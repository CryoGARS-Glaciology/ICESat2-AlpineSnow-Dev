%%% This code was writen by Karina Zikan to calculate the elevation
%%% residuals and compile all the data into one master array
%%%
%%% SPECIFIED INPUTS:
%%%     icesat2 = path to ICESat-2 file (output from batch_icesat2_terrain_parameter_comparison.m)
%%%     ref_elevations = path to reference elevations file (output from DTM_reference_elevations_calculation.m)
%%%     abbrev = site abriviation for file name
%%%     outputname = output file name
%%%
%%% OUTPUTS:
%%%     File = data file with all the data and calcualted residuals
%%%
%%% Last updated: Feb 2025 by Karina Zikan

%% Inputs
clearvars;

%Folder path
folderpath = '/Users/karinazikan/Documents/ICESat2-AlpineSnow/Sites/';
%site abbreviation for file names
abbrev = 'RCEW';

% Grouping type:
% 'fineGS-agg' - 0
% 'fineGS-ByTrack' - 1
% 'noCoreg' - 2
% 'Agg_acc' - 3
% 'Agg_dec' - 4
% 'gradDecent' - 5
Grouping = 1;


%set footprint length
% footprint = 40;

%% File paths
if Grouping == 0
    Group = 'fineGS-agg'
elseif Grouping == 1
    Group = 'fineGS-ByTrack'
elseif Grouping == 2
    Group = 'noCoreg'
elseif Grouping == 3
    Group = 'Agg-acc'
elseif Grouping == 4
    Group = 'Agg-dec'
elseif Grouping == 5
    Group = 'gradDecent'
end

icesat2 = [folderpath abbrev '/IS2_Data/A6-40/' abbrev '-ICESat2-A6-40-SnowCover'];
ref_elevations = [folderpath abbrev '/IS2_Data/A6-40/' abbrev '-ICESat2-A6-40-ref-elevations-grid-search-' Group];

%output file name
outputname = ['ATL06-A6-40-AllData-' Group];

%% Load data
%load the reference elevation data
E = readtable(ref_elevations);

%load the ICESat-2 data
I = readtable(icesat2);

%% Make arrays the same length
I_dates = datetime(I.time.Year,I.time.Month,I.time.Day);

if Grouping == 1
    %bytrack coreg table
    ByTrack_shift_path = [folderpath abbrev '/IS2_Data/A6-40/' abbrev '_A6-40-ByTrack-fineGS-Ashift'];
    ByTrack_shifts = readtable(ByTrack_shift_path);
    %filter by dates
    E_dates = datetime(ByTrack_shifts.Var1,'ConvertFrom','yyyymmdd');
    ix = ismember(I_dates,E_dates);
    I = I(ix,:);
elseif Grouping == 3
    %dates array
    path = [folderpath 'IS2_Data/A6-40/' abbrev '_A6-40dates-acc'];
    E_dates = readtable(path);
    %filter by dates
    E_dates = datetime(E_dates,'ConvertFrom','yyyymmdd');
    ix = ismember(I_dates,E_dates);
    I = I(ix,:);
elseif Grouping == 4
    %dates array
    path = [folderpath 'IS2_Data/A6-40/' abbrev '_A6-40dates-dec'];
    E_dates = readtable(path);
    %filter by dates
    E_dates = datetime(E_dates,'ConvertFrom','yyyymmdd');
    ix = ismember(I_dates,E_dates);
    I = I(ix,:);
else
end

%% Make snow-off array
ix = find(I.snowcover == 0);
I_off = I(ix,:);
E_off = E(ix,:);


%% Calculate residuals w/ and w/out vertical cogregistration
Residuals_off =  I_off.h_mean - E_off.elevation_report_nw_mean;
Residuals =  I.h_mean - E.elevation_report_nw_mean;

%remove extreme outliers
Residuals_off(Residuals_off > 80) = NaN; Residuals_off(Residuals_off < -80) = NaN;
Residuals(Residuals > 80) = NaN; Residuals(Residuals < -80) = NaN;

%Calculate ICESat-2 along track slope
IS2_slope = abs(atand(I.dh_fit_dx));

%calculate quadratic slope correction w/ dtm slope
slope = E_off.slope_mean;
x= slope; y = Residuals(ix);
ind = isnan(x) | isnan(y); %index nans
x(ind) = []; y(ind) = []; %remove nans
p = polyfit(x,y,2); % fit quadratic
% Vertical corregistration
elev_residuals_dtm_slopecorrected = Residuals-polyval(p,E.slope_mean);
elev_residuals_dtm_slopecorrected_off = elev_residuals_dtm_slopecorrected(ix);

%calculate quadratic slope correction w/ IS2 slope
slope = IS2_slope(ix);
x= slope; y = Residuals(ix);
ind = isnan(x) | isnan(y); %index nans
x(ind) = []; y(ind) = []; %remove nans
p = polyfit(x,y,2); % fit quadratic
% Vertical corregistration
elev_residuals_is2_slopecorrected = Residuals-polyval(p,IS2_slope);
elev_residuals_is2_slopecorrected_off = elev_residuals_is2_slopecorrected(ix);

% shift by median snow-off residual to vertically coregister residuals
Residuals_VertCoreg = Residuals - median(Residuals_off,'omitnan');
elev_residuals_vertcoreg_dtm_slopecorrected = elev_residuals_dtm_slopecorrected - median(elev_residuals_dtm_slopecorrected_off,'omitnan');
elev_residuals_vertcoreg_is2_slopecorrected = elev_residuals_is2_slopecorrected - median(elev_residuals_is2_slopecorrected_off,'omitnan');

%% Combine all data into one file
Output = [I E];
Output.elev_residuals = Residuals;
Output.elev_residuals_vertcoreg = Residuals_VertCoreg;
Output.elev_residuals_vertcoreg_dtm_slopecorrected = elev_residuals_vertcoreg_dtm_slopecorrected;
Output.elev_residuals_vertcoreg_is2_slopecorrected = elev_residuals_vertcoreg_is2_slopecorrected;
Output.IS2_slope_deg = IS2_slope;

Output_off = Output(Output.snowcover == 0,:);
Output_on = Output(Output.snowcover == 1,:);

%% Write output file
writetable(Output,[folderpath abbrev '/IS2_Data/A6-40/' outputname '.csv']);
writetable(Output_off,[folderpath abbrev '/IS2_Data/A6-40/' outputname '_off.csv']);
writetable(Output_on,[folderpath abbrev '/IS2_Data/A6-40/' outputname '_on.csv']);
