%% Inputs
clearvars;
addpath(['/Users/karinazikan/Documents/ICESat2-AlpineSnow/functions'])
addpath(['/Users/karinazikan/Documents/cmocean'])
%colors
load('/Users/karinazikan/Documents/ScientificColourMaps8/vik/DiscretePalettes/vik10.mat');

%Folder path
folderpath = '/Users/karinazikan/Documents/ICESat2-AlpineSnow/Sites/';
%site abbreviation for file names
site_abbrevs = string({'RCEW';'Banner';'MCS';'DCEW'});
site_names = string({'RCEW';'BCS';'MCS';'DCEW'});
Coreg_type = string({'noCoreg';'Agg';'ByTrack'});

%Turn dtm or is2 slope correction
slope_correction = 2; % 0 = dtm, 1 = is2, 2 = no slope correction
%Turn dtm or is2 slope correction
slope_filter = 0; % 0 = none, 1 = remove slopes > 30 degrees

%Weather Station Location
% Reynolds snowex: snotel_E = 519729; snotel_N = 4768225;
% Banner snotel: snotel_E = 640823; snotel_N = 4907084;
% MCS snotel: snotel_E = 607075; snotel_N = 4865193;
% DCEW little deer point AWS: snotel_E = 570697; snotel_N = 4843042;
snotel_E = {519729; 640823; 607075; 570697};
snotel_N = {4768225; 4907084; 4865193; 4843042};

%set colors
colors{1} = cmocean('-dense',6);
colors{2} = cmocean('-algae',5);
colors{3} = cmocean('ice',5);
colors{4} = cmocean('-amp',5);

%% Read in data
for j = 1:length(site_abbrevs)
    % IS2 data
    for k = 1:length(Coreg_type)
        filepath = strcat(folderpath, site_abbrevs(j), '/IS2_Data/A6-40/ATL06-A6-40-AllData-', Coreg_type(k), '_on.csv');
        df_on{j,k} = readtable(filepath);
        filepath = strcat(folderpath, site_abbrevs(j), '/IS2_Data/A6-40/ATL06-A6-40-AllData-', Coreg_type(k), '_off.csv');
        df_off{j,k} = readtable(filepath);
        % slope correction
        if slope_correction == 1
            df_off{j,k}.elev_residuals_vertcoreg = df_off{j,k}.elev_residuals_vertcoreg_is2_slopecorrected;
            df_on{j,k}.elev_residuals_vertcoreg = df_on{j,k}.elev_residuals_vertcoreg_is2_slopecorrected;
            df_off{j,k}.slope_mean = df_off{j,k}.IS2_slope_deg;
            df_on{j,k}.slope_mean = df_on{j,k}.IS2_slope_deg;
            if k ==1 && j == 1
                ('IS2 Slope correction used')
            else
            end
        elseif slope_correction == 2
            if k ==1 && j == 1
                ('No Slope correction used')
            else
            end
        elseif slope_correction == 0
            df_off{j,k}.elev_residuals_vertcoreg = df_off{j,k}.elev_residuals_vertcoreg_dtm_slopecorrected;
            df_on{j,k}.elev_residuals_vertcoreg = df_on{j,k}.elev_residuals_vertcoreg_dtm_slopecorrected;
            df_off{j,k}.slope_mean = df_off{j,k}.IS2_slope_deg;
            df_on{j,k}.slope_mean = df_on{j,k}.IS2_slope_deg;
            if k ==1 && j == 1
                ('DTM Slope correction used')
            else
            end
        end
    end
    if slope_filter == 1
        df_off{j,k}(df_off{j,k}.slope_mean > 30,:) = [];
        df_on{j,k}(df_on{j,k}.slope_mean > 30,:) = [];
    else
    end

    %snotel data
    snotel_files = dir(strcat(folderpath, site_abbrevs(j), '/snotel/*.csv'));
    if j == 1 %RCEW site
        temp_file = readtable(strcat(folderpath, site_abbrevs(j), '/snotel/', snotel_files(1).name));
        Dates = datetime(temp_file.date_time.Year,temp_file.date_time.Month,temp_file.date_time.Day);
        snotel{j}.Date = [Dates; Dates; Dates; Dates];
        snotel{j}.SNWD_I_1_in_ = [temp_file.RME_176; temp_file.RME_176b; temp_file.RME_rmsp3; temp_file.RME_rmsp3b];
        snotel{j}.SNWD_I_1_in_ = snotel{j}.SNWD_I_1_in_ / 100;
    else
        snotel{j} = readtable(strcat(folderpath, site_abbrevs(j), '/snotel/', snotel_files(1).name));
        for i = 2:length(snotel_files)
            file = readtable(strcat(folderpath, site_abbrevs(j), '/snotel/', snotel_files(i).name));
            snotel{j} = cat(1,snotel{j},file);
        end
        snotel{j}.SNWD_I_1_in_ = snotel{j}.SNWD_I_1_in_ * 0.0254; %convert from in to m
        snotel{j}.SNWD_I_1_in_(snotel{j}.SNWD_I_1_in_ < 0) = NaN;
    end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% set coregerestration type for future plots
k = 2; % agg coreg


%% Figures
%% Non-parametric pdfs
% snow on vs snow pff
figure(1); clf; hold on
for j = 1:length(site_abbrevs)
    subplot(2,2,j); hold on
    pd = fitdist(df_on{j,k}.elev_residuals_vertcoreg,'kernel','Kernel','normal');
    fplot(@(x) pdf(pd,x),[-10 8], 'Linewidth', 2);
    pd = fitdist(df_off{j,k}.elev_residuals_vertcoreg,'kernel','Kernel','normal');
    fplot(@(x) pdf(pd,x),[-10 8], 'Linewidth', 2);
    set(gca,'fontsize',16,'xlim',[-6 6]);
    %set(gcf,'position',[50 50 800 400]);
    xlabel('Snow free Vertical offset (m)'); ylabel('Probability density');
    legend('Snow On','Snow Off');
    title(site_names{j});
end
hold off

figure(2); clf; hold on
for j = 1:length(site_abbrevs)
    subplot(length(site_abbrevs),1,j); hold on
    pd = fitdist(df_on{j,k}.elev_residuals_vertcoreg,'kernel','Kernel','normal');
    fplot(@(x) pdf(pd,x),[-10 8], 'Linewidth', 2);
    pd = fitdist(df_off{j,k}.elev_residuals_vertcoreg,'kernel','Kernel','normal');
    fplot(@(x) pdf(pd,x),[-10 8], 'Linewidth', 2);
    pd = fitdist(df_on{j,k}.elev_residuals_vertcoreg_dtm_slopecorrected,'kernel','Kernel','normal');
    fplot(@(x) pdf(pd,x),[-10 8], 'Linewidth', 2);
    pd = fitdist(df_off{j,k}.elev_residuals_vertcoreg_dtm_slopecorrected,'kernel','Kernel','normal');
    fplot(@(x) pdf(pd,x),[-10 8], 'Linewidth', 2);
    pd = fitdist(df_on{j,k}.elev_residuals_vertcoreg_is2_slopecorrected,'kernel','Kernel','normal');
    fplot(@(x) pdf(pd,x),[-10 8], 'Linewidth', 2);
    pd = fitdist(df_off{j,k}.elev_residuals_vertcoreg_is2_slopecorrected,'kernel','Kernel','normal');
    fplot(@(x) pdf(pd,x),[-10 8], 'Linewidth', 2);
    set(gca,'fontsize',16,'xlim',[-3 3]);
    %set(gcf,'position',[50 50 800 400]);
    xlabel('Snow free Vertical offset (m)'); ylabel('Probability density');
    legend('Snow On','Snow Off','dtm Slope Corrected Snow On','dtm Slope Corrected Snow Off','is2 Slope Corrected Snow On','is2 Slope Corrected Snow Off');
    title(site_names{j});
end
hold off

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Terrain Histograms & boxplots
Nbin = 8; %set humber of bins for box plots
figure(3); clf
for j = 1:length(site_abbrevs)
    %ELEVATION
    subplot(length(site_abbrevs),3,(3*j-2));
    h = histogram([df_off{j,k}.elevation_report_mean; df_on{j,k}.elevation_report_mean],Nbin,'FaceColor',colors{1}(3,:));
    elev_binwidth{j} = h.BinWidth; elev_binedges{j} = h.BinEdges;
    clear h;
    xlabel('Elevation (m a.s.l.)','fontsize',16); ylabel('Observations','fontsize',16);
    yline(0)
    %ASPECT
    subplot(length(site_abbrevs),3,(3*j-1));
    h = histogram([df_off{j,k}.aspect_mean; df_on{j,k}.aspect_mean],Nbin,'FaceColor',colors{2}(3,:));
    aspect_binwidth{j} = h.BinWidth; aspect_binedges{j} = h.BinEdges;
    clear h;
    xlabel('Aspect (degrees)','fontsize',16);
    yline(0)
    title(site_names{j},'fontsize',16);
    %SLOPE
    subplot(length(site_abbrevs),3,(3*j));
    h = histogram([df_off{j,k}.slope_mean; df_on{j,k}.slope_mean],Nbin,'FaceColor',colors{3}(3,:));
    slope_binwidth{j} = h.BinWidth; slope_binedges{j} = h.BinEdges;
    clear h;
    xlabel('Slope (degrees)','fontsize',16);
    yline(0)
end

% Terrain Boxplots
% no slope correction
% figure(4); clf
% for j = 1:length(site_abbrevs)
%     %ELEVATION
%     bins = {num2str(elev_binedges{j}(2))};
%     for i= 3:length(elev_binedges{j})
%         bins = [bins; {num2str(elev_binedges{j}(i))}];
%     end
%     subplot(length(site_abbrevs),3,(3*j-2));
%     hold on
%     groupElev = discretize(df_off{j,k}.elevation_report_mean,elev_binedges{j},'categorical',bins);
%     boxchart(groupElev, df_off{j,k}.elev_residuals_vertcoreg,'BoxFaceColor',colors{1}(3,:),'MarkerStyle','none')
%     ylim([-2,2])
%     set(gca,'fontsize',16,'box','on'); drawnow;
%     xlabel('Elevation (m a.s.l.)','fontsize',16); ylabel('Elevation residuals (m)','fontsize',16);
%     yline(0)
% 
%     %ASPECT
%     bins = {num2str(aspect_binedges{j}(2))};
%     for i= 3:length(aspect_binedges{j})
%         bins = [bins; {num2str(aspect_binedges{j}(i))}];
%     end
%     subplot(length(site_abbrevs),3,(3*j-1));
%     hold on
%     groupAspect = discretize(df_off{j,k}.aspect_mean,aspect_binedges{j},'categorical',bins);
%     boxchart(groupAspect, df_off{j}.elev_residuals_vertcoreg,'BoxFaceColor',colors{2}(3,:),'MarkerStyle','none')
%     ylim([-2,2])
%     set(gca,'fontsize',16,'box','on'); drawnow;
%     xlabel('Aspect (degrees)','fontsize',16);
%     title(site_names{j},'fontsize',16);
%     yline(0)
% 
%     %SLOPE
%     bins = {num2str(slope_binedges{j}(2))};
%     for i= 3:length(slope_binedges{j})
%         bins = [bins; {num2str(slope_binedges{j}(i))}];
%     end
%     subplot(length(site_abbrevs),3,(3*j));
%     hold on
%     groupSlope = discretize(df_off{j,k}.slope_mean,slope_binedges{j},'categorical',bins);
%     boxchart(groupSlope, df_off{j,k}.elev_residuals_vertcoreg,'BoxFaceColor',colors{3}(3,:),'MarkerStyle','none')
%     ylim([-3,3])
%     set(gca,'fontsize',16,'box','on'); drawnow;
%     xlabel('Slope (degrees)','fontsize',16);
%     yline(0)
% end

% slope correction
figure(5); clf
for j = 1:length(site_abbrevs)
    %ELEVATION
    bins = {num2str(elev_binedges{j}(2))};
    for i= 3:length(elev_binedges{j})
        bins = [bins; {num2str(elev_binedges{j}(i))}];
    end
    subplot(length(site_abbrevs),3,(3*j-2));
    hold on
    groupElev = discretize(df_off{j,k}.elevation_report_mean,elev_binedges{j},'categorical',bins);
    boxchart(groupElev, df_off{j,k}.elev_residuals_vertcoreg_dtm_slopecorrected,'BoxFaceColor',colors{1}(3,:),'MarkerStyle','none')
    ylim([-2,2])
    set(gca,'fontsize',16,'box','on'); drawnow;
    xlabel('Elevation (m a.s.l.)','fontsize',16); ylabel('Elevation residuals (m)','fontsize',16);
    yline(0)

    %ASPECT
    bins = {num2str(aspect_binedges{j}(2))};
    for i= 3:length(aspect_binedges{j})
        bins = [bins; {num2str(aspect_binedges{j}(i))}];
    end
    subplot(length(site_abbrevs),3,(3*j-1));
    hold on
    groupAspect = discretize(df_off{j}.aspect_mean,aspect_binedges{j},'categorical',bins);
    boxchart(groupAspect, df_off{j}.elev_residuals_vertcoreg_dtm_slopecorrected,'BoxFaceColor',colors{2}(3,:),'MarkerStyle','none')
    ylim([-2,2])
    set(gca,'fontsize',16,'box','on'); drawnow;
    xlabel('Aspect (degrees)','fontsize',16);
    title(site_names{j},'fontsize',16);
    yline(0)

    %SLOPE
    bins = {num2str(slope_binedges{j}(2))};
    for i= 3:length(slope_binedges{j})
        bins = [bins; {num2str(slope_binedges{j}(i))}];
    end
    subplot(length(site_abbrevs),3,(3*j));
    hold on
    groupSlope = discretize(df_off{j,k}.slope_mean,slope_binedges{j},'categorical',bins);
    boxchart(groupSlope, df_off{j,k}.elev_residuals_vertcoreg_dtm_slopecorrected,'BoxFaceColor',colors{3}(3,:),'MarkerStyle','none')
    ylim([-3,3])
    set(gca,'fontsize',16,'box','on'); drawnow;
    xlabel('Slope (degrees)','fontsize',16);
    yline(0)
end

%%
% slope correction figure
figure(6); clf
for j = 1:length(site_abbrevs)
    %SLOPE histogram
    subplot(length(site_abbrevs),3,(3*j-2));
    h = histogram([df_off{j,k}.slope_mean; df_on{j,k}.slope_mean],Nbin,'FaceColor',colors{1}(3,:));
    slope_binwidth{j} = h.BinWidth; slope_binedges{j} = h.BinEdges;
    clear h;
    xlabel('Slope (degrees)','fontsize',16); ylabel('Observations','fontsize',16);
    yline(0)

    %SLOPE boxplot
    bins = {num2str(slope_binedges{j}(2))};
    for i= 3:length(slope_binedges{j})
        bins = [bins; {num2str(slope_binedges{j}(i))}];
    end
    subplot(length(site_abbrevs),3,(3*j-1));
    hold on
    groupSlope = discretize(df_off{j,k}.slope_mean,slope_binedges{j},'categorical',bins);
    boxchart(groupSlope, df_off{j,k}.elev_residuals_vertcoreg,'BoxFaceColor',colors{2}(3,:),'MarkerStyle','none')
    ylim([-3,3])
    set(gca,'fontsize',16,'box','on'); drawnow;
    xlabel('Slope (degrees)','fontsize',16); ylabel('Elevation residuals (m)','fontsize',16);
    yline(0)
    title(site_names{j},'fontsize',16);

    %SLOPE corrected boxplot
    bins = {num2str(slope_binedges{j}(2))};
    for i= 3:length(slope_binedges{j})
        bins = [bins; {num2str(slope_binedges{j}(i))}];
    end
    subplot(length(site_abbrevs),3,(3*j));
    hold on
    groupSlope = discretize(df_off{j,k}.slope_mean,slope_binedges{j},'categorical',bins);
    boxchart(groupSlope, df_off{j,k}.elev_residuals_vertcoreg_dtm_slopecorrected,'BoxFaceColor',colors{3}(3,:),'MarkerStyle','none')
    ylim([-3,3])
    set(gca,'fontsize',16,'box','on'); drawnow;
    xlabel('Slope (degrees)','fontsize',16); ylabel('Elevation residuals (m)','fontsize',16);
    yline(0)
end

% equal boxes
slope_binedges = [1:5:55];
%%
figure(13); clf
for j = 1:length(site_abbrevs)
    %SLOPE histogram
    subplot(length(site_abbrevs),3,(3*j-2));
    h = histogram([df_off{j,k}.slope_mean; df_on{j,k}.slope_mean],slope_binedges,'FaceColor',colors{1}(3,:));
    clear h;
    xlabel('Slope (degrees)','fontsize',16); ylabel('Observations','fontsize',16);
    yline(0)

    %SLOPE boxplot
    bins = {num2str(slope_binedges(2))};
    for i= 3:length(slope_binedges)
        bins = [bins; {num2str(slope_binedges(i))}];
    end
    subplot(length(site_abbrevs),3,(3*j-1));
    hold on
    groupSlope = discretize(df_off{j,k}.slope_mean,slope_binedges,'categorical',bins);
    boxchart(groupSlope, df_off{j,k}.elev_residuals_vertcoreg,'BoxFaceColor',colors{2}(3,:),'MarkerStyle','none')
    ylim([-3,3])
    set(gca,'fontsize',16,'box','on'); drawnow;
    xlabel('Slope (degrees)','fontsize',16); ylabel('Elevation residuals (m)','fontsize',16);
    yline(0)
    title(site_names{j},'fontsize',16);

    %SLOPE corrected boxplot
    bins = {num2str(slope_binedges(2))};
    for i= 3:length(slope_binedges)
        bins = [bins; {num2str(slope_binedges(i))}];
    end
    subplot(length(site_abbrevs),3,(3*j));
    hold on
    groupSlope = discretize(df_off{j,k}.slope_mean,slope_binedges,'categorical',bins);
    boxchart(groupSlope, df_off{j,k}.elev_residuals_vertcoreg_dtm_slopecorrected,'BoxFaceColor',colors{3}(3,:),'MarkerStyle','none')
    ylim([-3,3])
    set(gca,'fontsize',16,'box','on'); drawnow;
    xlabel('Slope (degrees)','fontsize',16); ylabel('Elevation residuals (m)','fontsize',16);
    yline(0)
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Residual vs Slope

% Scatter plot
figure(7);  clf
hold on
for j = 1:length(site_abbrevs)
    scatter(df_off{j,k}.slope_mean, df_off{j,k}.elev_residuals_vertcoreg, '.')
    set(gca,'fontsize',16);
    xlabel('Slope (degrees)');
    ylabel('Elevation Residuals (m)');
end
ylim([-10,10])
yline(0)
legend(site_names);


%% Terrain Boxplots
% no slope correction
slope_binedges = [1:5:55];
tbl.slope = []; tbl.elevRes = []; tbl.group = [];
Cat_groupSlope = []; Cat_df_off = [];
% all sites boxplot on top of each other
figure(10); clf
for j = 1:length(site_abbrevs)
    clear group
    bins = {num2str(slope_binedges(2))};
    for i= 3:length(slope_binedges)
        bins = [bins; {num2str(slope_binedges(i))}];
    end
    hold on
    groupSlope = discretize(df_off{j,k}.slope_mean,slope_binedges,'categorical',bins);
    tbl.slope = [tbl.slope; groupSlope];
    group(1:length(groupSlope),:) = j;
    tbl.elevRes = [tbl.elevRes; df_off{j,k}.elev_residuals_vertcoreg];
    tbl.group = [tbl.group; group];
    boxchart(groupSlope, df_off{j,k}.elev_residuals_vertcoreg,'BoxFaceColor',colors{j}(3,:),'MarkerStyle','none');
    Cat_groupSlope = [Cat_groupSlope; groupSlope];
    Cat_df_off = [Cat_df_off; df_off{j,k}.elev_residuals_vertcoreg];
    ylim([-5,5])
    set(gca,'fontsize',16,'box','on'); drawnow;
    xlabel('Slope (degrees)','fontsize',16);
end
yline(0)
legend(site_names);

% All data boxplots
figure(11); clf
boxchart(Cat_groupSlope, Cat_df_off,'BoxFaceColor','k','MarkerStyle','none');
for j = 1:length(site_abbrevs)
    clear group cat_slope_tbl
    bins = {num2str(slope_binedges(2))};
    for i= 3:length(slope_binedges)
        bins = [bins; {num2str(slope_binedges(i))}];
    end
    hold on
    groupSlope = discretize(df_off{j,k}.slope_mean,slope_binedges,'categorical',bins);
    cat_slope_tbl(:,1) = table(groupSlope);
    cat_slope_tbl(:,2) = table(df_off{j,k}.elev_residuals_vertcoreg);
    Redidual_Medians = varfun(@(x)median(x,'omitnan'),cat_slope_tbl,'GroupingVariables',{'groupSlope'});
    Redidual_IQR = varfun(@(x)iqr(x),cat_slope_tbl,'GroupingVariables',{'groupSlope'});
    scatter(Redidual_Medians.groupSlope, Redidual_Medians.Fun_Var2, 60, 'filled','MarkerFaceColor', colors{j}(3,:),'MarkerEdgeColor', colors{j}(2,:))
    % scatter(Redidual_IQR.groupSlope,(Redidual_Medians.Fun_Var2 + Redidual_IQR.Fun_Var2), 'Marker', '*','MarkerEdgeColor', colors{j}(3,:))
    % scatter(Redidual_IQR.groupSlope,(Redidual_Medians.Fun_Var2 - Redidual_IQR.Fun_Var2), 'Marker', '*','MarkerEdgeColor', colors{j}(3,:))
    ylim([-5,5])
    set(gca,'fontsize',16,'box','on'); drawnow;
    xlabel('Slope (degrees)','fontsize',16);
end
yline(0)
legend('All Sites', 'RCEW median', 'BCS median', 'MCS median', 'DCEW median');




























