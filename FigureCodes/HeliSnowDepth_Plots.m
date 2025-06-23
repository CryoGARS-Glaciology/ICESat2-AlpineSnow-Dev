%% Inputs
clearvars;
addpath(['/Users/karinazikan/Documents/ICESat2-AlpineSnow/functions'])
addpath(['/Users/karinazikan/Documents/cmocean'])

%site abbreviation for file names
abbrev = 'MCS';
%Product abbreviation for files
prod_abbrev = 'A6-40';
%Folder path
folderpath = ['/Users/karinazikan/Documents/ICESat2-AlpineSnow/Sites/' abbrev '/'];

%Turn dtm or is2 slope correction
slope_correction = 1; % 0 = dtm, 1 = is2, 2 = no slope correction

%Turn dtm or is2 slope correction
slope_filter = 0; % 0 = none, 1 = remove slopes < slope_threshhold, 2 = remove slopes > slope_threshhold
slope_threshhold = 20;

% ICESat-2 residuals below 0 to NaN?
remove_negative = 1; % 0 = off, 1 = on


%set colors
colors{1} = cmocean('-dense',6);
colors{2} = cmocean('-algae',5);
colors{3} = cmocean('ice',5);
colors{4} = cmocean('-amp',5);

Coreg_colors = ['#e6ab02'; '#1b9e77'; '#6e6dcf'];
site_shapes = ["o";"square";"diamond";"^"];

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Load data
% IS2 data
filepath = [folderpath 'IS2_Data/' prod_abbrev '/' abbrev '-heli-snow-depth-grid-search-noCoreg.csv'];
df_noCoreg = readtable(filepath);
filepath = [folderpath 'IS2_Data/' prod_abbrev '/' abbrev '-heli-snow-depth-FineGS-agg.csv'];
df_agg = readtable(filepath);
filepath = [folderpath 'IS2_Data/' prod_abbrev '/' abbrev '-heli-snow-depth-FineGS-ByTrack.csv'];
df_ByTrack = readtable(filepath);

% snow on
df_noCoreg_on = df_noCoreg(df_noCoreg.snowcover == 1,:);
df_agg_on = df_agg(df_agg.snowcover == 1,:);
df_ByTrack_on = df_ByTrack(df_ByTrack.snowcover == 1,:);

% slope correction
if slope_filter == 1
    df_noCoreg_on(df_noCoreg_on.slope_mean > 30,:) = [];
    df_agg_on(df_agg_on.slope_mean > 30,:) = []; 
    df_ByTrack_on(df_ByTrack_on.slope_mean > 30,:) = [];
end
if slope_correction == 1
    df_noCoreg_on.elev_residuals_vertcoreg = df_noCoreg_on.elev_residuals_vertcoreg_is2_slopecorrected;
    df_noCoreg_on.slope_mean = df_noCoreg_on.IS2_slope_deg;
    df_agg_on.elev_residuals_vertcoreg = df_agg_on.elev_residuals_vertcoreg_is2_slopecorrected;
    df_agg_on.slope_mean = df_agg_on.IS2_slope_deg;
    df_ByTrack_on.elev_residuals_vertcoreg = df_ByTrack_on.elev_residuals_vertcoreg_is2_slopecorrected;
    df_ByTrack_on.slope_mean = df_ByTrack_on.IS2_slope_deg;
    ('IS2 Slope correction used')
elseif slope_correction == 2
    ('No Slope correction used')
else
    df_noCoreg_on.elev_residuals_vertcoreg = df_noCoreg_on.elev_residuals_vertcoreg_dtm_slopecorrected;
    df_noCoreg_on.slope_mean = df_noCoreg_on.IS2_slope_deg;
    df_agg_on.elev_residuals_vertcoreg = df_agg_on.elev_residuals_vertcoreg_dtm_slopecorrected;
    df_agg_on.slope_mean = df_agg_on.IS2_slope_deg;
    df_ByTrack_on.elev_residuals_vertcoreg = df_ByTrack_on.elev_residuals_vertcoreg_dtm_slopecorrected;
    df_ByTrack_on.slope_mean = df_ByTrack_on.IS2_slope_deg;
    ('DTM Slope correction used')
end

% remove negative ICESat-2 elevation residuals
if remove_negative == 1
    df_noCoreg_on.snowdepth(df_noCoreg_on.elev_residuals_vertcoreg < 0) = NaN;
    df_agg_on.snowdepth(df_agg_on.elev_residuals_vertcoreg < 0) = NaN;
    df_ByTrack_on.snowdepth(df_ByTrack_on.elev_residuals_vertcoreg < 0) = NaN;
    
    df_noCoreg_on.elev_residuals_vertcoreg(df_noCoreg_on.elev_residuals_vertcoreg < 0) = NaN;
    df_agg_on.elev_residuals_vertcoreg(df_agg_on.elev_residuals_vertcoreg < 0) = NaN;
    df_ByTrack_on.elev_residuals_vertcoreg(df_ByTrack_on.elev_residuals_vertcoreg < 0) = NaN;
    ('Negative ICESat-2 elevation residuals removed')
else
end

% slope filter
if slope_filter == 1
    df_noCoreg_on(df_noCoreg_on.slope_mean < slope_threshhold,:) = [];
    df_agg_on(df_agg_on.slope_mean < slope_threshhold,:) = [];
    df_ByTrack_on(df_ByTrack_on.slope_mean < slope_threshhold,:) = [];
elseif slope_filter == 2
    df_noCoreg_on(df_noCoreg_on.slope_mean > slope_threshhold,:) = [];
    df_agg_on(df_agg_on.slope_mean > slope_threshhold,:) = [];
    df_ByTrack_on(df_ByTrack_on.slope_mean > slope_threshhold,:) = [];
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Stats
Residuals = df_noCoreg_on.elev_residuals_vertcoreg - df_noCoreg_on.snowdepth;
Rnmad(1) = 1.4826*median(abs(Residuals-nanmean(Residuals)),'omitnan'); % normalized meadian absolute difference
Rmed(1) = median(Residuals,'omitnan'); % median
Rmean(1) = nanmean(Residuals); % mean
Residuals = df_agg_on.elev_residuals_vertcoreg - df_agg_on.snowdepth;
Rnmad(2) = 1.4826*median(abs(Residuals-nanmean(Residuals)),'omitnan'); 
Rmed(2) = median(Residuals,'omitnan'); % median
Rmean(2) = nanmean(Residuals); % mean
Residuals = df_ByTrack_on.elev_residuals_vertcoreg - df_ByTrack_on.snowdepth;
Rnmad(3) = 1.4826*median(abs(Residuals-nanmean(Residuals)),'omitnan'); 
Rmed(3) = median(Residuals,'omitnan'); % median
Rmean(3) = nanmean(Residuals); % mean


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Figures
% %% Non-parametric pdfs
% xbounds = [-4 6];
% % Not vertically coregistered - snow free
% figure(1); clf; 
% subplot(3,1,1); hold on
% pd = fitdist(df_noCoreg_on.snowdepth,'kernel','Kernel','normal');
% fplot(@(x) pdf(pd,x),[-10 8], 'Linewidth', 3);
% pd = fitdist(df_noCoreg_on.elev_residuals_vertcoreg,'kernel','Kernel','normal');
% fplot(@(x) pdf(pd,x),[-10 8], 'Linewidth', 3);
% xline(nanmean(df_noCoreg_on.snowdepth), 'Linewidth', 3,'Color','blue')
% xline(median(df_noCoreg_on.elev_residuals_vertcoreg,'omitnan'), 'Linewidth', 3,'Color','red')
% set(gca,'fontsize',16,'xlim',xbounds);
% %set(gcf,'position',[50 50 800 400]);
% xlabel('Snow Depth (m)'); ylabel('Probability density');
% legend('Helicopter Lidar Snow Depth','ICESat-2 Snow Depth','Median Heli Snow Depth','Median ICESat-2 Snow Depth','Location','northwest');
% title('No Coregistration')
% hold off
% 
% subplot(3,1,2); hold on
% pd = fitdist(df_agg_on.snowdepth,'kernel','Kernel','normal');
% fplot(@(x) pdf(pd,x),[-10 8], 'Linewidth', 3);
% pd = fitdist(df_agg_on.elev_residuals_vertcoreg,'kernel','Kernel','normal');
% fplot(@(x) pdf(pd,x),[-10 8], 'Linewidth', 3);
% xline(nanmean(df_agg_on.snowdepth), 'Linewidth', 3,'Color','blue')
% xline(median(df_agg_on.elev_residuals_vertcoreg,'omitnan'), 'Linewidth', 3,'Color','red')
% set(gca,'fontsize',16,'xlim',xbounds);
% %set(gcf,'position',[50 50 800 400]);
% xlabel('Snow Depth (m)'); ylabel('Probability density');
% legend('Helicopter Lidar Snow Depth','ICESat-2 Snow Depth','Median Heli Snow Depth','Median ICESat-2 Snow Depth','Location','northwest');
% title('Aggregated Coregistration')
% hold off
% 
% % Vertically coregistered - snow free & snow on
% subplot(3,1,3); hold on
% pd = fitdist(df_ByTrack_on.snowdepth,'kernel','Kernel','normal');
% fplot(@(x) pdf(pd,x),[-10 8], 'Linewidth', 3);
% pd = fitdist(df_ByTrack_on.elev_residuals_vertcoreg,'kernel','Kernel','normal');
% fplot(@(x) pdf(pd,x),[-10 8], 'Linewidth', 3);
% xline(nanmean(df_ByTrack_on.snowdepth), 'Linewidth', 3,'Color','blue')
% xline(median(df_ByTrack_on.elev_residuals_vertcoreg,'omitnan'), 'Linewidth', 3,'Color','red')
% set(gca,'fontsize',16,'xlim',xbounds);
% %set(gcf,'position',[50 50 800 400]);
% xlabel('Snow Depth (m)'); ylabel('Probability density');
% legend('Helicopter Lidar Snow Depth','ICESat-2 Snow Depth','Median Heli Snow Depth','Median ICESat-2 Snow Depth','Location','northwest');
% title('By Track Coregistration')
% hold off

%% Non-parametric pdfs
xbounds = [-4 6];
% Not vertically coregistered - snow free
dates = datetime(df_agg.time.Year,df_agg.time.Month,df_agg.time.Day);
unique_dates = unique(dates);
% 
% for i = 1:length(unique_dates)
%     df_noCoreg_temp = df_noCoreg_on(datetime(df_noCoreg_on.time.Year,df_noCoreg_on.time.Month,df_noCoreg_on.time.Day) == unique_dates(i),:);
%     df_agg_temp = df_agg_on(datetime(df_agg_on.time.Year,df_agg_on.time.Month,df_agg_on.time.Day) == unique_dates(i),:);
%     df_ByTrack_temp = df_ByTrack_on(datetime(df_ByTrack_on.time.Year,df_ByTrack_on.time.Month,df_ByTrack_on.time.Day) == unique_dates(i),:);
% 
%     figure(i + 3); clf;
%     subplot(3,1,1); hold on
%     pd = fitdist(df_noCoreg_temp.snowdepth,'kernel','Kernel','normal');
%     fplot(@(x) pdf(pd,x),[-10 8], 'Linewidth', 3);
%     pd = fitdist(df_noCoreg_temp.elev_residuals_vertcoreg,'kernel','Kernel','normal');
%     fplot(@(x) pdf(pd,x),[-10 8], 'Linewidth', 3);
%     xline(median(df_noCoreg_temp.snowdepth,'omitnan'), 'Linewidth', 3,'Color','blue')
%     xline(median(df_noCoreg_temp.elev_residuals_vertcoreg,'omitnan'), 'Linewidth', 3,'Color','red')
%     set(gca,'fontsize',16,'xlim',xbounds);
%     %set(gcf,'position',[50 50 800 400]);
%     %xlabel('Snow Depth (m)'); ylabel('Probability density');
%     %legend('Helicopter Lidar Snow Depth','ICESat-2 Snow Depth','Average Heli Snow Depth','Median ICESat-2 Snow Depth','Location','northwest');
%     title(['No Coregistration - ' string(unique_dates(i))])
%     legend('Helicopter Lidar Snow Depth','ICESat-2 Snow Depth','Median Heli Snow Depth','Median ICESat-2 Snow Depth','Location','northeast');
%     hold off
% 
%     subplot(3,1,2); hold on
%     pd = fitdist(df_agg_temp.snowdepth,'kernel','Kernel','normal');
%     fplot(@(x) pdf(pd,x),[-10 8], 'Linewidth', 3);
%     pd = fitdist(df_agg_temp.elev_residuals_vertcoreg,'kernel','Kernel','normal');
%     fplot(@(x) pdf(pd,x),[-10 8], 'Linewidth', 3);
%     xline(median(df_agg_temp.snowdepth,'omitnan'), 'Linewidth', 3,'Color','blue')
%     xline(median(df_agg_temp.elev_residuals_vertcoreg,'omitnan'), 'Linewidth', 3,'Color','red')
%     set(gca,'fontsize',16,'xlim',xbounds);
%     %set(gcf,'position',[50 50 800 400]);
%     %xlabel('Snow Depth (m)'); 
%     ylabel('Probability density');
%     %legend('Helicopter Lidar Snow Depth','ICESat-2 Snow Depth','Average Heli Snow Depth','Median ICESat-2 Snow Depth','Location','northwest');
%     title('Aggregated Coregistration')
%     hold off
% 
%     % Vertically coregistered - snow free & snow on
%     if sum(~isnan(df_ByTrack_temp.snowdepth)) ~= 0
%         subplot(3,1,3); hold on
%         pd = fitdist(df_ByTrack_temp.snowdepth,'kernel','Kernel','normal');
%         fplot(@(x) pdf(pd,x),[-10 8], 'Linewidth', 3);
%         pd = fitdist(df_ByTrack_temp.elev_residuals_vertcoreg,'kernel','Kernel','normal');
%         fplot(@(x) pdf(pd,x),[-10 8], 'Linewidth', 3);
%         xline(median(df_ByTrack_temp.snowdepth,'omitnan'), 'Linewidth', 3,'Color','blue')
%         xline(median(df_ByTrack_temp.elev_residuals_vertcoreg,'omitnan'), 'Linewidth', 3,'Color','red')
%         set(gca,'fontsize',16,'xlim',xbounds);
%         %set(gcf,'position',[50 50 800 400]);
%         xlabel('Snow Depth (m)'); %ylabel('Probability density');
%         %legend('Helicopter Lidar Snow Depth','ICESat-2 Snow Depth','Average Heli Snow Depth','Median ICESat-2 Snow Depth','Location','northwest');
%         title('By Track Coregistration')
%         hold off
%     end
% end

%% Snow depth pdfs
figure(2); clf;
hold on
pd = fitdist(df_noCoreg_on.elev_residuals_vertcoreg,'kernel','Kernel','normal');
fplot(@(x) pdf(pd,x),[-10 8], 'Linewidth', 3);
pd = fitdist(df_agg_on.elev_residuals_vertcoreg,'kernel','Kernel','normal');
fplot(@(x) pdf(pd,x),[-10 8], 'Linewidth', 3);
pd = fitdist(df_ByTrack_on.elev_residuals_vertcoreg,'kernel','Kernel','normal');
fplot(@(x) pdf(pd,x),[-10 8], 'Linewidth', 3);
set(gca,'fontsize',16,'xlim',xbounds);
%set(gcf,'position',[50 50 800 400]);
xlabel('Snow Depth (m)'); ylabel('Probability density');
legend('No Coregistration', 'Aggregated Coregistration', 'By Track Coregistration');
hold off

%% snow depth residuals pdfs
xbounds = [-4 4];
% Not vertically coregistered - snow free
figure(3); clf; 
hold on
pd = fitdist((df_noCoreg_on.elev_residuals_vertcoreg - df_noCoreg_on.snowdepth),'kernel','Kernel','normal');
fplot(@(x) pdf(pd,x),[-10 8], 'Linewidth', 4,'Color', Coreg_colors(1,:),'LineStyle','-');
pd = fitdist((df_agg_on.elev_residuals_vertcoreg - df_agg_on.snowdepth),'kernel','Kernel','normal');
fplot(@(x) pdf(pd,x),[-10 8], 'Linewidth', 4,'Color', Coreg_colors(2,:),'LineStyle','-');
pd = fitdist((df_ByTrack_on.elev_residuals_vertcoreg - df_ByTrack_on.snowdepth),'kernel','Kernel','normal');
fplot(@(x) pdf(pd,x),[-10 8], 'Linewidth', 4,'Color', Coreg_colors(3,:),'LineStyle','-');
xline(0, 'Linewidth', 1,'Color','black');
% xline(median((df_noCoreg_on.elev_residuals_vertcoreg - df_noCoreg_on.snowdepth),'omitnan'), 'Linewidth', 2,'Color',"#0072BD")
% xline(median((df_agg_on.elev_residuals_vertcoreg - df_agg_on.snowdepth),'omitnan'), 'Linewidth', 2,'Color',"#D95319")
% xline(median((df_ByTrack_on.elev_residuals_vertcoreg - df_ByTrack_on.snowdepth),'omitnan'), 'Linewidth', 2,'Color',	"#EDB120")
set(gca,'fontsize',14,'xlim',xbounds);
%set(gcf,'position',[50 50 800 400]);
xlabel('Snow depth error (m)'); ylabel('Probability density');
legend('No Coregistration', 'Aggregated Coregistration', 'Individual Coregistration', '', 'Filtered to slopes below 20 degrees');
hold off


% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% snow depth by elevation plots
figure(1);

    clear groupElev elev_binedges bins snowdepth snowdepth_elevgroup

    df_on_temp = df_agg_on;
    df_on_temp1 = df_on_temp(month(df_on_temp.time) == 2 ,:);
    df_on_temp2 = df_on_temp(month(df_on_temp.time) == 3 ,:);
    df_on_temp = [df_on_temp1; df_on_temp2];

    df_on_temp = df_on_temp(~isnan(df_on_temp.elevation_report_nw_mean),:);

    % elevation grouping
    elev_binedges = 1000:100:3000;
    for i = 2:length(elev_binedges)
        bins{i-1} = num2str(elev_binedges(i));
    end
    groupElev = discretize(df_on_temp.elevation_report_nw_mean, elev_binedges);
    groupElev = elev_binedges(groupElev)';
    groupElevCat = discretize(df_on_temp.elevation_report_nw_mean, elev_binedges,'categorical',bins);

    snowdepth = table(groupElevCat, groupElev, df_on_temp.snowdepth, 'VariableNames',["elevationCAT", "elevation","residuals"]);
    snowdepth = snowdepth(~isnan(snowdepth.residuals),:);
    snowdepth_elevgroup = varfun(@(x)median(x,'omitnan'),snowdepth,'GroupingVariables',{'elevation'});
    for i = 1:length(snowdepth_elevgroup.elevation)
        if snowdepth_elevgroup.GroupCount(i) < 30
            snowdepth.residuals(snowdepth.elevation == snowdepth_elevgroup.elevation(i)) = NaN;
        end
    end
    snowdepth_elevgroup = varfun(@(x)median(x,'omitnan'),snowdepth,'GroupingVariables',{'elevation'});

    snowdepth = snowdepth(~isnan(snowdepth.residuals),:);
    linearfit = fit(snowdepth.elevation, snowdepth.residuals,'poly1');

    figure(1)
    subplot(4,3,[1 2 4 5 7 8 10 11])
    hold on
    scatter(snowdepth_elevgroup.elevation,snowdepth_elevgroup.Fun_residuals,75,'MarkerEdgeColor','k','Marker',site_shapes(3))
    set(gca,'fontsize',14);
    xlabel('Elevation (m)'); ylabel('Median ICESat-2 snow depth (m)')
    hold off


figure(1)
hold on
subplot(4,3,[1 2 4 5 7 8 10 11])
ylim([0 3]);
% cut fit lines to data range
plot([1800 2200],[1.91 2.81], 'Color','k');

legend('Reynolds Creek','Banner Summit','Mores Creek','Dry Creek','','','','','Mores Creek Helicoper Survey')
% 
% figure(1)
% hold on
% subplot(4,3,9)
% plot([categorical("1900") categorical("2200")],[1.91 2.81], 'Color','k');


% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% %% negative ICESat-2 snow depth removed
% xbounds = [-4 6];
% IS2_snowdepth_noCoreg = df_noCoreg_on.elev_residuals_vertcoreg;
% IS2_snowdepth_noCoreg(IS2_snowdepth_noCoreg < 0) = NaN;
% IS2_snowdepth_agg = df_agg_on.elev_residuals_vertcoreg;
% IS2_snowdepth_agg(IS2_snowdepth_agg < 0) = NaN;
% IS2_snowdepth_ByTrack = df_ByTrack_on.elev_residuals_vertcoreg;
% IS2_snowdepth_ByTrack(IS2_snowdepth_ByTrack < 0) = NaN;
% % Not vertically coregistered - snow free
% figure(4); clf; 
% subplot(3,1,1); hold on
% pd = fitdist(df_noCoreg_on.snowdepth,'kernel','Kernel','normal');
% fplot(@(x) pdf(pd,x),[-10 8], 'Linewidth', 3);
% pd = fitdist(IS2_snowdepth_noCoreg,'kernel','Kernel','normal');
% fplot(@(x) pdf(pd,x),[-10 8], 'Linewidth', 3);
% xline(nanmean(df_noCoreg_on.snowdepth), 'Linewidth', 3,'Color','blue')
% xline(median(IS2_snowdepth_noCoreg,'omitnan'), 'Linewidth', 3,'Color','red')
% set(gca,'fontsize',16,'xlim',xbounds);
% %set(gcf,'position',[50 50 800 400]);
% xlabel('Snow Depth (m)'); ylabel('Probability density');
% legend('Helicopter Lidar Snow Depth','ICESat-2 Snow Depth','Average Heli Snow Depth','Median ICESat-2 Snow Depth','Location','northwest');
% title('No Coregistration')
% hold off
% 
% subplot(3,1,2); hold on
% pd = fitdist(df_agg_on.snowdepth,'kernel','Kernel','normal');
% fplot(@(x) pdf(pd,x),[-10 8], 'Linewidth', 3);
% pd = fitdist(IS2_snowdepth_agg,'kernel','Kernel','normal');
% fplot(@(x) pdf(pd,x),[-10 8], 'Linewidth', 3);
% xline(nanmean(df_agg_on.snowdepth), 'Linewidth', 3,'Color','blue')
% xline(median(IS2_snowdepth_agg,'omitnan'), 'Linewidth', 3,'Color','red')
% set(gca,'fontsize',16,'xlim',xbounds);
% %set(gcf,'position',[50 50 800 400]);
% xlabel('Snow Depth (m)'); ylabel('Probability density');
% legend('Helicopter Lidar Snow Depth','ICESat-2 Snow Depth','Average Heli Snow Depth','Median ICESat-2 Snow Depth','Location','northwest');
% title('Aggregated Coregistration')
% hold off
% 
% % Vertically coregistered - snow free & snow on
% subplot(3,1,3); hold on
% pd = fitdist(df_ByTrack_on.snowdepth,'kernel','Kernel','normal');
% fplot(@(x) pdf(pd,x),[-10 8], 'Linewidth', 3);
% pd = fitdist(IS2_snowdepth_ByTrack,'kernel','Kernel','normal');
% fplot(@(x) pdf(pd,x),[-10 8], 'Linewidth', 3);
% xline(nanmean(df_ByTrack_on.snowdepth), 'Linewidth', 3,'Color','blue')
% xline(median(IS2_snowdepth_ByTrack,'omitnan'), 'Linewidth', 3,'Color','red')
% set(gca,'fontsize',16,'xlim',xbounds);
% %set(gcf,'position',[50 50 800 400]);
% xlabel('Snow Depth (m)'); ylabel('Probability density');
% legend('Helicopter Lidar Snow Depth','ICESat-2 Snow Depth','Average Heli Snow Depth','Median ICESat-2 Snow Depth','Location','northwest');
% title('By Track Coregistration')
% hold off
% 
% %% Snow depth pdfs
% figure(5); clf;
% hold on
% pd = fitdist(IS2_snowdepth_noCoreg,'kernel','Kernel','normal');
% fplot(@(x) pdf(pd,x),[-10 8], 'Linewidth', 3);
% pd = fitdist(IS2_snowdepth_agg,'kernel','Kernel','normal');
% fplot(@(x) pdf(pd,x),[-10 8], 'Linewidth', 3);
% pd = fitdist(IS2_snowdepth_ByTrack,'kernel','Kernel','normal');
% fplot(@(x) pdf(pd,x),[-10 8], 'Linewidth', 3);
% set(gca,'fontsize',16,'xlim',xbounds);
% %set(gcf,'position',[50 50 800 400]);
% xlabel('Snow Depth (m)'); ylabel('Probability density');
% legend('No Coregistration', 'Aggregated Coregistration', 'By Track Coregistration');
% hold off
% 
% %% snow depth residuals pdfs
% xbounds = [-8 6];
% % Not vertically coregistered - snow free
% figure(6); clf; 
% hold on
% pd = fitdist((IS2_snowdepth_noCoreg - df_ByTrack_on.snowdepth),'kernel','Kernel','normal');
% fplot(@(x) pdf(pd,x),[-10 8], 'Linewidth', 3);
% pd = fitdist((IS2_snowdepth_agg - df_agg_on.snowdepth),'kernel','Kernel','normal');
% fplot(@(x) pdf(pd,x),[-10 8], 'Linewidth', 3);
% pd = fitdist((IS2_snowdepth_ByTrack - df_ByTrack_on.snowdepth),'kernel','Kernel','normal');
% fplot(@(x) pdf(pd,x),[-10 8], 'Linewidth', 3);
% set(gca,'fontsize',16,'xlim',xbounds);
% %set(gcf,'position',[50 50 800 400]);
% xlabel('Snow Depth Residuals (m)'); ylabel('Probability density');
% legend('No Coregistration', 'Aggregated Coregistration', 'By Track Coregistration');
% hold off
% 
% %% each date
% for i = 1:length(unique_dates)
%     df_noCoreg_temp = df_noCoreg_on(datetime(df_noCoreg_on.time.Year,df_noCoreg_on.time.Month,df_noCoreg_on.time.Day) == unique_dates(i),:);
%     df_agg_temp = df_noCoreg_on(datetime(df_agg_on.time.Year,df_agg_on.time.Month,df_agg_on.time.Day) == unique_dates(i),:);
%     df_ByTrack_temp = df_ByTrack_on(datetime(df_ByTrack_on.time.Year,df_ByTrack_on.time.Month,df_ByTrack_on.time.Day) == unique_dates(i),:);
%     df_noCoreg_temp.elev_residuals_vertcoreg(df_noCoreg_temp.elev_residuals_vertcoreg < 0) = NaN;
%     df_agg_temp.elev_residuals_vertcoreg(df_agg_temp.elev_residuals_vertcoreg < 0) = NaN;
%     df_ByTrack_temp.elev_residuals_vertcoreg(df_ByTrack_temp.elev_residuals_vertcoreg < 0) = NaN;
%     figure; clf;
%     subplot(3,1,1); hold on
%     pd = fitdist(df_noCoreg_temp.snowdepth,'kernel','Kernel','normal');
%     fplot(@(x) pdf(pd,x),[-10 8], 'Linewidth', 3);
%     pd = fitdist(df_noCoreg_temp.elev_residuals_vertcoreg,'kernel','Kernel','normal');
%     fplot(@(x) pdf(pd,x),[-10 8], 'Linewidth', 3);
%     xline(nanmean(df_noCoreg_temp.snowdepth), 'Linewidth', 3,'Color','blue')
%     xline(median(df_noCoreg_temp.elev_residuals_vertcoreg,'omitnan'), 'Linewidth', 3,'Color','red')
%     set(gca,'fontsize',16,'xlim',xbounds);
%     %set(gcf,'position',[50 50 800 400]);
%     xlabel('Snow Depth (m)'); ylabel('Probability density');
%     legend('Helicopter Lidar Snow Depth','ICESat-2 Snow Depth','Average Heli Snow Depth','Median ICESat-2 Snow Depth','Location','northwest');
%     title('No Coregistration')
%     hold off
% 
%     subplot(3,1,2); hold on
%     pd = fitdist(df_agg_temp.snowdepth,'kernel','Kernel','normal');
%     fplot(@(x) pdf(pd,x),[-10 8], 'Linewidth', 3);
%     pd = fitdist(df_agg_temp.elev_residuals_vertcoreg,'kernel','Kernel','normal');
%     fplot(@(x) pdf(pd,x),[-10 8], 'Linewidth', 3);
%     xline(nanmean(df_agg_temp.snowdepth), 'Linewidth', 3,'Color','blue')
%     xline(median(df_agg_temp.elev_residuals_vertcoreg,'omitnan'), 'Linewidth', 3,'Color','red')
%     set(gca,'fontsize',16,'xlim',xbounds);
%     %set(gcf,'position',[50 50 800 400]);
%     xlabel('Snow Depth (m)'); ylabel('Probability density');
%     legend('Helicopter Lidar Snow Depth','ICESat-2 Snow Depth','Average Heli Snow Depth','Median ICESat-2 Snow Depth','Location','northwest');
%     title('Aggregated Coregistration')
%     hold off
% 
%     % Vertically coregistered - snow free & snow on
%     subplot(3,1,3); hold on
%     pd = fitdist(df_ByTrack_temp.snowdepth,'kernel','Kernel','normal');
%     fplot(@(x) pdf(pd,x),[-10 8], 'Linewidth', 3);
%     pd = fitdist(df_ByTrack_temp.elev_residuals_vertcoreg,'kernel','Kernel','normal');
%     fplot(@(x) pdf(pd,x),[-10 8], 'Linewidth', 3);
%     xline(nanmean(df_ByTrack_temp.snowdepth), 'Linewidth', 3,'Color','blue')
%     xline(median(df_ByTrack_temp.elev_residuals_vertcoreg,'omitnan'), 'Linewidth', 3,'Color','red')
%     set(gca,'fontsize',16,'xlim',xbounds);
%     %set(gcf,'position',[50 50 800 400]);
%     xlabel('Snow Depth (m)'); ylabel('Probability density');
%     legend('Helicopter Lidar Snow Depth','ICESat-2 Snow Depth','Average Heli Snow Depth','Median ICESat-2 Snow Depth','Location','northwest');
%     title('By Track Coregistration')
%     hold off
% end

