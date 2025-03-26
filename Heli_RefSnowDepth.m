%%% SPECIFIED INPUTS:
%%%     SD_path = path to the HeliPod Snow Depth maps on your computer
%%%     csv_path = path to the ICESat-2 datafiles on your computer
%%%     csv_name = name of ICESat-2 csv file
%%%     abbrev = site abriviation for file name
%%%     acronym = ICESat-2 product acronym
%%% OUTPUTS:
%%%     E = csv datatable reporting ICESat-2 snow depths with reference
%%%     snow depths calculated from MCS Heli snow depth surveys 
%%%
%%% Last updated: Feb 2025 by Karina Zikan


%% Inputs
clearvars; close all;
addpath('./functions')

%DTM (be sure the path ends in a /)
SD_path = '/Users/karinazikan/Documents/ICESat2-AlpineSnow/Sites/MCS/Heli_SnowDepth/';


%ICESat-2 csv (be sure the path ends in a /)
csv_path = '/Users/karinazikan/Documents/ICESat2-AlpineSnow/Sites/MCS/IS2_Data/A6-40/';


%site abbreviation for file names
abbrev = 'MCS';

%ICESat-2 product acronym
acronym = 'ATL06'; %set to ATL06-20 for the 20m atl06 data

%Set output name - MAKE SURE FILENAME SUFIX IS CORRECT!!!!!!!!!!!!!!!!!!!
% file name formats: '-ref-elevations-grid-grad-decent'
% '-atl08class-ref-elevations-grid-grad-decent'
% '-20m-ref-elevations-grid-grad-decent'
% '-atl08class-20m-ref-elevations-grid-grad-decent'


%set coregistration type
bytrack = 2; % 1 = bytrack, 0 = agg, 2 = noCoreg

if bytrack == 0
    filename_sufix = '-heli-snow-depth-FineGS-agg';
    csv_name = 'ATL06-A6-40-AllData-fineGS-agg.csv';
elseif bytrack == 1
    filename_sufix = '-heli-snow-depth-FineGS-ByTrack';
    csv_name = 'ATL06-A6-40-AllData-fineGS-ByTrack.csv';
elseif bytrack == 2
    filename_sufix = '-heli-snow-depth-grid-search-noCoreg';
    csv_name = 'ATL06-A6-40-AllData-noCoreg.csv';
end

Ashift_bytrack = readmatrix('/Users/karinazikan/Documents/ICESat2-AlpineSnow/Sites/MCS/IS2_Data/A6-40/MCS_A6-40-ByTrack-fineGS-Ashift.csv'); %bytrack shifts
Agg_ashift = [0.8,-0.1]; %agg shift


%% Set output name
outputname = ['/Users/karinazikan/Documents/ICESat2-AlpineSnow/Sites/MCS/IS2_Data/A6-40/', abbrev, filename_sufix, '.csv'];

%% Read in files
% Set default_length
if acronym == 'ATL08'
    default_length = 100;
elseif acronym == 'ATL06'
    default_length = 40;
elseif acronym == 'ATL06-20'
    default_length = 20;
else
    error('acronym must be ATL06 or ATL06-20 or ATL08')
end

%days of year
modays_norm = [31 28 31 30 31 30 31 31 30 31 30 31];
cumdays_norm = cumsum(modays_norm); cumdays_norm = [0 cumdays_norm(1:11)];
modays_leap = [31 29 31 30 31 30 31 31 30 31 30 31];
cumdays_leap = cumsum(modays_leap); cumdays_leap = [0 cumdays_leap(1:11)];

%load the ICESat-2 data
T_all = table; %create a table
icesat2 = [csv_path,csv_name]; %compile the file name
file = readtable(icesat2); %read in files
T_all = [T_all ; file];
dates = datetime(T_all.time.Year,T_all.time.Month,T_all.time.Day);
%T = T(1:5000,:); % ONLY FOR TESTING!!!!!!!!!!

%read in the snow-off reference elevation map
Heli_files = dir(strcat(SD_path, '*.tif'));
E = [];

for j = 1:length(Heli_files)
    [SD,Ref] = readgeoraster(strcat(Heli_files(1).folder, '/', Heli_files(j).name));
    sz = size(SD);
    slope = NaN(sz);
    aspect = NaN(sz);

    date = datetime(str2num(Heli_files(j).name(5:12)),'ConvertFrom', 'yyyymmdd');
    disp(string(date))
    ix = find(dates < date + days(3) & dates > date - days(3));
    if bytrack == 1 %define ashift based on agg or bytrack coreg shifts
        Ashift_date = datetime(Ashift_bytrack(:,1),'ConvertFrom', 'yyyymmdd');
        ix_ashift = find(Ashift_date < date + days(3) & Ashift_date > date - days(3));
        if length(ix_ashift) > 1
            ix_ashift = find(Ashift_date < date + days(2) & Ashift_date > date - days(2));
            if length(ix_ashift) > 1
                ix_ashift = find(Ashift_date < date + days(1) & Ashift_date > date - days(1));
            end
        end

        Ashift = [Ashift_bytrack(ix_ashift,2),Ashift_bytrack(ix_ashift,3)];
        % if isnan(Ashift(1,1)) == 1
        %     Ashift = [0,0];
        % end
        testAhift{j} = Ashift;
    else
        Ashift = Agg_ashift; %agg shift
    end

    if isempty(ix)
    else

        T = T_all(ix,:);

        %filter R2erence DTM elevations
        elevations = SD;
        elevations(elevations < -10) = nan; % throw out trash data
        elevations(elevations > 10000) = nan; % more trash takeout

        %% ICESat-2 variables
        if acronym == 'ATL06'| acronym == 'ATL06-20'
            zmod = T.h_mean(:); % save the median 'model' elevations (icesat-2 elevations)
            zstd = T.h_sigma; %save the standard deviation of the icesat-2 elevation estimates
        elseif acronym == 'ATL08'
            zmod = T.Elevation(:); % save the median 'model' elevations (icesat-2 elevations)
            zstd = T.std; %save the standard deviation of the icesat-2 elevation estimates
        else
            error('Error: the variable acronym must be ATL06, ATL06-20, or ATL08. Set acronym in the inputs')
        end
        easts = T.Easting(:); % pull out the easting values
        norths = T.Northing(:); % pull out the northings
        footwidth = 11; % approx. width of icesat2 shot footprint in meters

     
        %% Snow free data
        %identify the ends of each transect and flag them so that neighboring
        %transects aren't used when constructing footprints (use beam variable & date)
        dates_temp = datetime(T.time.Year,T.time.Month,T.time.Day);
        [~,unique_refs] = unique(dates_temp);
        end_flag = zeros(size(norths,1),1);
        end_flag(unique_refs) = 1; end_flag(unique_refs(unique_refs~=1)-1) = 1; end_flag(end) = 1;

        %% Calculate corregistered reference elevations
        tic
        [~,E_temp] = reference_elevations(zmod, norths, easts, end_flag, default_length, elevations, slope, aspect, Ref, Ashift); %calculate ref elevations with the shift
        toc
        T.snowdepth = E_temp.elevation_report_nw_mean;
        test{j} = T.snowdepth;
        E = [E; T];
    end
end

%% save refelevation csv
writetable(E,outputname);
