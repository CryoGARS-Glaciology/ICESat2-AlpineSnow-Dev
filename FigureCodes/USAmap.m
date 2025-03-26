figure(1); clf
usamap("conus");
states = readgeotable('usastatehi.shp');
geoshow(states, 'FaceColor','none')
set(gca,'fontsize',18)

figure(2); clf
ax = usamap({'CA','ID'});
set(ax,'Visible','off')

states = readgeotable('usastatehi.shp');
geoshow(states, 'FaceColor','none','LineWidth',1)
latlim = getm(ax,'MapLatLimit');
lonlim = getm(ax,'MapLonLimit');

hold on
folderpath = '/Users/karinazikan/Documents/ICESat2-AlpineSnow/Sites/';

roi_RCEW = shaperead([folderpath '/RCEW/ROIs/RCEW-outline_WGS84.shp'] ,'usegeo', true);
roi_DCEW = shaperead([folderpath '/DCEW/ROIs/DCEW2bound_WGS84.shp'] ,'usegeo', true);
roi_MCS = shaperead([folderpath '/MCS/ROIs/MCSborder_WGS84.shp'] ,'usegeo', true);
roi_BCS = shaperead([folderpath '/Banner/ROIs/BannerBound_WGS84.shp'] ,'usegeo', true);
mapshow(roi_RCEW)
mapshow(roi_DCEW)
mapshow(roi_MCS)
mapshow(roi_BCS)

lat = states.LabelLat;
lon = states.LabelLon;
tf = ingeoquad(lat,lon,latlim,lonlim);
