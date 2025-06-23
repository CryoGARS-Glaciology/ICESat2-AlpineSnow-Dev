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
%colors
load('/Users/karinazikan/Documents/ScientificColourMaps8/vik/DiscretePalettes/vik10.mat');

%Folder path
folderpath = '/Users/karinazikan/Documents/ICESat2-AlpineSnow/Sites/';
%site abbreviation for file names
site_abbrevs = string({'RCEW';'Banner';'MCS';'DCEW'});
site_names = string({'Reynolds Creek';'Banner Summit';'Mores Creek';'Dry Creek'});
Coreg_type = string({'noCoreg';'Agg';'ByTrack'});

%Turn dtm or is2 slope correction
slope_correction = 0; % 0 = dtm, 1 = is2, 2 = no slope correction

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

site_colors = ["#3dd6ff";"#6494ff";"#973ed3";"#77007a"];
site_shapes = ["o";"square";"diamond";"^"];

for j = 1:length(site_names)
    %site abbreviation for file names
    abbrev = site_abbrevs(j);
    %Product abbreviation for files
    prod_abbrev = 'A6-40';
    %Folder path
    folderpath = strcat('/Users/karinazikan/Documents/ICESat2-AlpineSnow/Sites/', abbrev, '/');


    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %% Load data
    % IS2 data
    filepath = strcat(folderpath, 'IS2_Data/', prod_abbrev, '/', abbrev, '_', prod_abbrev, '-ByTrack-fineGS-Ashift.csv');
    Ashift_ByTrack = readtable(filepath);

    Ashift_Agg = {[0.3,0.1];[0.7,-0.9];[0.8,-0.1];[0.3,-0.1]}; % agg shifts for {'RCEW';'Banner';'MCS';'DCEW'}

    a = table2array(Ashift_ByTrack(:,3));
    a = -1 * a;
    Ashift_ByTrack(:,3) = array2table(a);


    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %% Figures
    %% Scatter Plot
    figure(1);
    subplot(1,4,j); cla; hold on
    % for i = 0:1 % plot scatter plot with accending & decensinding tracks seperated
    %     scatter(Ashift_ByTrack.Var2(Ashift_ByTrack.Var4 == i),Ashift_ByTrack.Var3(Ashift_ByTrack.Var4 == i),100,'filled') %, 'MarkerFaceAlpha', 0.5); 
    %     %colormap([[0 0.4470 0.7410]; [0.8500 0.3250 0.0980]]);
    %     %h = gscatter(Ashift_ByTrack.Var2, Ashift_ByTrack.Var3, Ashift_ByTrack.Var4,'br','d',10,'filled');
    % end
    scatter(Ashift_ByTrack.Var2,Ashift_ByTrack.Var3,100,'filled','MarkerFaceColor',site_colors(j,:),'Marker',site_shapes(j)); %, 'MarkerFaceAlpha', 0.5); 
    scatter(Ashift_Agg{j}(1),Ashift_Agg{j}(2),400,'pentagram','filled','MarkerFaceColor',[0.9290 0.6940 0.1250],'MarkerEdgeColor','k');
    set(gca, 'XAxisLocation', 'origin', 'YAxisLocation', 'origin','fontsize',16,'DataAspectRatio',[1 1 1])
    xlabel('East shift (m)'); ylabel("North shift (m)")
   if j == 1
   legend('Individual Coregistration Shifts','Aggregate Coregistration Shift','Location','southoutside');
   end
    axis([-10 10 -10 10])
    title(site_names{j});
    hold off
    

    %'30-Jan-2019''26-Aug-2019''28-Aug-2019''29-Oct-2019''26-Jan-2020''23-Feb-2020''26-Feb-2020'
    %'28-Apr-2020''24-May-2020''26-Aug-2020''22-Nov-2020''21-Dec-2020''21-Feb-2021''23-Feb-2021''24-Aug-2021'
    %'22-Sep-2021''23-Nov-2021''19-Feb-2022''22-Feb-2022''20-Mar-2022''22-Mar-2022''24-Apr-2022'
    %'21-May-2022''25-Jun-2022''22-Jul-2022''24-Jul-2022''20-Aug-2022''21-Oct-2022'
    %'23-Oct-2022''18-Nov-2022''21-Nov-2022''25-Mar-2023''20-Apr-2023''23-Apr-2023''19-May-2023'

    %ix = [2 7 8 9 11 12 13 14 15 16 19 20 22 23 28 30 32 34 35 36 37 39 40 41 42 43 44 45 46 47 48 52 53 54 55];
    %ix = [7 8 9 14 15 16 28 30 40 41 42 43 44 45 46 55];


    % %% Scatter Plot
    % figure(3); clf; hold on
    % scatter(Ashift_ByTrack(ix,:),2,3,'filled','ColorVariable',4,'SizeData',100); colormap([[0 0.4470 0.7410]; [0.8500 0.3250 0.0980]]);
    % scatter(Ashift_Agg(1),Ashift_Agg(2),400,'pentagram','filled','MarkerFaceColor',[0.9290 0.6940 0.1250],'MarkerEdgeColor','k');
    % set(gca, 'XAxisLocation', 'origin', 'YAxisLocation', 'origin','fontsize',16)
    % xlabel('East shift (m)'); ylabel("North shift (m)")
    % axis([-10 10 -10 10])
    % colorbar
end







