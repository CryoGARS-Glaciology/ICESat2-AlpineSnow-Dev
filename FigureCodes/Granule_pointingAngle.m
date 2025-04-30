%%% Make Snow Depth timeseries figure
%%%
%%% SPECIFIED INPUTS:


%% Inputs
clearvars;
addpath(['/Users/karinazikan/Documents/cmocean'])

%Folder path
folderpath = '/Users/karinazikan/Documents/ICESat2-AlpineSnow/Sites/';

site_abbrevs = string({'RCEW';'Banner';'MCS';'DCEW'});
site_names = string({'RCEW';'BCS';'MCS';'DCEW'});

%Turn dtm or is2 slope correction
slope_correction = 1; % 0 = dtm, 1 = is2, 2 = no slope correction
%Turn dtm or is2 slope correction
slope_filter = 2; % 0 = none, 1 = remove slopes < slope_threshhold. 2 = remove slopes > slope_threshhold
slope_threshhold = 10;
% ICESat-2 residuals below 0 to NaN?
remove_negative = 1; % 0 = off, 1 = on

site_colors = ["#3dd6ff";"#6494ff";"#973ed3";"#77007a"];%["#360096";"#004df8";"#47a337";"#ffa83f"]; %["#a1dab4";"#41b6c4";"#2c7fb8";"#253494"]; %['#FFD700';'#FA8775';'#CD34B5';'#0000FF'];% '#E69F00';'#56B4E9';'#D55E00';'#009E73'];
site_colors_darker = ["#007ab6";"#003db5";"#2a0086";"#2e0033"];
site_shapes = ["o";"square";"diamond";"^"];
Coreg_colors = ['#FA8775';'#CD34B5';'#0000FF'];

%% Load data
% IS2 data
for j = 1:length(site_abbrevs)
    filepath = strcat(folderpath, site_abbrevs(j), '/IS2_Data/A6-40/ATL06-A6-40-AllData-fineGS-agg_on.csv');
    df_on{j} = readtable(filepath);
    filepath = strcat(folderpath, site_abbrevs(j), '/IS2_Data/A6-40/ATL06-A6-40-AllData-fineGS-agg_off.csv');
    df_off{j} = readtable(filepath);
    % slope correction
    if slope_correction == 1
        df_off{j}.elev_residuals_vertcoreg = df_off{j}.elev_residuals_vertcoreg_is2_slopecorrected;
        df_on{j}.elev_residuals_vertcoreg = df_on{j}.elev_residuals_vertcoreg_is2_slopecorrected;
        df_off{j}.slope_mean = df_off{j}.IS2_slope_deg;
        df_on{j}.slope_mean = df_on{j}.IS2_slope_deg;
        if  j == 1
            ('IS2 Slope correction used')
        end
    elseif slope_correction == 2
        if j == 1
            ('No Slope correction used')
        end
    else
        df_off{j}.elev_residuals_vertcoreg = df_off{j}.elev_residuals_vertcoreg_dtm_slopecorrected;
        df_on{j}.elev_residuals_vertcoreg = df_on{j}.elev_residuals_vertcoreg_dtm_slopecorrected;
        df_off{j}.slope_mean = df_off{j}.IS2_slope_deg;
        df_on{j}.slope_mean = df_on{j}.IS2_slope_deg;
        if j == 1
            ('DTM Slope correction used')
        end
    end
    if slope_filter == 1
        df_off{j}(df_off{j}.slope_mean < slope_threshhold,:) = [];
        df_on{j}(df_on{j}.slope_mean < slope_threshhold,:) = [];
    elseif slope_filter == 2
        df_off{j}(df_off{j}.slope_mean > slope_threshhold,:) = [];
        df_on{j}(df_on{j}.slope_mean > slope_threshhold,:) = [];
    end
    % remove negative ICESat-2 elevation residuals
    if remove_negative == 1
        df_on{j}.elev_residuals_vertcoreg(df_on{j}.elev_residuals_vertcoreg < 0) = NaN;
        if  j == 1
            ('Negative ICESat-2 snow depth removed')
        end
    end
end

% pointing angle
granuel_files = dir([folderpath 'snowex_toos_atl03_ai_20241121/' '*.csv']);
for j = 1:length(granuel_files)
    granuel = readtable([folderpath 'snowex_toos_atl03_ai_20241121/' granuel_files(j).name]);
    % for i = 2:length(granuel_files)
    %     file = readtable([folderpath granuel_files(i).name]);
    %     granuel = cat(1,granuel,file);
    % end
    granuel(granuel.lon < -117,:) = []; granuel(granuel.lon > -115,:) = [];
    granuel(granuel.lat < 43,:) = []; granuel(granuel.lat > 44.5,:) = [];

    start_time = datetime(2018, 01, 01);
    time = start_time + seconds(granuel.delta_time);
    granuel.time = time;

    % group data
    G = findgroups(granuel.gt, granuel.yyyymmdd);
    group_ref_pa_deg = splitapply(@(x){x}, [granuel.ref_pa_deg] , G);
    group_time = splitapply(@(x){x}, [granuel.time] , G);
    max_angle(j) = max(group_ref_pa_deg{length(group_ref_pa_deg)});
    gran_dates(j) = datetime(time(1).Year,time(1).Month,time(1).Day);

    % % plot
    % figure(j); clf
    % % angle over time
    % subplot(2,1,1)
    % hold on
    % for i = 1:length(group_ref_pa_deg)
    %     plot(group_time{i}, group_ref_pa_deg{i}, 'LineWidth',3)
    %     xlabel('time'); ylabel('angle (deg)')
    %     %set(gca,'fontsize',20);
    % end
    % hold off
    % 
    % % location plot
    % subplot(2,1,2)
    % geoscatter(granuel.lat,granuel.lon,"filled")
    % geobasemap topographic
end
%%
%bin by slope
slope_binedges = 1:5:55;
tbl.slope = []; tbl.elevRes = []; tbl.group = [];
Cat_groupSlope = []; Cat_df_off = [];
clear group
bins = {num2str(slope_binedges(2))};
for i = 3:length(slope_binedges)
    bins = [bins; {num2str(slope_binedges(i))}];
end

% clear figs
for i = 1:5
    figure(i); clf
    set(gca,'fontsize',16);
end

for j = 1:length(site_abbrevs)
    df_off_temp = df_off{j};

    if j == 1
        df_off_temp(df_off_temp.time.Month > 11,:) = [];
        df_off_temp(df_off_temp.time.Month < 5,:) = [];
    else
        df_off_temp(df_off_temp.time.Month > 10,:) = [];
        df_off_temp(df_off_temp.time.Month < 6,:) = [];
    end
    % group into slope bins
    groupSlope = discretize(df_off_temp.slope_mean,slope_binedges,'categorical',bins);
    tbl.slope = [tbl.slope; groupSlope];
    group(1:length(groupSlope),:) = j;
    tbl.elevRes = [tbl.elevRes; df_off_temp.elev_residuals_vertcoreg];
    tbl.group = [tbl.group; group];

    % cycle through dates
    dates = datetime(df_off_temp.time.Year,df_off_temp.time.Month,df_off_temp.time.Day);
    unique_dates = unique(dates);

    for i = 1:length(unique_dates)
        ix = find(dates == unique_dates(i));
        df_temp = df_off_temp(ix,:);
        if ~isempty(max_angle(gran_dates == unique_dates(i)))
            ave_slope{j}(i) = nanmean(df_temp.slope_mean);
            std_slope{j}(i) = std(df_temp.slope_mean);
            Rnmad{j}(i) = 1.4826*median(abs(df_temp.elev_residuals_vertcoreg-nanmean(df_temp.elev_residuals_vertcoreg)),'omitnan'); % normalized meadian absolute difference
            RMSE{j}(i) = sqrt(nanmean((df_temp.elev_residuals_vertcoreg).^2)); % Root mean square error
            Rmedian{j}(i) = median(df_temp.elev_residuals_vertcoreg,'omitnan'); % median
            Rangle{j}(i) = max_angle(gran_dates == unique_dates(i));
        elseif isempty(max_angle(gran_dates == unique_dates(i)))
            ave_slope{j}(i) = NaN;
            std_slope{j}(i) = NaN;
            Rnmad{j}(i) = NaN; % normalized meadian absolute difference
            RMSE{j}(i) = NaN; % Root mean square error
            Rmedian{j}(i) = NaN; % median
            Rangle{j}(i) = NaN;
        end
    end

    figure(1);
    hold on
    scatter(Rangle{j},Rnmad{j},100,'filled','MarkerFaceColor',site_colors(j,:),'Marker',site_shapes(j))
    xline(0, 'Linewidth', 1,'Color','black');
    hold off
    xlabel('pointing angle'); ylabel('snow free NMAD')

    figure(2);
    hold on
    scatter(Rangle{j},Rmedian{j},100,'filled','MarkerFaceColor',site_colors(j,:),'Marker',site_shapes(j))
    hold off

    figure(3);
    hold on
    scatter(Rangle{j},Rmedian{j},100,ave_slope{j},'filled','Marker',site_shapes(j))
    hold off

    figure(4);
    hold on
    scatter(Rangle{j},Rmedian{j},100,std_slope{j},'filled','Marker',site_shapes(j))
    hold off

    figure(5);
    hold on
    scatter(unique_dates,Rangle{j},100,'filled','Marker',site_shapes(j),'MarkerFaceColor',site_colors(j,:))
    %scatter(unique_dates,Rangle{j},100,ave_slope{j},'filled','Marker',site_shapes(j))
    hold off

    figure(6);
    hold on
    scatter(unique_dates,ave_slope{j},100,'filled','Marker',site_shapes(j),'MarkerFaceColor',site_colors(j,:))
    %scatter(unique_dates,Rangle{j},100,ave_slope{j},'filled','Marker',site_shapes(j))
    hold off
end

figure(1);
hold on
yline(0, 'Linewidth', 1,'Color','black');
line = lsline;
for j = 1:length(site_abbrevs)
    line(j).Color = site_colors(5-j,:);
end
hold off
%ylim([-0.8, 0.5])
xlabel('pointing angle'); ylabel('snow free NMAD')
legend(site_names)

figure(2);
hold on
yline(0, 'Linewidth', 1,'Color','black');
% line = lsline;
% for j = 1:length(site_abbrevs)
%     line(j).Color = site_colors(5-j,:);
%     B = [ones(size(line(j).XData(:))), line(j).XData(:)]\line(j).YData(:);
%     Slope(5-j) = B(2);
%     Intercept(5-j) = B(1);
% end
hold off
ylim([-1.5, 1])
xlabel('Maximum off-pointing angle (degrees)'); ylabel('snow-free median ICESat-2 elevation residual (m)')
if slope_filter == 2
    title(['Slopes below ' num2str(slope_threshhold) ' degrees'])
elseif slope_filter == 1
    title(['Slopes above ' num2str(slope_threshhold) ' degrees'])
end
legend(site_names)

figure(3);
hold on
yline(0, 'Linewidth', 1,'Color','black');
hold off
%ylim([-0.8, 0.5])
xlabel('Maximum off-pointing angle (degrees)'); ylabel('snow-free median ICESat-2 elevation residual (m)')
legend(site_names)
c = colorbar;
c.Label.String = 'Average slope (degrees)';

figure(4);
hold on
yline(0, 'Linewidth', 1,'Color','black');
hold off
%ylim([-0.8, 0.5])
xlabel('Maximum off-pointing angle (degrees)'); ylabel('snow-free median ICESat-2 elevation residual (m)')
legend(site_names)
c = colorbar;
c.Label.String = 'Standard deviation of slope (degrees)';

figure(5);
%ylim([-0.8, 0.5])
xlabel('Maximum off-pointing angle (degrees)');
legend(site_names)
% colormap cool;
% c = colorbar;
% c.Label.String = 'Average slope (degrees)';

figure(6);
%ylim([-0.8, 0.5])
ylabel('average slope (degrees)');
legend(site_names)



