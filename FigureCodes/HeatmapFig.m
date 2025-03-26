%%% Make heatmap figure
%%%
%%% SPECIFIED INPUTS: 
%%%     folderpath = path to ICESat-2 datafiles
%%%     abbrev = site name abrivation 
%%%
%%% OUTPUTS:
%%%     Heatmap figures jpegs
%%%
%%% Last updated: Nov 2023 by Karina Zikan

%% Inputs
clearvars;
addpath(['/Users/karinazikan/Documents/functions'])
addpath(['/Users/karinazikan/Documents/cmocean'])


%site abbreviation for file names
abbrev = 'Banner';
%Folder path
folderpath = ['/Users/karinazikan/Documents/ICESat2-AlpineSnow/Sites/' abbrev '/'];

%Turn slope correction off or on
slope_correction = 1; % 0 = off, 1 = on

numbins = 20;

%% Load data
filepath = [folderpath 'IS2_Data/A6-40/ATL06-A6-40-AllData-fineGS-agg.csv'];
df = readtable(filepath);

%% Grouped data plot - elevations

% ATL06 classified
SnowDepthAll =  df.elev_residuals_vertcoreg;
SnowDepthAll(SnowDepthAll > 80) = NaN; SnowDepthAll(SnowDepthAll < -80) = NaN; %remove extreme outliers
%filter out extreme slopes
% SnowDepthAll(df.slope_mean > 30) = NaN; 

if slope_correction == 1
    ix_off = find(df.snowcover == 0);
    df_off = df(ix_off,:);

    %calculate quadratic slope correction
    slope = df_off.slope_mean;
    x= slope; y = df_off.elev_residuals_vertcoreg;
    ind = isnan(x) | isnan(y); %index nans
    x(ind) = []; y(ind) = []; %remove nans
    p = polyfit(x,y,2); % fit quadratic
    % Vertical corregistration
    SnowDepthAll = SnowDepthAll-polyval(p,df.slope_mean);
    SnowDepthAll = SnowDepthAll - median(SnowDepthAll(ix_off),'omitnan');
    ('Slope correction applied')
end

df.elevation_report_nw_mean(isnan(SnowDepthAll)) = NaN;
% group elevation
figure(1);
h = histogram(df.elevation_report_nw_mean,numbins);
elev_binwidth = h.BinWidth; elev_binedges = h.BinEdges;
clear h;
for i = 2:length(elev_binedges)
    bins{i-1} = num2str(elev_binedges(i));
end
groupElev = discretize(df.elevation_report_nw_mean, elev_binedges,'categorical',bins);

% group aspect
figure(2);
h = histogram(df.aspect_mean,numbins);
aspect_binwidth = h.BinWidth; aspect_binedges = h.BinEdges;
clear h;
for i = 2:length(aspect_binedges)
    bins{i-1} = num2str(aspect_binedges(i));
end
groupAspect = discretize(df.aspect_mean, aspect_binedges,'categorical',bins);

% group slope
figure(3);
h = histogram(df.slope_mean,numbins);
slope_binwidth = h.BinWidth; slope_binedges = h.BinEdges;
clear h;
for i = 2:length(slope_binedges)
    bins{i-1} = num2str(slope_binedges(i));
end
groupSlope = discretize(df.slope_mean, slope_binedges,'categorical',bins);

% Make table that can be grouped by various parameters
SnowDepthTable(:,1) = table([datetime(df.time.Year,df.time.Month,df.time.Day)]); %Date
SnowDepthTable(:,2) = table(groupElev);  %binned elevations
SnowDepthTable(:,3) = table(groupAspect);  %binned aspects
SnowDepthTable(:,4) = table(groupSlope);  %binned slopes
SnowDepthTable(:,5) = table(SnowDepthAll); %ATL06_class Snow Depth
SnowDepthTable(:,6) = table(df.snowcover); %ATL06_class Snow Depth
SnowDepthTable = renamevars(SnowDepthTable,["Var1","Var2","Var3","Var4","Var5","Var6"],["Date","Elevation","Aspect","Slope","ATL06_classSnowDepth","SnowCover"]);

% Average snow depth by paramaters and date
SnowDepthMedTable_elev = varfun(@(x)median(x,'omitnan'),SnowDepthTable,'GroupingVariables',{'Date','Elevation'});
SnowDepthMedTable_aspect = varfun(@(x)median(x,'omitnan'),SnowDepthTable,'GroupingVariables',{'Date','Aspect'});
SnowDepthMedTable_slope = varfun(@(x)median(x,'omitnan'),SnowDepthTable,'GroupingVariables',{'Date','Slope'});
SnowDepthMedTable_date = varfun(@(x)median(x,'omitnan'),SnowDepthTable,'InputVariables','ATL06_classSnowDepth','GroupingVariables','Date');
% stdT = varfun(@std,SnowDepthTable,'GroupingVariables',{'Date','Elevation'});
% SnowDepthMedTable(:,5) = stdT(:,4);
% SnowDepthMedTable = renamevars(SnowDepthMedTable,["Fun_ATL06_classSnowDepth","Var5"],["median","std"]);
dates = unique(SnowDepthMedTable_elev.Date);
% make date array with empty months inbetween
dates_array = dates(1):calmonths(1):dates(2);
for i = 2:(length(dates)-1)
    dates_array = [dates_array,dates(i):calmonths(1):dates(i+1)];
end
dates_array = [dates_array, dates(length(dates))];
dates_array = dates_array';

% Make grouped snow depths arrays
for k = 1:length(dates_array)
    if ismember(dates_array(k),dates) == 0
        SnowDepthMedArray_elev(k,(1:numbins)) = NaN;
        SnowDepthMedArray_aspect(k,(1:numbins)) = NaN;
        SnowDepthMedArray_slope(k,(1:numbins)) = NaN;
    else
        for i = 2:length(elev_binedges)
            % elevation
            ix = SnowDepthMedTable_elev.Date == dates_array(k); %index by date
            T = SnowDepthMedTable_elev(ix,:);
            if sum(ismember(num2str(elev_binedges(i)),T.Elevation)) ~= 0
                ix = find(T.Elevation == num2str(elev_binedges(i))); %index by elevation
                SnowDepthMedian = T.Fun_ATL06_classSnowDepth(ix,:);
            else
                SnowDepthMedian = NaN;
            end
            SnowDepthMedArray_elev(k,[i-1]) = SnowDepthMedian;

            % aspect
            ix = SnowDepthMedTable_aspect.Date == dates_array(k); %index by date
            T = SnowDepthMedTable_aspect(ix,:);
            if sum(ismember(num2str(aspect_binedges(i)),T.Aspect)) ~= 0
                ix = find(T.Aspect == num2str(aspect_binedges(i))); %index by elevation
                SnowDepthMedian = T.Fun_ATL06_classSnowDepth(ix,:);
            else
                SnowDepthMedian = NaN;
            end
            SnowDepthMedArray_aspect(k,[i-1]) = SnowDepthMedian;

            % slope
            ix = SnowDepthMedTable_slope.Date == dates_array(k); %index by date
            T = SnowDepthMedTable_slope(ix,:);
            if sum(ismember(num2str(slope_binedges(i)),T.Slope)) ~= 0
                ix = find(T.Slope == num2str(slope_binedges(i))); %index by elevation
                SnowDepthMedian = T.Fun_ATL06_classSnowDepth(ix,:);
            else
                SnowDepthMedian = NaN;
            end
            SnowDepthMedArray_slope(k,[i-1]) = SnowDepthMedian;
        end
    end
end

%% Plot elevation grouped snow depths
ylabels = string(dates_array,'MM-yyyy');
ylabels(1:3:end) = NaN;
ylabels(2:3:end) = NaN;

if slope_correction == 1
    fig1 = figure(4); clf
else
    fig1 = figure(7); clf
end
datenum = convertTo(dates_array,'yyyymmdd');
imagesc(datenum,elev_binedges([2:length(elev_binedges)]),SnowDepthMedArray_elev',[-3 3])
cmap = cmocean('-balance'); cmap = [ 0 0 0 ; cmap ];
set(gca,'fontsize',18,'YDir','normal');
colormap(cmap); c = colorbar; c.Label.String = 'Elevation Residual (m)';
ylabel('Elevation (m)')
title(abbrev)
a=(max(datenum)-min(datenum))/(length(datenum)-1);
ticks = min(datenum):a:max(datenum);
xticks(ticks)
xticklabels(ylabels)

if slope_correction == 1
    fig2 = figure(5); clf
else
    fig2 = figure(8); clf
end
imagesc(datenum,aspect_binedges([2:length(aspect_binedges)]),SnowDepthMedArray_aspect',[-3 3])
cmap = cmocean('-balance'); cmap = [ 0 0 0 ; cmap ];
colormap(cmap); c = colorbar; c.Label.String = 'Elevation Residual (m)';
set(gca,'fontsize',18,'YDir','normal');
ylabel('Aspect (degrees)')
a=(max(datenum)-min(datenum))/(length(datenum)-1);
ticks = min(datenum):a:max(datenum);
xticks(ticks)
xticklabels(ylabels)

if slope_correction == 1
    fig3 = figure(6); clf
else
    fig3 = figure(9); clf
end
imagesc(datenum,slope_binedges([2:length(slope_binedges)]),SnowDepthMedArray_slope',[-3 3])
cmap = cmocean('-balance'); cmap = [ 0 0 0 ; cmap ];
colormap(cmap); c = colorbar; c.Label.String = 'Elevation Residual (m)';
set(gca,'fontsize',18,'YDir','normal');
ylabel('Slope (degrees)')
a=(max(datenum)-min(datenum))/(length(datenum)-1);
ticks = min(datenum):a:max(datenum);
xticks(ticks)
xticklabels(ylabels)

%% Save Plots
