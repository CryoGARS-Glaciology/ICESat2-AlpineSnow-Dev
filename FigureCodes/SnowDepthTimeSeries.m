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

%Folder path
folderpath = '/Users/karinazikan/Documents/ICESat2-AlpineSnow/Sites/Banner/';
%site abbreviation for file names
abbrev = 'Banner';

%Turn slope correction off or on
slope_correction = 1; % 0 = off, 1 = on

%Weather Station Location
    % Banner snotel: snotel_E = 640823; snotel_N = 4907084;
    % MCS snotel: snotel_E = 607075; snotel_N = 4865193;
    % Reynolds snowex: snotel_E = 519729; snotel_N = 4768225;
    % DCEW little deer point AWS: snotel_E = 570697; snotel_N = 4843042;
snotel_E = 640823; snotel_N = 4907084;


%% Load data
% IS2 data
filepath = [folderpath 'IS2_Data/A6-40/ATL06-A6-40-AllData-noCoreg_on.csv'];
df_on = readtable(filepath);
filepath = [folderpath 'IS2_Data/A6-40/ATL06-A6-40-AllData-noCoreg_off.csv'];
df_off = readtable(filepath);

%snotel data
snotel_files = dir([folderpath 'snotel/*.csv']);
snotel = readtable([folderpath 'snotel/' snotel_files(1).name]);
for i = 2:length(snotel_files)
    file = readtable([folderpath 'snotel/' snotel_files(i).name]);
    snotel = cat(1,snotel,file);
end
snotel.SNWD_I_1_in_ = snotel.SNWD_I_1_in_ * 0.0254; %convert from in to m
snotel.SNWD_I_1_in_(snotel.SNWD_I_1_in_ < 0) = NaN;
%% 
if slope_correction == 1
    %calculate quadratic slope correction
    slope = df_off.slope_mean;
    x= slope; y = df_off.elev_residuals_vertcoreg;
    ind = isnan(x) | isnan(y); %index nans
    x(ind) = []; y(ind) = []; %remove nans
    p = polyfit(x,y,2); % fit quadratic
    % Vertical corregistration
    df_on.elev_residuals_vertcoreg = df_on.elev_residuals_vertcoreg-polyval(p,df_on.slope_mean);
    df_off.elev_residuals_vertcoreg = df_off.elev_residuals_vertcoreg-polyval(p,df_off.slope_mean);
    ('Slope correction applied')
end

% % Filter to near snotel station
window = 500;
df_on = df_on((df_on.Easting <= (snotel_E + window) & df_on.Easting >= (snotel_E - window)),:);
df_on = df_on((df_on.Northing <= (snotel_N + window) & df_on.Northing >= (snotel_N - window)),:);
df_off = df_off((df_off.Easting <= (snotel_E + window) & df_off.Easting >= (snotel_E - window)),:);
df_off = df_off((df_off.Northing <= (snotel_N + window) & df_off.Northing >= (snotel_N - window)),:);

%% Only tracks that go through SNOTEL
% dates_on = datetime(df_on.time.Year,df_on.time.Month,df_on.time.Day);
% groups = findgroups(dates_on,df_on.gt);
% unique_tracks = unique(groups);
% for i = 1:length(unique_tracks)
%     ix = groups == unique_tracks(i);
%     df_ix = df_on(ix,:);
%     df_ix = df_ix((df_ix.Easting <= (snotel_E + window) & df_ix.Easting >= (snotel_E - window)),:);
%     df_ix = df_ix((df_ix.Northing <= (snotel_N + window) & df_ix.Northing >= (snotel_N - window)),:);
%     if isempty(df_ix) == 1
%         df_on.elev_residuals_vertcoreg(ix) = NaN;
%     else
%     end
% end

%%
snowdepth = table([datetime(df_on.time.Year,df_on.time.Month,df_on.time.Day)], df_on.elev_residuals_vertcoreg, 'VariableNames',["time","residuals"]);
snowdepth_dategroup = varfun(@(x)median(x,'omitnan'),snowdepth,'GroupingVariables',{'time'});
elevresiduals = table([datetime(df_off.time.Year,df_off.time.Month,df_off.time.Day)], df_off.elev_residuals_vertcoreg, 'VariableNames',["time","residuals"]);
elevresiduals_dategroup = varfun(@(x)median(x,'omitnan'),elevresiduals,'GroupingVariables',{'time'});
snoteldepth = table(snotel.Date, snotel.SNWD_I_1_in_ ,'VariableNames',["time","SnowDepth"]);
snoteldepth_dategroup = varfun(@(x)nanmean(x),snoteldepth,'GroupingVariables',{'time'});

%% Plots
%colors
load('/Users/karinazikan/Documents/ScientificColourMaps8/vik/DiscretePalettes/vik10.mat');

%timeseries
fig1 = figure(1); clf
plot(snoteldepth_dategroup.time,snoteldepth_dategroup.Fun_SnowDepth, 'LineWidth',2)
legend('SNOTEL mean snow depth')
set(gca,'fontsize',20);
ylabel('Snow Depth (m)') 

fig2 = figure(2); clf
plot(snoteldepth_dategroup.time,snoteldepth_dategroup.Fun_SnowDepth, 'LineWidth',2,'Color',[0.9290, 0.6940, 0.1250]	)
hold on
scatter(snowdepth_dategroup.time,snowdepth_dategroup.Fun_residuals,50,'filled','MarkerFaceColor',[0, 0.4470, 0.7410])
legend('SNOTEL mean snow depth','ICESat-2 median snow depth')
set(gca,'fontsize',20);
ylabel('Snow Depth (m)')

fig3 = figure(3); clf
plot(snoteldepth_dategroup.time,snoteldepth_dategroup.Fun_SnowDepth, 'LineWidth',2,'Color',[0.9290, 0.6940, 0.1250]	)
hold on
scatter(elevresiduals_dategroup.time,elevresiduals_dategroup.Fun_residuals,'MarkerEdgeColor',[0.8500, 0.3250, 0.0980])
scatter(snowdepth_dategroup.time,snowdepth_dategroup.Fun_residuals,'filled','MarkerFaceColor',[0, 0.4470, 0.7410])
legend('SNOTEL mean snow depth','ICESat-2 median snow free elevation residuals','ICESat-2 median snow depth')
set(gca,'fontsize',20);
ylabel('Snow Depth (m)')












































