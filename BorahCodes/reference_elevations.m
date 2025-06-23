function [Rnmad,E] = reference_elevations(icesat2_elevations, norths, easts, end_flag, default_length, elevations, slope, aspect, Ref, A)
% Function COREGISTER_ICESAT2 coregisters icesat-2 data with a corresponding digital
% terrain model 
% INPUTS:   icesat2_elevations = array of ICESat-2 elevations
%           norths = array of ICESat-2 Northing coordinates
%           easts = array of ICESat-2 Easting coordinates
%           end_flag = location of the last data point of each track
%           default_length = length of ICESat-2 averaving window
%           elevations = the reference elevation matrix 
%           slope =  slope matrix
%           aspect =  aspect matrix
%           Ref = the cell map reference for the reference DTM
%           A = a [2 1] vector that serves as the spatial offsets in
%                       the x and y directions (meters)
% OUTPUTS:  E = array of reference elevations
%           Rnmad = normalized median absolute difference of
%               ICESat-2_elevations - elevations

% last modified May 2024 Karina Zikan (karinazikan@u.boisestate.edu)

% Set ICESat-2 footwidth
footwidth = 11; % approx. width of icesat2 shot footprint in meters

%% Calculating footprints for each data point
%define the Reference elevation data
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

% calculates footprint corners
[xc,yc,theta] = ICESat2_FootprintCorners(A(2)+norths,A(1)+easts,default_length,end_flag);

%% Calculate Reference Elevations, Slope, & Aspect
for r=1:length(icesat2_elevations)

    %identify the R2erence elevation points in each ICESat2 footprint
    xv = xc(r,[3:6]); %3]); % bounding box x vector
    yv = yc(r,[3:6]); %3]); % bounding box y vector

    % % subset giant grid
    % ix = find(x <= (easts(r)+(default_length./2 + 10)) & x >= (easts(r)-(default_length./2 + 10))); % x index for subgrid
    % iy = find(y <= (norths(r)+(default_length./2 + 10)) & y >= (norths(r)-(default_length./2 + 10))); % y index for subgrid
    % xsubgrid = xgrid(iy,ix);
    xsubgrid = xgrid(:);
    % ysubgrid = ygrid(iy,ix);
    ysubgrid = ygrid(:);
    % subelevations = elevations(iy,ix);
    subelevations = elevations(:);
    % subslope = slope(iy,ix);
    subslope = slope(:);
    % subaspect = aspect(iy,ix);
    subaspect = aspect(:);

   %data in the footprint
    in = inpoly2([xsubgrid, ysubgrid], [xv', yv']); % get logical array of in values

    pointsinx = xsubgrid(in); % save x locations
    pointsiny = ysubgrid(in); % save y locations
    elevationsin = subelevations(in); % save elevations
    slopesin = subslope(in); % save slopes
    aspectsin = subaspect(in); % save slopes

    %wieghted average
    dist = nan([1,length(pointsinx)])'; %initialize dist
    for a = 1:length(pointsinx)
        phi = atan2d((pointsiny(a)-norths(r)),(pointsinx(a)-easts(r)));
        dist(a)=abs(sqrt((pointsiny(a)-norths(r))^2+(pointsinx(a)-easts(r))^2)*sind(phi-theta(r))); %distance from the line in the center of the window
    end
    maxdist = footwidth/2; % defining the maximum distance a point can be from the center icesat2 point
    w = 15/16*(1-(dist/maxdist).^2).^2; %bisqared kernel
    elevation_report_mean(r,:) = sum(w.*elevationsin)./sum(w); %weighted elevation estimate
    elevation_report_std(r,:) = std(elevationsin); %std of the elevations within the footprint

    %non wieghted average
    elevation_report_nw_mean(r,:) = nanmean(elevationsin); % non-wieghted elevations
    slope_mean(r,:) = nanmean(slopesin);
    slope_std(r,:) = std(slopesin);
    aspect_mean(r,:) = nanmean(aspectsin);
    aspect_std(r,:) = std(aspectsin);

    %fitted surface
    if sum(sum(~isnan(elevationsin))) >= 3
        warning('off')
        ix = find(~isnan(elevationsin));
        p = fit([pointsinx(ix), pointsiny(ix)],elevationsin(ix),'poly11'); %fit linear polynomial
        elevation_report_fitted(r,:) = p(easts(r),norths(r));
        along_slope(r,:) = abs(atand((p(xv(:,1),yv(:,1))-p(xv(:,4),yv(:,4)))/default_length));
        across_slope(r,:) = abs(atand((p(xv(:,1),yv(:,1))-p(xv(:,2),yv(:,2)))/footwidth));
        x_slope = p((easts(r)+1),norths(r)) - p(easts(r),norths(r));
        y_slope = p(easts(r),(norths(r)+1)) - p(easts(r),norths(r));
        aspect_fit(r,:) = mod(270 - atan2d(y_slope,x_slope),360);
    else
        elevation_report_fitted(r,:) = NaN;
        along_slope(r,:) = NaN;
        across_slope(r,:) = NaN;
        aspect_fit(r,:) = NaN;
    end
end
%interpolated elevation
elevation_report_interp = interp2(x,y,elevations,easts,norths);

%compile table of elevations
E = table(elevation_report_nw_mean,elevation_report_mean,elevation_report_interp,elevation_report_fitted,elevation_report_std,slope_mean,slope_std,along_slope,across_slope,aspect_mean,aspect_std,aspect_fit);

% calculate mean & NMAD
Residuals = icesat2_elevations - elevation_report_nw_mean; % difference ICESat-2 and ref elevations
Rmean = nanmean(Residuals); % calculate mean of Residuals
Rnmad = 1.4826*median(abs(Residuals-Rmean),'omitnan'); % normalized meadian absolute difference

