%% SPECIFIED INPUTS:
%%%     DTM_path = path to the reference DTM on your computer
%%%     DTM_name = DTM file name
%%%     DTM_slope = Slope map file name
%%%     DTM_aspect = Aspect map file name
%%%     csv_path = path to the ICESat-2 datafiles on your computer
%%%     csv_name = name of ICESat-2 csv file
%%%     abbrev = site abriviation for file name
%%%     acronym = ICESat-2 product acronym
%%% OUTPUTS:
%%%     Reference_Elevations = csv datatable reporting the non-weighted
%%%         mean, std, weighted mean, and fitted refference elevations,
%%%         mean slope, std slope, mean aspect, std aspect
%%%
%%%
%%% Last updated: Sept 2024 by Karina Zikan & Ellyn Enderlin

%% Inputs
clearvars; close all;
addpath('/bsuhome/karinazikan/scratch/')

%DTM (be sure the path ends in a /)
DTM_path = '/bsuhome/karinazikan/scratch/MCS/';
DTM_name = 'MCS_REFDEM_WGS84.tif';
if contains(DTM_name,'.tif')
    DTM_date = '20120826'; %only need to change this if the DTM is a geotiff
end
% Slope
DTM_slope = 'MCS_REFDEM_WGS84-slope.tif';
% Aspect
DTM_aspect = 'MCS_REFDEM_WGS84-aspect.tif';

%csv (be sure the path ends in a /)
% csv_path = '/Users/alexiturriria/ICESat2-AlpineSnow/Sites/DCEW_2shape/IS2_Data/';
csv_path = '/bsuhome/karinazikan/scratch/MCS/A6-40/';
csv_name = 'MCS-ICESat2-A6-40-SnowCover.csv';

%site abbreviation for file names
abbrev = 'MCS';

%ICESat-2 product acronym
acronym = 'A6-40'; %for custom ATL06 with ATL08 classification set to A6-20 for 20m, A6-40 for 40m, 'A6-30' for 30m

%Set output name - MAKE SURE FILENAME SUFIX IS CORRECT!!!!!!!!!!!!!!!!!!!
% file name formats: '-ref-elevations-grid-grad-decent'
%                    '-atl08class-ref-elevations-grid-grad-decent'
%                    '-20m-ref-elevations-grid-grad-decent'
%                    '-atl08class-20m-ref-elevations-grid-grad-decent'
filename_sufix = '-ref-elevations-grid-search-Agg';

%% Set output name
outputname = [abbrev,'-ICESat2-',acronym, filename_sufix, '.csv'];
outputname_acc = [abbrev,'-ICESat2-',acronym, filename_sufix, '-acc.csv'];
outputname_dec = [abbrev,'-ICESat2-',acronym, filename_sufix, '-dec.csv'];

%% Read in files
% Set default_length
if acronym == 'ATL08'
    default_length = 100;
elseif acronym == 'ATL06'
    default_length = 40;
elseif acronym == 'A6-40'
    default_length = 40;
elseif acronym == 'A6-20'
    default_length = 20;
elseif acronym == 'A6-30'
    default_length = 30;
else
    error('acronym must be ATL06 or or A6-40 or A6-20 or ATL08')
end
footwidth = 11; % approx. width of icesat2 shot footprint in meters

%days of year
modays_norm = [31 28 31 30 31 30 31 31 30 31 30 31];
cumdays_norm = cumsum(modays_norm); cumdays_norm = [0 cumdays_norm(1:11)];
modays_leap = [31 29 31 30 31 30 31 31 30 31 30 31];
cumdays_leap = cumsum(modays_leap); cumdays_leap = [0 cumdays_leap(1:11)];

%read in the snow-off reference elevation map
cd(DTM_path);
if contains(DTM_name,'.tif')
    [DTM,Ref] = readgeoraster(DTM_name);
    DEMdate = DTM_date;
elseif contains(DTM_name,'.mat')
    load(DTM_name);
    for i = 1:length(Z)
        DEMdate(i) = Z(i).deciyear;
    end
end
slope = readgeoraster(DTM_slope);
aspect = readgeoraster(DTM_aspect);

%identify the ICESat-2 data csv files
cd(csv_path);

%filter R2erence DTM elevations
elevations = DTM;
elevations(elevations < -10) = nan; % throw out trash data
elevations(elevations > 10000) = nan; % more trash takeout

%load the ICESat-2 data
T = table; %create a table
icesat2 = [csv_path,csv_name]; %compile the file name
file = readtable(icesat2); %read in files
T = [T; file];

%extract data from columns
zmod = T.h_mean(:); % save the median 'model' elevations (icesat-2 elevations)
zstd = T.h_sigma; %save the standard deviation of the icesat-2 elevation estimates
easts = T.Easting(:); % pull out the easting values
norths = T.Northing(:); % pull out the northings
tracks = T.spot(:); % pull out the beam (1-6)

%identify the ends of each transect and flag them so that neighboring
%transects aren't used when constructing footprints (use beam variable & date)
dates = datetime(T.time.Year,T.time.Month,T.time.Day);
[unique_dates,unique_refs] = unique(dates);
end_flag = zeros(size(norths,1),1);
end_flag(unique_refs) = 1; end_flag(unique_refs(unique_refs~=1)-1) = 1; end_flag(end) = 1;

%filter the data to remove any single-footprint tracks & resave the csv
for k = 1:length(unique_dates)
    ix = find(dates == unique_dates(k));
    if length(ix) == 1
        zmod(ix) = []; zstd(ix) = []; easts(ix) = []; norths(ix) = [];
        tracks(ix) = []; dates(ix) = []; end_flag(ix) = [];
        T(ix,:) = [];
    end
end
%resave icesat2
writetable(T,icesat2);
%find edited unique dates
clear unique_*;
[unique_dates,~] = unique(dates);

%% Snow free data
ix_off = find(T.snowcover == 0);
zmod_off = zmod(ix_off,:);
norths_off = norths(ix_off,:);
easts_off = easts(ix_off,:);
tracks_off = tracks(ix_off,:);

%identify dates and if each footprint is at the end of a track
dates_off = dates(ix_off,:);
[unique_dates_off,unique_refs] = unique(dates_off);
end_flag_off = zeros(size(norths(ix_off,:),1),1);
end_flag_off(unique_refs) = 1; end_flag_off(unique_refs(unique_refs~=1)-1) = 1; end_flag_off(end) = 1;

%% Aggreidated snow off corregistation
disp('Aggregated Coregistration:')
%make dummy matrices to hold concatenated variables
End_E = []; Adate = []; Arow = []; Acol = []; Adir = [];


% if date has snow free data coregister data and calcualte reference elevations

% create the grid search function
GridSearchFunc = @(A)reference_elevations(zmod_off, norths_off, easts_off, end_flag_off, default_length, elevations, slope, aspect, Ref, A); %create the handle to call the coregistration function

%set up the grid size
A1 = -8:8;
%run the grid search
tic
for i = 1:length(A1)
    for j = 1:length(A1)
        fprintf('running cell [ %5.2f , %5.2f ] \n', i, j);
        rmad_grid(i,j) = GridSearchFunc([A1(i),A1(j)]);
    end
    writematrix(rmad_grid,[abbrev,'_',acronym,'_rmadGrid.csv'])
end
toc

%save the best coregistration shifts to file
[row, col] = find(ismember(rmad_grid, min(rmad_grid(:))));
writematrix([A1(row),A1(col)],[abbrev,'_',acronym,'-Agg-Ashift.csv']);

% print old and new RMAD
fprintf('x-offset = %5.2f m & y-offset = %5.2f m w/ RNMAD = %5.2f m \n',A1(row),A1(col),min(rmad_grid(:)));
fprintf('Old RNMAD = %5.2f \n', rmad_grid(9,9));

% Calculate corregistered reference elevations
[~,E] = reference_elevations(zmod, norths, easts, end_flag, default_length, elevations, slope, aspect, Ref, [A1(row),A1(col)]); %calculate ref elevations with the shift
End_E = [End_E; E]; clear E;

% save refelevation csv
writetable(End_E,outputname);



























