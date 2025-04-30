%%% This code was writen by Karina Zikan to graph individual ICESat-2
%%% transects over site DTMs
%%%
%%% SPECIFIED INPUTS:
%%%     icesat2 = path to ICESat-2 file (output from batch_icesat2_terrain_parameter_comparison.m)
%%%     ref_elevations = path to reference elevations file (output from DTM_reference_elevations_calculation.m)
%%%     abbrev = site abriviation for file name
%%% OUTPUTS:
%%%
%%%
%%% Last updated: Nov 2024 by Karina Zikan

%% Inputs
clearvars;
addpath(['/Users/karinazikan/Documents/ICESat2-AlpineSnow/functions'])
addpath(['/Users/karinazikan/Documents/cmocean'])
addpath(['/Users/karinazikan/Documents/Hillshade_esri/Hillshade_esri'])
addpath(['/Users/karinazikan/Documents/nclCM/nclCM'])

%Folder path
folderpath = '/Users/karinazikan/Documents/ICESat2-AlpineSnow/Sites/';
%site abbreviation for file names
abbrev = 'MCS';

% DEM path
DTM_name = [folderpath abbrev '/DEMs/MCS_REFDEM_WGS84.tif'];
%DTM_name = [folderpath abbrev '/DEMs/RCEW_1m_WGS84UTM11_WGS84.tif'];
%DTM_name = [folderpath abbrev '/DEMs/Banner_Bare_Earth_DEMs_mosaic_UTM11WGS84.tif'];
%DTM_name = [folderpath abbrev '/DEMs/DryCreekBase1m_WGS84UTM11_DEM.tif'];

% % Veg_map
% NDVI_name = [folderpath abbrev '/DEMs/NDVI_map_2020_09_RCEW_UTM11WGS84.tif'];

%% Load data ({1} = ATL08, {2} = ATL06, {3} = ATL06 w/ ATL08 classification)
%load the reference elevation data
filepath = strcat(folderpath, abbrev, '/IS2_Data/A6-40/ATL06-A6-40-AllData-fineGS-agg');
df = readtable(filepath);
df.time = datetime(df.time.Year,df.time.Month,df.time.Day);
df.Easting = df.Easting./(10^3);
df.Northing = df.Northing./(10^3);
%snow on + snow off
df_off = df(df.snowcover == 0, :);
df_on = df(df.snowcover == 1, :);

%unique dates
unique_dates = unique(df.time);


footwidth = 11; % approx. width of icesat2 shot footprint in meters

%DEM
[DTM,Ref] = readgeoraster(DTM_name);
%[NDVI,VRef] = readgeoraster(NDVI_name);
if isfield(Ref,'LatitudeLimits')
    [latgrid,longrid] = meshgrid(Ref.LongitudeLimits(1)+0.5*Ref.CellExtentInLongitude:Ref.CellExtentInLongitude:Ref.LongitudeLimits(2)-0.5*Ref.CellExtentInLongitude,...
        Ref.LatitudeLimits(2)-0.5*Ref.CellExtentInLatitude:-Ref.CellExtentInLatitude:Ref.LatitudeLimits(1)+0.5*Ref.CellExtentInLatitude);
    [xgrid, ygrid,~] = wgs2utm(latgrid,longrid);
else
    x = Ref.XWorldLimits(1)+0.5*Ref.CellExtentInWorldX:Ref.CellExtentInWorldX:Ref.XWorldLimits(2)-0.5*Ref.CellExtentInWorldX;
    if strcmp(Ref.ColumnsStartFrom,'north')
        y = Ref.YWorldLimits(2)-0.5*Ref.CellExtentInWorldY:-Ref.CellExtentInWorldY:Ref.YWorldLimits(1)+0.5*Ref.CellExtentInWorldY;
    else
        y = Ref.YWorldLimits(1)+0.5*Ref.CellExtentInWorldY:Ref.CellExtentInWorldY:Ref.YWorldLimits(2)-0.5*Ref.CellExtentInWorldY;
    end
    [xgrid, ygrid] = meshgrid(x, y); % create grids of each of the x and y coords
end
% if isfield(VRef,'LatitudeLimits')
%     [latgrid,longrid] = meshgrid(VRef.LongitudeLimits(1)+0.5*VRef.CellExtentInLongitude:VRef.CellExtentInLongitude:VRef.LongitudeLimits(2)-0.5*VRef.CellExtentInLongitude,...
%         VRef.LatitudeLimits(2)-0.5*VRef.CellExtentInLatitude:-VRef.CellExtentInLatitude:VRef.LatitudeLimits(1)+0.5*VRef.CellExtentInLatitude);
%     [vxgrid, vygrid,~] = wgs2utm(latgrid,longrid);
% else
%     vx = VRef.XWorldLimits(1)+0.5*VRef.CellExtentInWorldX:VRef.CellExtentInWorldX:VRef.XWorldLimits(2)-0.5*VRef.CellExtentInWorldX;
%     if strcmp(VRef.ColumnsStartFrom,'north')
%         vy = VRef.YWorldLimits(2)-0.5*VRef.CellExtentInWorldY:-VRef.CellExtentInWorldY:VRef.YWorldLimits(1)+0.5*VRef.CellExtentInWorldY;
%     else
%         vy = VRef.YWorldLimits(1)+0.5*VRef.CellExtentInWorldY:VRef.CellExtentInWorldY:VRef.YWorldLimits(2)-0.5*VRef.CellExtentInWorldY;
%     end
%     [vxgrid, vygrid] = meshgrid(vx, vy); % create grids of each of the x and y coords
% end
DTM(DTM>(3*10^3)) = NaN;
x = x./(10^3); % to km
y = y./(10^3);% to km
%y = flip(y);
DTM(DTM<1000) = NaN;

%NDVI(DTM<0) = NaN;

%hillshade
hs=hillshade_esri(DTM,y,x);


%% Track Plots
date = '23-Feb-2020';
dates = datetime(df.time.Year,df.time.Month,df.time.Day);
ix = find(dates == date);
Track = df(ix,:);


figure(1); clf
ax1 = axes;
Elevim = imagesc(x,y,DTM);
clim([1000 2900])
colormap(ax1,[0 0 0; nclCM('MPL_terrain',200)]); daspect([1 1 1]); % nclCM('MPL_terrain',200) %cmocean('topo','pivot', 1000.1)
xlabel('Easting [km]'); ylabel('Northing [km]');
set(gca,'fontsize',20); set(gca,'Ydir','normal');
xlim([min(x) max(x)]); ylim([min(y) max(y)]);
c = colorbar;
c.Label.String = 'Elevation (m)'; clim([1000 2900])
ax2 = axes;
hold on
HSim = imagesc(x,y,hs,'AlphaData',0.2); 
colormap(ax2,[0 0 0; cmocean('grey')]); daspect([1 1 1]);
scatter([df.Easting],[df.Northing],[],'MarkerEdgeColor',"white",'Marker','.')
xlabel('Easting [km]'); ylabel('Northing [km]');
set(gca,'fontsize',20); set(gca,'Ydir','normal');
xlim([min(x) max(x)]); ylim([min(y) max(y)]);
c2 = colorbar;
c2.Label.String = 'Elevation (m)';
hold off
%%link axes
linkaxes([ax1,ax2])
%%Hide the top axes 
ax2.Visible = 'off'; 
ax2.XTick = []; 
ax2.YTick = []; 
set(c2,'visible','off')



% %% Residual Map Plots
% cmap = cmocean('-balance'); 
% figure(2); clf
% subplot(1,2,1) 
% daspect([1 1 1]); colormap(cmap); 
% scatter(df_off,'Easting','Northing','filled','ColorVariable', 'elev_residuals_vertcoreg_is2_slopecorrected')
% xlabel('Easting [km]'); ylabel('Northing [km]');
% set(gca,'fontsize',20); set(gca,'Ydir','normal');
% c = colorbar; 
% c.Label.String = 'Elevation residual (m)'; clim([-6 6])
% title('Snow Off')
% 
% subplot(1,2,2)
% daspect([1 1 1]); colormap(cmap); 
% scatter(df_on,'Easting','Northing','filled','ColorVariable', 'elev_residuals_vertcoreg_is2_slopecorrected')
% xlabel('Easting [km]'); ylabel('Northing [km]');
% set(gca,'fontsize',20); set(gca,'Ydir','normal');
% c = colorbar;
% c.Label.String = 'Elevation residual (m)'; clim([-4 4])
% title('Snow On')

%% Residuals gif
cmap = cmocean('-balance'); 
fig = figure(3); clf
ax1 = axes; 
imagesc(x,y,DTM); hold on
%scatter([df.Easting],[df.Northing],[],'green','.');
xlim([min(x) max(x)]); ylim([min(y) max(y)]); daspect([1 1 1]);
set(gca,'fontsize',20); set(gca,'Ydir','normal');
xlabel('Easting [km]'); ylabel('Northing [km]');
c1 = colorbar;
ax2 = axes;
for idx = 1:length(unique_dates)   
    df_plot = df(df.time == unique_dates(idx), :);
    scatter(df_plot,'Easting','Northing','filled','ColorVariable', 'elev_residuals_vertcoreg_is2_slopecorrected')
    xlabel('Easting [km]'); ylabel('Northing [km]');
    set(gca,'fontsize',20); set(gca,'Ydir','normal');
    c2 = colorbar; c2.Label.String = 'Elevation residual (m)'; clim([-6 6])
    xlim([min(x) max(x)]); ylim([min(y) max(y)]); daspect([1 1 1]);

    ax1.Title.String = string(unique_dates(idx),'MMM-yyyy');

    colormap(ax1,[0 0 0; cmocean('grey')])
    colormap(ax2,cmap)
    ax2.Visible = 'off';
    ax2.XTick = [];
    ax2.YTick = [];
    set(c1,'visible','off')


    drawnow
    frame = getframe(fig);
    im{idx} = frame2im(frame);
    clear df_plot
end
%
figure;
for idx = 1:length(unique_dates)
    subplot(8,7,idx)
    imshow(im{idx});
end
% %% export gif
% filename = ['/Users/karinazikan/Documents/ICESat2-AlpineSnow/FigureCodes/Figures/' abbrev '_ElevResiduals.gif']; % Specify the output file name
% for idx = 1:length(unique_dates)
%     [A,map] = rgb2ind(im{idx},256);
%     if idx == 1
%         imwrite(A,map,filename,"gif",LoopCount=Inf, ...
%             DelayTime=1)
%     else
%         imwrite(A,map,filename,"gif",WriteMode="append", ...
%             DelayTime=1)
%     end
% end
%%
cmap = cmocean('-balance'); 
fig = figure(4); clf
ax1 = axes; 
imagesc(x,y,DTM); hold on
xlim([603.5 608]); ylim([4863.7 4869.5]); daspect([1 1 1]);
set(gca,'fontsize',20); set(gca,'Ydir','normal');
xlabel('Easting [km]'); ylabel('Northing [km]');
c1 = colorbar; c1.Label.String = 'Elevation (m)';

% HSim = imagesc(x,y,hs,'AlphaData',1); 
% colormap(ax1,[0 0 0; cmocean('grey')]); daspect([1 1 1]);
% xlabel('Easting [km]'); ylabel('Northing [km]');
% set(gca,'fontsize',20); set(gca,'Ydir','normal');
% xlim([603.5 608]); ylim([4863.7 4869.5]); daspect([1 1 1]);
% c1 = colorbar;
% c1.Label.String = 'Elevation (m)';


ax2 = axes;
for idx = 36 
    df_plot = df(df.time == unique_dates(idx), :);
    scatter(df_plot,'Easting','Northing','filled','ColorVariable', 'elev_residuals_vertcoreg_is2_slopecorrected')
    xlabel('Easting [km]'); ylabel('Northing [km]');
    set(gca,'fontsize',20); set(gca,'Ydir','normal');
    c2 = colorbar; c2.Label.String = 'Elevation residual (m)'; clim([-6 6])
    xlim([603.5 608]); ylim([4863.7 4869.5]); daspect([1 1 1]);

    ax1.Title.String = string(unique_dates(idx),'MMMM dd yyyy');

    colormap(ax1,[0 0 0; cmocean('grey')])
    colormap(ax2,cmap)
    ax2.Visible = 'off';
    ax2.XTick = [];
    ax2.YTick = [];
    set(c2,'visible','off')
    %set(c1,'visible','off')


    drawnow
    frame = getframe(fig);
    im{idx} = frame2im(frame);
    clear df_plot
end

%%link axes
linkaxes([ax1,ax2])








