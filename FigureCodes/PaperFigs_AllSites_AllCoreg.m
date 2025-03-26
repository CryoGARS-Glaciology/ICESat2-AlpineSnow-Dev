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
Coreg_type = string({'noCoreg';'fineGS-agg';'fineGS-ByTrack'});

%Turn dtm or is2 slope correction
slope_correction = 1; % 0 = dtm, 1 = is2, 2 = no slope correction
%Turn dtm or is2 slope correction
slope_filter = 0; % 0 = none, 1 = remove slopes > 30 degrees
% ICESat-2 residuals below 0 to NaN?
remove_negative = 1; % 0 = off, 1 = on

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

site_colors = ["#3dd6ff";"#6494ff";"#973ed3";"#77007a"];%["#360096";"#004df8";"#47a337";"#ffa83f"]; %["#a1dab4";"#41b6c4";"#2c7fb8";"#253494"]; %['#FFD700';'#FA8775';'#CD34B5';'#0000FF'];% '#E69F00';'#56B4E9';'#D55E00';'#009E73'];
site_colors_darker = ["#007ab6";"#003db5";"#2a0086";"#2e0033"];
site_shapes = ["o";"square";"diamond";"^"];
Coreg_colors = ['#FA8775';'#CD34B5';'#0000FF'];


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
            end
        elseif slope_correction == 2
            if k ==1 && j == 1
                ('No Slope correction used')
            end
        else
            df_off{j,k}.elev_residuals_vertcoreg = df_off{j,k}.elev_residuals_vertcoreg_dtm_slopecorrected;
            df_on{j,k}.elev_residuals_vertcoreg = df_on{j,k}.elev_residuals_vertcoreg_dtm_slopecorrected;
            df_off{j,k}.slope_mean = df_off{j,k}.IS2_slope_deg;
            df_on{j,k}.slope_mean = df_on{j,k}.IS2_slope_deg;
            if k ==1 && j == 1
                ('DTM Slope correction used')
            end
        end
        if slope_filter == 1
            df_off{j,k}(df_off{j,k}.slope_mean > 30,:) = [];
            df_on{j,k}(df_on{j,k}.slope_mean > 30,:) = [];
        end
        % remove negative ICESat-2 elevation residuals
        if remove_negative == 1
            df_on{j,k}.elev_residuals_vertcoreg(df_on{j,k}.elev_residuals_vertcoreg < 0) = NaN;
            if k ==1 && j == 1
                ('Negative ICESat-2 snow depth removed')
            end
        end
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
    
    for k = 1:length(Coreg_type)
        % Filter to near snotel station
        window = 500;
        df_window_on{j,k} = df_on{j,k}((df_on{j,k}.Easting <= (snotel_E{j} + window) & df_on{j,k}.Easting >= (snotel_E{j} - window)),:);
        df_window_on{j,k} = df_window_on{j,k}((df_window_on{j,k}.Northing <= (snotel_N{j} + window) & df_window_on{j,k}.Northing >= (snotel_N{j} - window)),:);

        % Only tracks that go through SNOTEL
        dates_on = datetime(df_on{j,k}.time.Year,df_on{j,k}.time.Month,df_on{j,k}.time.Day);
        groups = findgroups(dates_on,df_on{j,k}.gt);
        unique_tracks = unique(groups);
        df_thruTracks_on{j,k} = df_on{j,k};
        for i = 1:length(unique_tracks)
            ix = groups == unique_tracks(i);
            df_ix = df_on{j,k}(ix,:);
            df_ix = df_ix((df_ix.Easting <= (snotel_E{j} + window) & df_ix.Easting >= (snotel_E{j} - window)),:);
            df_ix = df_ix((df_ix.Northing <= (snotel_N{j} + window) & df_ix.Northing >= (snotel_N{j} - window)),:);
            if isempty(df_ix) == 1
                df_thruTracks_on{j,k}.elev_residuals_vertcoreg(ix) = NaN;
            end
        end
    end
    clear df_ix dates_on groups unique_tracks
end

%% Stats
for k = 1:length(Coreg_type)
    for j = 1:length(site_abbrevs)
        Rnmad(j,k) = 1.4826*median(abs(df_off{j,k}.elev_residuals_vertcoreg-nanmean(df_off{j,k}.elev_residuals_vertcoreg)),'omitnan'); % normalized meadian absolute difference
        RMSE(j,k) = sqrt(nanmean((df_off{j,k}.elev_residuals_vertcoreg).^2)); % Root mean square error
        Rmedian(j,k) = median(df_off{j,k}.elev_residuals_vertcoreg,'omitnan'); % median
    end
end

%% Plots
%% Coregistration types

figure(12); clf
xbounds = [-1,1];
for  j = 1:length(site_abbrevs)
    if j < 3
        xbounds = [-2,2];
    else
        xbounds = [-3,3];
    end
    subplot(2,2,j); hold on
    for k = 1:length(Coreg_type)
        pd = fitdist(df_off{j,k}.elev_residuals_vertcoreg,'kernel','Kernel','normal');
        fplot(@(x) pdf(pd,x),[-10 8], 'Linewidth', 3,'Color',Coreg_colors(k,:));
    end
    title(site_names{j});
    xline(0, 'Linewidth', 1,'Color','black');
    set(gca,'fontsize',20,'xlim',xbounds);
    xlabel('Snow free Vertical offset (m)'); ylabel('Probability density');
end
%set(gcf,'position',[50 50 800 400]);

legend('No Coregistration','Aggregated Coregistration','By Track Coregistration');
hold off


%% Snow depth time series
%timeseries
for k = 2%1:length(Coreg_type)
    fig = figure(k); clf;
    for j = 1:length(site_abbrevs)
        df_on_temp = df_on{j,k};
        df_window_on_temp = df_window_on{j,k};
        df_thruTracks_on_temp = df_thruTracks_on{j,k};
        df_off_temp = df_off{j,k};
        snotel_temp = snotel{j};

        snowdepth = table([datetime(df_on_temp.time.Year,df_on_temp.time.Month,df_on_temp.time.Day)], df_on_temp.elev_residuals_vertcoreg, 'VariableNames',["time","residuals"]);
        snowdepth_dategroup = varfun(@(x)median(x,'omitnan'),snowdepth,'GroupingVariables',{'time'});
        snowdepth_window = table([datetime(df_window_on_temp.time.Year,df_window_on_temp.time.Month,df_window_on_temp.time.Day)], df_window_on_temp.elev_residuals_vertcoreg, 'VariableNames',["time","residuals"]);
        snowdepth_window_dategroup = varfun(@(x)median(x,'omitnan'),snowdepth_window,'GroupingVariables',{'time'});
        snowdepth_thruTracks = table([datetime(df_thruTracks_on_temp.time.Year,df_thruTracks_on_temp.time.Month,df_thruTracks_on_temp.time.Day)], df_thruTracks_on_temp.elev_residuals_vertcoreg, 'VariableNames',["time","residuals"]);
        snowdepth_thruTracks_dategroup = varfun(@(x)median(x,'omitnan'),snowdepth_thruTracks,'GroupingVariables',{'time'});
        elevresiduals = table([datetime(df_off_temp.time.Year,df_off_temp.time.Month,df_off_temp.time.Day)], df_off_temp.elev_residuals_vertcoreg, 'VariableNames',["time","residuals"]);
        elevresiduals_dategroup = varfun(@(x)median(x,'omitnan'),elevresiduals,'GroupingVariables',{'time'});
        snoteldepth = table(snotel_temp.Date, snotel_temp.SNWD_I_1_in_ ,'VariableNames',["time","SnowDepth"]);
        snoteldepth_dategroup = varfun(@(x)median(x,'omitnan'),snoteldepth,'GroupingVariables',{'time'});
        snoteldepth_dategroup_IS2_dates = snoteldepth_dategroup(ismember(snoteldepth_dategroup.time, elevresiduals_dategroup.time), :);

        subplot(4,1,j); hold on
        plot(snoteldepth_dategroup.time,snoteldepth_dategroup.Fun_SnowDepth, 'LineWidth',1,'Color','#969696')
        scatter(snowdepth_dategroup.time,snowdepth_dategroup.Fun_residuals,75,'filled','MarkerFaceColor',site_colors(j,:),'Marker',site_shapes(j))
        %scatter(snowdepth_thruTracks_dategroup.time,snowdepth_thruTracks_dategroup.Fun_residuals,75,'filled','MarkerFaceColor',[0.8500 0.3250 0.0980],'Marker',site_shapes(j))
        scatter(snowdepth_window_dategroup.time,snowdepth_window_dategroup.Fun_residuals,75,'filled','MarkerEdgeColor','k','Marker',site_shapes(j),'MarkerFaceColor','none')
        title(site_names{j});
        set(gca,'fontsize',14);
        xlim([datetime(2018,9,1) datetime(2024,6,1)])
        ylim([-0.5 4])
        ylabel('Snow Depth (m)')

        hold off
    end
    xlabel('Date'); ylabel('Snow Depth');
    legend('AWS median snow depth','ICESat-2 median snow depth','ICESat-2 median snow depth within 500 m of AWS');

    figure(k+3); clf
    for j = 1:length(site_abbrevs)
        df_on_temp = df_on{j,k};
        df_off_temp = df_off{j,k};
        snotel_temp = snotel{j};

        snowdepth = table([datetime(df_on_temp.time.Year,df_on_temp.time.Month,df_on_temp.time.Day)], df_on_temp.elev_residuals_vertcoreg, 'VariableNames',["time","residuals"]);
        snowdepth_dategroup = varfun(@(x)median(x,'omitnan'),snowdepth,'GroupingVariables',{'time'});
        elevresiduals = table([datetime(df_off_temp.time.Year,df_off_temp.time.Month,df_off_temp.time.Day)], df_off_temp.elev_residuals_vertcoreg, 'VariableNames',["time","residuals"]);
        elevresiduals_dategroup = varfun(@(x)median(x,'omitnan'),elevresiduals,'GroupingVariables',{'time'});
        snoteldepth = table(snotel_temp.Date, snotel_temp.SNWD_I_1_in_ ,'VariableNames',["time","SnowDepth"]);
        snoteldepth_dategroup = varfun(@(x)nanmean(x),snoteldepth,'GroupingVariables',{'time'});

        subplot(4,1,j); hold on
        plot(snoteldepth_dategroup.time,snoteldepth_dategroup.Fun_SnowDepth, 'LineWidth',2,'Color',[0.9290, 0.6940, 0.1250]	)
        scatter(elevresiduals_dategroup.time,elevresiduals_dategroup.Fun_residuals,75,'MarkerEdgeColor',[0.8500, 0.3250, 0.0980])
        scatter(snowdepth_dategroup.time,snowdepth_dategroup.Fun_residuals,75,'filled','MarkerFaceColor',[0, 0.4470, 0.7410])
        set(gca,'fontsize',20);
        title(site_names{j});
        hold off
        xlim([datetime(2018,1,1) datetime(2024,6,1)])
        ylim([-0.5 4])
        ylabel('Snow Depth')
    end
    legend('AWS mean snow depth','ICESat-2 median snow free elevation residuals','ICESat-2 median snow depth')
    sgtitle(Coreg_type{k});
    xlabel('Date');

    % figure(k+6); clf % plot snow free elevation residuals
    % for j = 1:length(site_abbrevs)
    %     df_on_temp = df_on{j,k};
    %     df_off_temp = df_off{j,k};
    %     snotel_temp = snotel{j};
    % 
    %     if j == 1
    %         df_off_temp(df_off_temp.time.Month > 11,:) = [];
    %         df_off_temp(df_off_temp.time.Month < 5,:) = [];
    %     else
    %         df_off_temp(df_off_temp.time.Month > 10,:) = [];
    %         df_off_temp(df_off_temp.time.Month < 6,:) = [];
    %     end
    % 
    %     snowdepth = table([datetime(df_on_temp.time.Year,df_on_temp.time.Month,df_on_temp.time.Day)], df_on_temp.elev_residuals_vertcoreg, 'VariableNames',["time","residuals"]);
    %     snowdepth_dategroup = varfun(@(x)median(x,'omitnan'),snowdepth,'GroupingVariables',{'time'});
    %     elevresiduals = table([datetime(df_off_temp.time.Year,df_off_temp.time.Month,df_off_temp.time.Day)], df_off_temp.elev_residuals_vertcoreg, 'VariableNames',["time","residuals"]);
    %     elevresiduals_dategroup = varfun(@(x)median(x,'omitnan'),elevresiduals,'GroupingVariables',{'time'});
    %     elevresiduals_error_dategroup = varfun(@(x)iqr(x),elevresiduals,'GroupingVariables',{'time'});
    %     snoteldepth = table(snotel_temp.Date, snotel_temp.SNWD_I_1_in_ ,'VariableNames',["time","SnowDepth"]);
    %     snoteldepth_dategroup = varfun(@(x)nanmean(x),snoteldepth,'GroupingVariables',{'time'});
    % 
    %     subplot(4,1,j); cla; hold on
    %     %plot(snoteldepth_dategroup.time,snoteldepth_dategroup.Fun_SnowDepth, 'LineWidth',2,'Color',[0.9290, 0.6940, 0.1250]	)
    %     %errorbar(elevresiduals_dategroup.time,elevresiduals_dategroup.Fun_residuals,elevresiduals_error_dategroup.Fun_residuals, 'vertical', 'LineStyle', 'none');
    %     scatter(elevresiduals_dategroup.time,elevresiduals_dategroup.Fun_residuals,75,'filled','o')
    %     %scatter(snowdepth_dategroup.time,snowdepth_dategroup.Fun_residuals,'filled','MarkerFaceColor',[0, 0.4470, 0.7410])
    %     yline(0)
    %     set(gca,'fontsize',20);
    %     title(site_names{j});
    %     ylabel('Elevation Residual (m)')
    %     xlim([datetime(2018,06,01) datetime(2024,01,01)])
    %     ylim([-1 1])
    %     hold off
    % end
    % legend( 'ICESat-2 median snow free elevation residuals','zero line')
    % sgtitle(Coreg_type{k});
end
%%
% fig = figure(10); clf
% for j = 1:length(site_abbrevs)
%     snotel_temp = snotel{j};
%     snoteldepth = table(snotel_temp.Date, snotel_temp.SNWD_I_1_in_ ,'VariableNames',["time","SnowDepth"]);
%     snoteldepth_dategroup = varfun(@(x)nanmean(x),snoteldepth,'GroupingVariables',{'time'});
% 
%     subplot(4,1,j); hold on
%     plot(snoteldepth_dategroup.time,snoteldepth_dategroup.Fun_SnowDepth, 'LineWidth',2)
% 
%     for k = 1:length(Coreg_type)
%         df_on_temp = df_on{j,k};
%         df_off_temp = df_off{j,k};
%         snotel_temp = snotel{j};
% 
%         snowdepth = table([datetime(df_on_temp.time.Year,df_on_temp.time.Month,df_on_temp.time.Day)], df_on_temp.elev_residuals_vertcoreg, 'VariableNames',["time","residuals"]);
%         snowdepth_dategroup = varfun(@(x)median(x,'omitnan'),snowdepth,'GroupingVariables',{'time'});
%         elevresiduals = table([datetime(df_off_temp.time.Year,df_off_temp.time.Month,df_off_temp.time.Day)], df_off_temp.elev_residuals_vertcoreg, 'VariableNames',["time","residuals"]);
%         elevresiduals_dategroup = varfun(@(x)median(x,'omitnan'),elevresiduals,'GroupingVariables',{'time'});
% 
%         scatter(snowdepth_dategroup.time,snowdepth_dategroup.Fun_residuals,75,'filled')
%         title(site_names{j});
%         set(gca,'fontsize',20);
%     end
%     hold off
% end
% legend('AWS mean snow depth','no coreg', 'agg', 'bytrack')

%% Snow Depth Error Plots
for k = 2
    figure(11); clf;
    figure(13); clf;
    plot([0,3], [0,3],'--k','LineWidth',2)
    figure(14); clf;
    plot([0,3], [0,3],'--k','LineWidth',2)
    for j = 1:length(site_abbrevs)
        df_on_temp = df_on{j,k};
        df_off_temp = df_off{j,k};
        snotel_temp = snotel{j};
        df_window_on_temp = df_window_on{j,k};
        clear snowdepth snowdepth_dategroup snowdepth_window snowdepth_window_dategroup elevresiduals elevresiduals_dategroup snoteldepth snoteldepth_dategroup snoteldepth_dategroup_IS2_dates snowdepth_error

        snowdepth = table([datetime(df_on_temp.time.Year,df_on_temp.time.Month,df_on_temp.time.Day)], df_on_temp.elev_residuals_vertcoreg, 'VariableNames',["time","residuals"]);
        snowdepth_dategroup = varfun(@(x)median(x,'omitnan'),snowdepth,'GroupingVariables',{'time'});
        snowdepth_window = table([datetime(df_window_on_temp.time.Year,df_window_on_temp.time.Month,df_window_on_temp.time.Day)], df_window_on_temp.elev_residuals_vertcoreg, 'VariableNames',["time","residuals"]);
        snowdepth_window_dategroup = varfun(@(x)median(x,'omitnan'),snowdepth_window,'GroupingVariables',{'time'});
        elevresiduals = table([datetime(df_off_temp.time.Year,df_off_temp.time.Month,df_off_temp.time.Day)], df_off_temp.elev_residuals_vertcoreg, 'VariableNames',["time","residuals"]);
        elevresiduals_dategroup = varfun(@(x)median(x,'omitnan'),elevresiduals,'GroupingVariables',{'time'});
        snoteldepth = table(snotel_temp.Date, snotel_temp.SNWD_I_1_in_ ,'VariableNames',["time","SnowDepth"]);
        snoteldepth_dategroup = varfun(@(x)median(x,'omitnan'),snoteldepth,'GroupingVariables',{'time'});
        snoteldepth_dategroup_IS2_dates = snoteldepth_dategroup(ismember(snoteldepth_dategroup.time, elevresiduals_dategroup.time), :);
        snowdepth_error = (snowdepth_dategroup.Fun_residuals(ismember(snowdepth_dategroup.time,snoteldepth_dategroup_IS2_dates.time)) - snoteldepth_dategroup_IS2_dates.Fun_SnowDepth(ismember(snoteldepth_dategroup_IS2_dates.time,snowdepth_dategroup.time)));
        median_SD_error(j) = median(abs(snowdepth_error),'omitnan');
        rmse_SD_error(j) = (nanmean((snowdepth_error).^2)).^(0.5);
        snowdepth_window_error = (snowdepth_window_dategroup.Fun_residuals(ismember(snowdepth_window_dategroup.time,snoteldepth_dategroup_IS2_dates.time)) - snoteldepth_dategroup_IS2_dates.Fun_SnowDepth(ismember(snoteldepth_dategroup_IS2_dates.time,snowdepth_window_dategroup.time)));
        median_SD_window_error(j) = median(abs(snowdepth_window_error),'omitnan');
        rmse_SD_window_error(j) = (nanmean((snowdepth_window_error).^2)).^(0.5);

        figure(11);
        subplot(4,1,j); hold on
        scatter(snowdepth_dategroup.GroupCount(ismember(snowdepth_dategroup.time,snoteldepth_dategroup_IS2_dates.time)),snowdepth_error,100,'filled','MarkerFaceColor',site_colors(j),'Marker',site_shapes(j))
        yline(0)
        title(site_names{j});
        set(gca,'fontsize',20);
        if j == 2
            ylabel('ICESat-2 Snow Depth - AWS Snow Depth')
        end
        hold off

        figure(13);
        hold on
        scatter(snoteldepth_dategroup_IS2_dates.Fun_SnowDepth(ismember(snoteldepth_dategroup_IS2_dates.time,snowdepth_window_dategroup.time)),snowdepth_window_dategroup.Fun_residuals(ismember(snowdepth_window_dategroup.time,snoteldepth_dategroup_IS2_dates.time)), 100,'MarkerEdgeColor', site_colors(j,:),'Marker',site_shapes(j))
        hold off

        figure(14);
        hold on
        scatter(snoteldepth_dategroup_IS2_dates.Fun_SnowDepth(ismember(snoteldepth_dategroup_IS2_dates.time,snowdepth_dategroup.time)),snowdepth_dategroup.Fun_residuals(ismember(snowdepth_dategroup.time,snoteldepth_dategroup_IS2_dates.time)), 100,'filled','MarkerFaceColor',site_colors(j,:),'Marker',site_shapes(j))
        hold off
    end
     for j = 1:length(site_abbrevs)
       df_on_temp = df_on{j,k};
        df_off_temp = df_off{j,k};
        snotel_temp = snotel{j};
        df_window_on_temp = df_window_on{j,k};
        clear snowdepth snowdepth_dategroup snowdepth_window snowdepth_window_dategroup elevresiduals elevresiduals_dategroup snoteldepth snoteldepth_dategroup snoteldepth_dategroup_IS2_dates snowdepth_error

        snowdepth = table([datetime(df_on_temp.time.Year,df_on_temp.time.Month,df_on_temp.time.Day)], df_on_temp.elev_residuals_vertcoreg, 'VariableNames',["time","residuals"]);
        snowdepth_dategroup = varfun(@(x)median(x,'omitnan'),snowdepth,'GroupingVariables',{'time'});
        snowdepth_window = table([datetime(df_window_on_temp.time.Year,df_window_on_temp.time.Month,df_window_on_temp.time.Day)], df_window_on_temp.elev_residuals_vertcoreg, 'VariableNames',["time","residuals"]);
        snowdepth_window_dategroup = varfun(@(x)median(x,'omitnan'),snowdepth_window,'GroupingVariables',{'time'});
        elevresiduals = table([datetime(df_off_temp.time.Year,df_off_temp.time.Month,df_off_temp.time.Day)], df_off_temp.elev_residuals_vertcoreg, 'VariableNames',["time","residuals"]);
        elevresiduals_dategroup = varfun(@(x)median(x,'omitnan'),elevresiduals,'GroupingVariables',{'time'});
        snoteldepth = table(snotel_temp.Date, snotel_temp.SNWD_I_1_in_ ,'VariableNames',["time","SnowDepth"]);
        snoteldepth_dategroup = varfun(@(x)median(x,'omitnan'),snoteldepth,'GroupingVariables',{'time'});
        snoteldepth_dategroup_IS2_dates = snoteldepth_dategroup(ismember(snoteldepth_dategroup.time, elevresiduals_dategroup.time), :);
        snowdepth_error = (snowdepth_dategroup.Fun_residuals(ismember(snowdepth_dategroup.time,snoteldepth_dategroup_IS2_dates.time)) - snoteldepth_dategroup_IS2_dates.Fun_SnowDepth(ismember(snoteldepth_dategroup_IS2_dates.time,snowdepth_dategroup.time)));

        figure(14);
        hold on
        scatter(snoteldepth_dategroup_IS2_dates.Fun_SnowDepth(ismember(snoteldepth_dategroup_IS2_dates.time,snowdepth_window_dategroup.time)),snowdepth_window_dategroup.Fun_residuals(ismember(snowdepth_window_dategroup.time,snoteldepth_dategroup_IS2_dates.time)), 100,'MarkerFaceColor',site_colors(j,:), 'MarkerFaceAlpha', 0, 'MarkerEdgeColor',site_colors_darker(j,:),'Marker',site_shapes(j))
        hold off
    end
end
figure(11);
xlabel('# of ICESat-2 observations');

figure(13);
xlabel('Median d\_AWS (m)'); ylabel('Median d\_IS2 (m)');
set(gca,'fontsize',14,'xlim',[0,2.5],'ylim',[-1,2.5],'DataAspectRatio',[1 1 1]);
legend(['1-1 Line'; site_names],'Location','northwest')

figure(14);
xlabel('Median d\_AWS (m)'); ylabel('Median d\_IS2 (m)');
set(gca,'fontsize',14,'xlim',[0,2.5],'ylim',[-1,2.5],'DataAspectRatio',[1 1 1]);
legend(['1-1 Line'; site_names; 'within 500 m of AWS'],'Location','northwest')

%% Terrain Boxplots
figure(17); clf; hold on
for j = 1:length(site_abbrevs)
    pd = fitdist(df_off{j,k}.slope_mean,'kernel','Kernel','normal');
    fplot(@(x) pdf(pd,x),[0 55], 'Linewidth', 2,'Color', site_colors(j,:));
    set(gca,'fontsize',14,'xlim',[0 55]);
    xlabel('Slope (degrees)'); ylabel('Probability density');
end
legend(site_names);
hold off

figure(15); clf
figure(16); clf
for ii = 1:2
    % no slope correction
    slope_binedges = 1:5:55;
    tbl.slope = []; tbl.elevRes = []; tbl.group = [];
    Cat_groupSlope = []; Cat_df_off = [];
    % all sites boxplot on top of each other
    figure(16);
    subplot(1,2,ii);
    for j = 1:length(site_abbrevs)
        clear group
        bins = {num2str(slope_binedges(2))};
        for i = 3:length(slope_binedges)
            bins = [bins; {num2str(slope_binedges(i))}];
        end
        hold on
        if ii == 2
            df_off{j,k}.slope_mean = df_off{j,k}.IS2_slope_deg;
            df_on{j,k}.slope_mean = df_on{j,k}.IS2_slope_deg;

            %calc quadratic corection
            x = df_off{j,k}.slope_mean; y = df_off{j,k}.elev_residuals_vertcoreg;
            ind = isnan(x) | isnan(y); %index nans
            x(ind) = []; y(ind) = []; %remove nans
            % ix = find(x > 40); %index slopes above 40 degrees
            % x(ix) = []; y(ix) = []; %remove slopes above 40 degrees
            p = polyfit(x,y,2); % fit quadratic
            % Vertical corregistration
            df_off{j,k}.elev_residuals_vertcoreg = df_off{j,k}.elev_residuals_vertcoreg-polyval(p,df_off{j,k}.slope_mean);
        end
        groupSlope = discretize(df_off{j,k}.slope_mean,slope_binedges,'categorical',bins);
        tbl.slope = [tbl.slope; groupSlope];
        group(1:length(groupSlope),:) = j;
        tbl.elevRes = [tbl.elevRes; df_off{j,k}.elev_residuals_vertcoreg];
        tbl.group = [tbl.group; group];
        boxchart(groupSlope, df_off{j,k}.elev_residuals_vertcoreg,'BoxFaceColor',site_colors(j,:),'MarkerStyle','none');
        Cat_groupSlope = [Cat_groupSlope; groupSlope];
        Cat_df_off = [Cat_df_off; df_off{j,k}.elev_residuals_vertcoreg];
        ylim([-5,5])
        set(gca,'fontsize',14,'box','on'); drawnow;
        xlabel('Slope (degrees)','fontsize',16);
    end
    yline(0)
    legend(site_names);

    %All data boxplots
    figure(15);
    subplot(1,2,ii);
    boxchart(Cat_groupSlope, Cat_df_off,'BoxFaceColor','#ffffcc','BoxEdgeColor','k','MarkerStyle','none');
    for j = 1:length(site_abbrevs)
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
        scatter(Redidual_Medians.groupSlope, Redidual_Medians.Fun_Var2, 100, 'filled','MarkerFaceColor', site_colors(j,:),'Marker',site_shapes(j))
        % scatter(Redidual_IQR.groupSlope,(Redidual_Medians.Fun_Var2 + Redidual_IQR.Fun_Var2), 'Marker', '*','MarkerEdgeColor', site_colors(j,:))
        % scatter(Redidual_IQR.groupSlope,(Redidual_Medians.Fun_Var2 - Redidual_IQR.Fun_Var2), 'Marker', '*','MarkerEdgeColor', site_colors(j,:))
        ylim([-5,5])
        set(gca,'fontsize',14,'box','on'); drawnow;
        xlabel('Slope (degrees)','fontsize',16); ylabel('h\_residual (m)');
        clear group cat_slope_tbl
    end
    yline(0)
    legend('All Sites', 'RCEW median', 'BCS median', 'MCS median', 'DCEW median','Location','northwest');
end

%% snow depth by elevation plots
for k = 2
    figure(20); clf;
    for j = 1:length(site_abbrevs)
        clear groupElev elev_binedges bins snowdepth snowdepth_elevgroup

        df_on_temp = df_on{j,k};
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

        snowdepth = table(groupElevCat, groupElev, df_on_temp.elev_residuals_vertcoreg, 'VariableNames',["elevationCAT", "elevation","residuals"]);
        snowdepth = snowdepth(~isnan(snowdepth.residuals),:);
        snowdepth_elevgroup = varfun(@(x)median(x,'omitnan'),snowdepth,'GroupingVariables',{'elevation'});
        for i = 1:length(snowdepth_elevgroup.elevation)
            if snowdepth_elevgroup.GroupCount(i) < 30
                snowdepth.residuals(snowdepth.elevation == snowdepth_elevgroup.elevation(i)) = NaN;
            end
        end
        snowdepth_elevgroup = varfun(@(x)median(x,'omitnan'),snowdepth,'GroupingVariables',{'elevation'});

        snowdepth = snowdepth(~isnan(snowdepth.residuals),:);
        linearfit{j} = fit(snowdepth.elevation, snowdepth.residuals,'poly1');

        figure(20)
        subplot(4,3,[1 2 4 5 7 8 10 11])
        hold on
        scatter(snowdepth_elevgroup.elevation,snowdepth_elevgroup.Fun_residuals,75,'filled','MarkerFaceColor',site_colors(j,:),'Marker',site_shapes(j))
        set(gca,'fontsize',14);
        xlabel('Elevation (m)'); ylabel('February and March Median d\_IS2 (m)')
        hold off

        figure(20)
        subplot(4,3,j.*3);
        hold on
        boxchart(snowdepth.elevationCAT, snowdepth.residuals,'BoxFaceColor',site_colors(j,:),'MarkerStyle','none','WhiskerLineStyle', "none");
        set(gca,'fontsize',14);
        %xlim([categorical('1400'; '2800')])
        ylim([0 3])
        xticklabels({})
        ylabel('d\_IS2 (m)')
        title(site_names{j});
        hold off  
    end

    figure(20)
    xticklabels('auto');
    %xticklabels({'1300' , '' , '1500', '' , '1700', '' , '1900' , '' , '2100' , '' , '2300' , '' , '2500' , '' , '2700' , '' })
    xlabel('Elevation (m)');
    subplot(4,3,[1 2 4 5 7 8 10 11])
    line = lsline;
    for j = 1:length(site_abbrevs)
        line(j).Color = site_colors(5-j,:);
    end
    legend(site_names, 'Location','northwest')

    xlabel('Elevation (m)');
    
end