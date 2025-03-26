%%% Make Snow Depth timeseries figure
%%%
%%% SPECIFIED INPUTS: 
%%%     folderpath = path to ICESat-2 datafiles
%%%     abbrev = site name abrivation 
%%%
%%% OUTPUTS:
%%%     figures jpegs
%%%
%%% Last updated: March 2024 by Karina Zikan

%% Inputs
clearvars;
addpath(['/Users/karinazikan/Documents/ICESat2-AlpineSnow/functions'])
addpath(['/Users/karinazikan/Documents/cmocean'])

%site abbreviation for file names
abbrev = 'Banner';
%Product abbreviation for files
prod_abbrev = 'A6-40';
%Folder path
folderpath = ['/Users/karinazikan/Documents/ICESat2-AlpineSnow/Sites/' abbrev '/'];

%Turn slope correction off or on
slope_correction = 1; % 0 = off, 1 = on


%set colors
colors{1} = cmocean('-dense',6);
colors{2} = cmocean('-algae',5);
colors{3} = cmocean('ice',5);
colors{4} = cmocean('-amp',5);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Load data
% IS2 data
filepath = [folderpath 'IS2_Data/' prod_abbrev '/ATL06-' prod_abbrev '-AllData-noCoreg_on.csv'];
df_noCoreg_on = readtable(filepath);
filepath = [folderpath 'IS2_Data/' prod_abbrev '/ATL06-' prod_abbrev '-AllData-noCoreg_off.csv'];
df_noCoreg_off = readtable(filepath);
filepath = [folderpath 'IS2_Data/' prod_abbrev '/ATL06-' prod_abbrev '-AllData-fineGS-agg_on.csv'];
df_on = readtable(filepath);
filepath = [folderpath 'IS2_Data/' prod_abbrev '/ATL06-' prod_abbrev '-AllData-fineGS-agg_off.csv'];
df_off = readtable(filepath);
filepath = [folderpath 'IS2_Data/' prod_abbrev '/ATL06-' prod_abbrev '-AllData-fineGS-ByTrack_on.csv'];
df_ByTrack_on = readtable(filepath);
filepath = [folderpath 'IS2_Data/' prod_abbrev '/ATL06-' prod_abbrev '-AllData-fineGS-ByTrack_off.csv'];
df_ByTrack_off = readtable(filepath);
filepath = [folderpath 'IS2_Data/' prod_abbrev '/' abbrev '_' prod_abbrev '-ByTrack-fineGS-Ashift.csv'];
df_Ashift = readtable(filepath);

%snow on bytract date array
ByTrack_on_dates = datetime(df_ByTrack_on.time.Year,df_ByTrack_on.time.Month,df_ByTrack_on.time.Day);
ByTrack_on_dates = datetime(ByTrack_on_dates,"Format",'yyyyMMdd');
ByTrack_off_dates = datetime(df_ByTrack_off.time.Year,df_ByTrack_off.time.Month,df_ByTrack_off.time.Day);
ByTrack_off_dates = datetime(ByTrack_off_dates,"Format",'yyyyMMdd');

%make file without bytrack dates with no corregistration
CoregOnlyDates = datetime(table2array(df_Ashift(~isnan(table2array(df_Ashift(:,2))),1)),'ConvertFrom','yyyyMMdd');
ix_date = zeros(height(df_ByTrack_on),1);
for i = 1:length(CoregOnlyDates)
    ix_date = ix_date + (ByTrack_on_dates == CoregOnlyDates(i));
    numberObs_date(i,:) = sum(ByTrack_off_dates == CoregOnlyDates(i));
end
ix_date = logical(ix_date);
df_ByTrack_CoregOnly_on = df_ByTrack_on(ix_date,:);

%snotel data
snotel_files = dir([folderpath 'snotel/*.csv']);
snotel = readtable([folderpath 'snotel/' snotel_files(1).name]);
for i = 2:length(snotel_files)
    file = readtable([folderpath 'snotel/' snotel_files(i).name]);
    snotel = cat(1,snotel,file);
end
snotel.SNWD_I_1_in_ = snotel.SNWD_I_1_in_ * 0.0254; %convert from in to m
snotel.SNWD_I_1_in_(snotel.SNWD_I_1_in_ < 0) = NaN;

% %Weather Station Location
% if abbrev == 'RCEW'
%     snotel_E = 519729; snotel_N = 4768225;
% elseif abbrev == 'DCEW'
%     snotel_E = 570697; snotel_N = 4843042;
% elseif abbrev == 'MCS'
%     snotel_E = 607075; snotel_N = 4865193;
% elseif abbrev == 'Banner'
%     snotel_E = 640823; snotel_N = 4907084;
% else
%     error('abbrev must be RCEW, DCEW, MCS, or Banner')
% end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Figures
%% Non-parametric pdfs
xbounds = [-6 4];
% Not vertically coregistered - snow free
figure(1); clf; hold on
pd = fitdist(df_noCoreg_off.elev_residuals,'kernel','Kernel','normal');
fplot(@(x) pdf(pd,x),[-20 8], 'Linewidth', 4, 'Color', colors{4}(3,:));
pd = fitdist(df_off.elev_residuals,'kernel','Kernel','normal');
fplot(@(x) pdf(pd,x),[-20 8], 'Linewidth', 3, 'Color', colors{1}(3,:));
pd = fitdist(df_ByTrack_off.elev_residuals,'kernel','Kernel','normal');
fplot(@(x) pdf(pd,x),[-20 8], 'Linewidth', 3, 'Color', colors{2}(3,:));
%set(gca,'fontsize',16,'xlim',xbounds);
%set(gcf,'position',[50 50 800 400]);
xlabel('Snow free Vertical offset (m)'); ylabel('Probability density');
legend('No Coregistration','Aggregated Coregistration','By Track Coregistration');
hold off

% Vertically coregistered - snow free
figure(2); clf; hold on
pd = fitdist(df_noCoreg_off.elev_residuals_vertcoreg,'kernel','Kernel','normal');
fplot(@(x) pdf(pd,x),[-10 8], 'Linewidth', 4);
pd = fitdist(df_off.elev_residuals_vertcoreg,'kernel','Kernel','normal');
fplot(@(x) pdf(pd,x),[-10 8], 'Linewidth',  4);
pd = fitdist(df_ByTrack_off.elev_residuals_vertcoreg,'kernel','Kernel','normal');
fplot(@(x) pdf(pd,x),[-10 8], 'Linewidth', 4);
xline(0, 'Linewidth', 1,'Color','black');
set(gca,'fontsize',20,'xlim',xbounds);
%set(gcf,'position',[50 50 800 400]);
xlabel('Snow free Vertical offset (m)'); ylabel('Probability density');
legend('No Coregistration','Aggregated Coregistration','By Track Coregistration');
hold off

% Vertically coregistered - snow free
figure(8); clf; hold on
pd = fitdist(df_noCoreg_on.elev_residuals_vertcoreg,'kernel','Kernel','normal');
fplot(@(x) pdf(pd,x),[-10 8], 'Linewidth', 3); % , 'Color', colors{4}(3,:)
pd = fitdist(df_on.elev_residuals_vertcoreg,'kernel','Kernel','normal');
fplot(@(x) pdf(pd,x),[-10 8], 'Linewidth',  3); % , 'Color', colors{1}(3,:)
pd = fitdist(df_ByTrack_on.elev_residuals_vertcoreg,'kernel','Kernel','normal');
fplot(@(x) pdf(pd,x),[-10 8], 'Linewidth', 3); % , 'Color', colors{2}(3,:)
pd = fitdist(df_ByTrack_CoregOnly_on.elev_residuals_vertcoreg,'kernel','Kernel','normal');
fplot(@(x) pdf(pd,x),[-10 8], 'Linewidth', 3); % , 'Color', colors{3}(3,:)
set(gca,'fontsize',16,'xlim',xbounds);
%set(gcf,'position',[50 50 800 400]);
xlabel('Snow On Vertical offset (m)'); ylabel('Probability density');
legend('No Coregistration','Aggregated Coregistration','By Track Coregistration','By Track Coregistration, Coregistered Tracks Only');
hold off

% Vertically coregistered - snow free & snow on
figure(3); clf;
subplot(4,1,1); hold on
pd = fitdist(df_noCoreg_on.elev_residuals_vertcoreg,'kernel','Kernel','normal');
fplot(@(x) pdf(pd,x),[-10 8], 'Linewidth', 3);
pd = fitdist(df_noCoreg_off.elev_residuals_vertcoreg,'kernel','Kernel','normal');
fplot(@(x) pdf(pd,x),[-10 8], 'Linewidth', 3);
set(gca,'fontsize',16,'xlim',xbounds);
%set(gcf,'position',[50 50 800 400]);
xlabel('Vertical offset (m)'); ylabel('Probability density');
legend('Snow On','Snow Off');
title('No Coregistration')
hold off

subplot(4,1,2); hold on
pd = fitdist(df_on.elev_residuals_vertcoreg,'kernel','Kernel','normal');
fplot(@(x) pdf(pd,x),[-10 8], 'Linewidth', 3);
pd = fitdist(df_off.elev_residuals_vertcoreg,'kernel','Kernel','normal');
fplot(@(x) pdf(pd,x),[-10 8], 'Linewidth', 3);
set(gca,'fontsize',16,'xlim',xbounds);
%set(gcf,'position',[50 50 800 400]);
xlabel('Vertical offset (m)'); ylabel('Probability density');
legend('Snow On','Snow Off');
title('Aggregated Coregistration')
hold off

% Vertically coregistered - snow free & snow on
subplot(4,1,3); hold on
pd = fitdist(df_ByTrack_on.elev_residuals_vertcoreg,'kernel','Kernel','normal');
fplot(@(x) pdf(pd,x),[-10 8], 'Linewidth', 3);
pd = fitdist(df_ByTrack_off.elev_residuals_vertcoreg,'kernel','Kernel','normal');
fplot(@(x) pdf(pd,x),[-10 8], 'Linewidth', 3);
set(gca,'fontsize',16,'xlim',xbounds);
%set(gcf,'position',[50 50 800 400]);
xlabel('Vertical offset (m)'); ylabel('Probability density');
legend('Snow On','Snow Off');
title('By Track Coregistration')
hold off

% Vertically coregistered - snow free & snow on
subplot(4,1,4); hold on
pd = fitdist(df_ByTrack_CoregOnly_on.elev_residuals_vertcoreg,'kernel','Kernel','normal');
fplot(@(x) pdf(pd,x),[-10 8], 'Linewidth', 3);
pd = fitdist(df_ByTrack_off.elev_residuals_vertcoreg,'kernel','Kernel','normal');
fplot(@(x) pdf(pd,x),[-10 8], 'Linewidth', 3);
set(gca,'fontsize',16,'xlim',xbounds);
%set(gcf,'position',[50 50 800 400]);
xlabel('Vertical offset (m)'); ylabel('Probability density');
legend('Snow On','Snow Off');
title('By Track Coregistration, Coregistered Tracks Only')
hold off

% Vertically coregistered - snow free & snow on
figure(7); clf; hold on
pd = fitdist(df_ByTrack_CoregOnly_on.elev_residuals_vertcoreg,'kernel','Kernel','normal');
fplot(@(x) pdf(pd,x),[-10 8], 'Linewidth', 3);
pd = fitdist(df_ByTrack_off.elev_residuals_vertcoreg,'kernel','Kernel','normal');
fplot(@(x) pdf(pd,x),[-10 8], 'Linewidth', 3);
set(gca,'fontsize',16,'xlim',xbounds);
%set(gcf,'position',[50 50 800 400]);
xlabel('Vertical offset (m)'); ylabel('Probability density');
legend('Snow On','Snow Off');
title('By Track Coregistration, Coregistered Tracks Only')
hold off

%% Terrain Histograms & boxplots
Nbin = 8; %set humber of bins for box plots
figure(5); clf

    %ELEVATION
    subplot(2,3,1);
    h = histogram([df_off.elevation_report_mean; df_on.elevation_report_mean],Nbin,'FaceColor',colors{1}(3,:));
    elev_binwidth = h.BinWidth; elev_binedges = h.BinEdges;
    clear h;
    xlabel('Elevation (m a.s.l.)','fontsize',16); ylabel('Observations','fontsize',16);
    yline(0)
    subplot(2,3,4);
    h = histogram([df_ByTrack_off.elevation_report_mean; df_ByTrack_on.elevation_report_mean],Nbin,'FaceColor',colors{1}(3,:));
    elev_binwidth = h.BinWidth; elev_binedges = h.BinEdges;
    clear h;
    xlabel('Elevation (m a.s.l.)','fontsize',16); ylabel('Observations','fontsize',16);
    yline(0)
    %ASPECT
    subplot(2,3,2);
    h = histogram([df_off.aspect_mean; df_on.aspect_mean],Nbin,'FaceColor',colors{2}(3,:));
    aspect_binwidth = h.BinWidth; aspect_binedges = h.BinEdges;
    clear h;
    xlabel('Aspect (degrees)','fontsize',16);
    yline(0)
    title('Aggregated Coregistration');
    subplot(2,3,5);
    h = histogram([df_ByTrack_off.aspect_mean; df_ByTrack_on.aspect_mean],Nbin,'FaceColor',colors{2}(3,:));
    aspect_binwidth = h.BinWidth; aspect_binedges = h.BinEdges;
    clear h;
    xlabel('Aspect (degrees)','fontsize',16);
    yline(0)
    title('By Track Coregistration');
    %SLOPE
    subplot(2,3,3);
    h = histogram([df_off.slope_mean; df_on.slope_mean],Nbin,'FaceColor',colors{3}(3,:));
    slope_binwidth = h.BinWidth; slope_binedges = h.BinEdges;
    clear h;
    xlabel('Slope (degrees)','fontsize',16);
    yline(0)
    subplot(2,3,6);
    h = histogram([df_ByTrack_off.slope_mean; df_ByTrack_on.slope_mean],Nbin,'FaceColor',colors{3}(3,:));
    slope_binwidth = h.BinWidth; slope_binedges = h.BinEdges;
    clear h;
    xlabel('Slope (degrees)','fontsize',16);
    yline(0)


% Terrain Boxplots
% no slope correction
figure(6); clf

    %ELEVATION
    subplot(3,3,1);
    h = histogram([df_off.elevation_report_mean; df_on.elevation_report_mean],Nbin,'FaceColor',colors{1}(3,:));
    elev_binwidth = h.BinWidth; elev_binedges = h.BinEdges;
    clear h;
    xlabel('Elevation (m a.s.l.)','fontsize',16); ylabel('Observations','fontsize',16);
    yline(0)
    bins = {num2str(elev_binedges(2))};
    for i= 3:length(elev_binedges)
        bins = [bins; {num2str(elev_binedges(i))}];
    end
    subplot(3,3,4);
    hold on
    groupElev = discretize(df_off.elevation_report_mean,elev_binedges,'categorical',bins);
    boxchart(groupElev, df_off.elev_residuals_vertcoreg,'BoxFaceColor',colors{1}(3,:),'MarkerStyle','none')
    ylim([-2,2])
    set(gca,'fontsize',16,'box','on'); drawnow;
    xlabel('Elevation (m a.s.l.)','fontsize',16); ylabel('Elevation residuals (m)','fontsize',16);
    yline(0)
    subplot(3,3,7);
    hold on
    groupElev = discretize(df_ByTrack_off.elevation_report_mean,elev_binedges,'categorical',bins);
    boxchart(groupElev, df_ByTrack_off.elev_residuals_vertcoreg,'BoxFaceColor',colors{1}(3,:),'MarkerStyle','none')
    ylim([-2,2])
    set(gca,'fontsize',16,'box','on'); drawnow;
    xlabel('Elevation (m a.s.l.)','fontsize',16); ylabel('Elevation residuals (m)','fontsize',16);
    yline(0)

    %ASPECT
    subplot(3,3,2);
    h = histogram([df_off.aspect_mean; df_on.aspect_mean],Nbin,'FaceColor',colors{2}(3,:));
    aspect_binwidth = h.BinWidth; aspect_binedges = h.BinEdges;
    clear h;
    xlabel('Aspect (degrees)','fontsize',16);
    yline(0)
    set(gca,'fontsize',16,'box','on'); drawnow;
    title(abbrev);
    
    bins = {num2str(aspect_binedges(2))};
    for i= 3:length(aspect_binedges)
        bins = [bins; {num2str(aspect_binedges(i))}];
    end
    subplot(3,3,5);
    hold on
    groupAspect = discretize(df_off.aspect_mean,aspect_binedges,'categorical',bins);
    boxchart(groupAspect, df_off.elev_residuals_vertcoreg,'BoxFaceColor',colors{2}(3,:),'MarkerStyle','none')
    ylim([-2,2])
    set(gca,'fontsize',16,'box','on'); drawnow;
    xlabel('Aspect (degrees)','fontsize',16);
    title('Aggregated Coregistration');
    yline(0)
    subplot(3,3,8);
    hold on
    groupAspect = discretize(df_ByTrack_off.aspect_mean,aspect_binedges,'categorical',bins);
    boxchart(groupAspect, df_ByTrack_off.elev_residuals_vertcoreg,'BoxFaceColor',colors{2}(3,:),'MarkerStyle','none')
    ylim([-2,2])
    set(gca,'fontsize',16,'box','on'); drawnow;
    xlabel('Aspect (degrees)','fontsize',16);
    title('By Track Coregistration');
    yline(0)

    %SLOPE
    subplot(3,3,3);
    h = histogram([df_off.slope_mean; df_on.slope_mean],Nbin,'FaceColor',colors{3}(3,:));
    slope_binwidth = h.BinWidth; slope_binedges = h.BinEdges;
    clear h;
    xlabel('Slope (degrees)','fontsize',16);
    yline(0)
    bins = {num2str(slope_binedges(2))};
    for i= 3:length(slope_binedges)
        bins = [bins; {num2str(slope_binedges(i))}];
    end
    subplot(3,3,6);
    hold on
    groupSlope = discretize(df_off.slope_mean,slope_binedges,'categorical',bins);
    boxchart(groupSlope, df_off.elev_residuals_vertcoreg,'BoxFaceColor',colors{3}(3,:),'MarkerStyle','none')
    ylim([-3,3])
    set(gca,'fontsize',16,'box','on'); drawnow;
    xlabel('Slope (degrees)','fontsize',16);
    yline(0)
    subplot(3,3,9);
    hold on
    groupSlope = discretize(df_ByTrack_off.slope_mean,slope_binedges,'categorical',bins);
    boxchart(groupSlope, df_ByTrack_off.elev_residuals_vertcoreg,'BoxFaceColor',colors{3}(3,:),'MarkerStyle','none')
    ylim([-3,3])
    set(gca,'fontsize',16,'box','on'); drawnow;
    xlabel('Slope (degrees)','fontsize',16);
    yline(0)






































