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
%%% Last updated: Jan 2025 by Karina Zikan

%% Inputs
clearvars; close all;
addpath('/bsuhome/karinazikan/scratch/') % path to location of reference_elevations & ICESat2_FootprintCorners functions

%DTM (be sure the path ends in a /)
DTM_path = '/bsuhome/karinazikan/scratch/RCEW/'; %path to dtm, slope, & aspect maps
DTM_name = 'RCEW_1m_WGS84UTM11_WGS84.tif';
if contains(DTM_name,'.tif')
    DTM_date = '20120826'; %only need to change this if the DTM is a geotiff
end
% Slope
DTM_slope = 'RCEW_1m_WGS84UTM11_WGS84-slope.tif';
% Aspect
DTM_aspect = 'RCEW_1m_WGS84UTM11_WGS84-aspect.tif';

%csv (be sure the path ends in a /)
csv_path = '/bsuhome/karinazikan/scratch/RCEW/A6-40/'; %Path to ICESat-2 data with snow cover classification
csv_name = 'RCEW-ICESat2-A6-40-SnowCover.csv';

%site abbreviation for file names
abbrev = 'RCEW';

%ICESat-2 product acronym
acronym = 'A6-40'; %for custom ATL06 with ATL08 classification set to A6-20 for 20m, A6-40 for 40m, 'A6-30' for 30m

%Set output name - MAKE SURE FILENAME SUFIX IS CORRECT!!!!!!!!!!!!!!!!!!!
% file name formats: '-ref-elevations-grid-grad-decent'
%                    '-atl08class-ref-elevations-grid-grad-decent'
%                    '-20m-ref-elevations-grid-grad-decent'
%                    '-atl08class-20m-ref-elevations-grid-grad-decent'
filename_sufix = 'A6-40-ref-elevations-grid-search-fineGS-agg';

% Corse Grid search offset (from corse coregistration)
Arow = 1;
Acol = 2;

%% Set output name
outputname = [abbrev,'-ICESat2-', filename_sufix, '.csv'];

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
footwidth = 11; 


%days of year
modays_norm = [31 28 31 30 31 30 31 31 30 31 30 31];
cumdays_norm = cumsum(modays_norm); cumdays_norm = [0 cumdays_norm(1:11)];
modays_leap = [31 29 31 30 31 30 31 31 30 31 30 31];
cumdays_leap = cumsum(modays_leap); cumdays_leap = [0 cumdays_leap(1:11)];

%read in the snow-off reference elevation map
cd_to_DTM = ['cd ',DTM_path]; eval(cd_to_DTM);
if contains(DTM_name,'.tif')
    [DTM,Ref] = readgeoraster(DTM_name);
    DEMdate = DTM_date;
elseif contains(DTM_name,'.mat')
    load_DTM = ['load ',DTM_name]; eval(load_DTM);
    for i = 1:length(Z)
        DEMdate(i) = Z(i).deciyear;
    end
end
slope = readgeoraster(DTM_slope);
aspect = readgeoraster(DTM_aspect);

%identify the ICESat-2 data csv files
cd_to_csv = ['cd ',csv_path]; eval(cd_to_csv);

%filter R2erence DTM elevations
elevations = DTM;
elevations(elevations < -10) = nan; % throw out trash data
elevations(elevations > 10000) = nan; % more trash takeout

%load the ICESat-2 data
T = table; %create a table
icesat2 = [csv_path,csv_name]; %compile the file name
file = readtable(icesat2); %read in files
T = [T; file];
%T = T(1:5000,:); % ONLY FOR TESTING!!!!!!!!!!

zmod = T.h_mean(:); % save the median 'model' elevations (icesat-2 elevations)
% zmodfit = T.Elevation_bestfit(:); % save the fitted 'model' elevations (icesat-2 elevations_bestfit)
% zmodfit(isnan(zmod)) = NaN;
zstd = T.h_sigma; %save the standard deviation of the icesat-2 elevation estimates
easts = T.Easting(:); % pull out the easting values
norths = T.Northing(:); % pull out the northings
footwidth = 11; % approx. width of icesat2 shot footprint in meters

%% Snow free data
ix_off = find(T.snowcover == 0);

%identify the ends of each transect and flag them so that neighboring
%transects aren't used when constructing footprints (use beam variable & date)
dates = datetime(T.time.Year,T.time.Month,T.time.Day);
[~,unique_refs] = unique(dates);
end_flag = zeros(size(norths,1),1);
end_flag(unique_refs) = 1; end_flag(unique_refs(unique_refs~=1)-1) = 1; end_flag(end) = 1;

dates_off = dates(ix_off,:);
[~,unique_refs] = unique(dates_off);
end_flag_off = zeros(size(norths(ix_off,:),1),1);
end_flag_off(unique_refs) = 1; end_flag_off(unique_refs(unique_refs~=1)-1) = 1; end_flag_off(end) = 1;

%reference elevation function to optimise 
GradDecentFunc = @(A)reference_elevations(zmod(ix_off,:), norths(ix_off,:), easts(ix_off,:), end_flag_off, default_length, elevations, slope, aspect, Ref, A); %create the handle to call the coregistration function

%% Grid of possible inputs to calculate initial guess
A1 = -0.9:0.1:0.9;
rmad_grid = zeros(length(A1),length(A1));

k = 1;
if k ~= 1
    rmad_grid = readmatrix([abbrev,'_rmadFineGrid.csv']);
end

tic
for i = 1:length(A1)
    tic
    for j = 1:length(A1)
        rmad_grid(i,j) = GradDecentFunc([Arow+A1(i),Acol+A1(j)]);
    end    
    fprintf('row %5.2f completed',i);
    writematrix(rmad_grid,[abbrev,'_rmadFineGrid.csv'])
    toc
end
toc


figure(2);
im = imagesc(rmad_grid); 
xticks(1:length(A1)); yticks(1:length(A1)); 
xticklabels(A1); yticklabels(A1); 
colorbar;

[row, col] = find(ismember(rmad_grid, min(rmad_grid(:))));
A1row = A1(row); A1col = A1(col);

writematrix([Arow+A1row,Acol+A1col],[abbrev,'_Ashift.csv'])

% Test Gradient Decent from grid guess
 tic
 % GradDecentFunc = @(A)reference_elevations(zmod(ix_off,:), norths(ix_off,:), easts(ix_off,:), end_flag_off, default_length, elevations, slope, aspect, Ref, A); %create the handle to call the coregistration function
 % [Agrid_best,RMADgrid_best] = fminsearch(GradDecentFunc,[Arow,Acol],optimset('PlotFcns',@optimplotfval)); %initial horizontal offset estimate = [0,0] = [0 m East, 0 m North]
 fprintf('x-offset = %5.2f m & y-offset = %5.2f m w/ RNMAD = %5.2f m \n',Arow+A1row,Acol+A1col,min(rmad_grid(:)));
 fprintf('Old RNMAD = %5.2f', rmad_grid(10,10));
 toc

%% Calculate corregistered reference elevations
[~,E] = reference_elevations(zmod, norths, easts, end_flag, default_length, elevations, slope, aspect, Ref, [Arow+A1row,Acol+A1col]); %calculate ref elevations with the shift
    
%% save ref elevation csv
writetable(E,outputname);