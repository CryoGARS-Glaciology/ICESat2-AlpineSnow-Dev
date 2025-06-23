function [xc,yc,theta] = ICESat2_FootprintCorners(norths,easts,default_length,end_flag)
% ICESat2_Footprint calculates the corners of the window around each
% ICESat2 datapoint. This function uses a footprint width of 11 and length
% of 100 for ATLO8 and length of 40 for ATL06
%
% Written by Karina Zikan and Ellyn Enderlin
% Last update: Nov 2023
%
% INPUTS:
%   norths = northing coordinates for ICESat2 segment centerpoints
%   easts = easting coordinates for ICESat2 segment centerpoints
%   default_length = set the length of the ICESat-2 window, atl08 has a
%                    windowlength of 100, atl06 has a windowlength of 40
%   end_flag = logical array locating the last point in each track
% OUTPUTS:
%   xc = x corner coordinates order: (center1 center2 corner1 corner2
%        corner3 corner4)
%   yc = y corner coordinates
%   theta = angle theta between the icesat2 track and due east

%specify ICESat-2 footprint width & length
footwidth = 11; % approx. width of icesat2 shot footprint in meters
% initialize matrix for RGT orientations
theta = NaN(size(norths,1),2);

% create polygons of ICESat-2 footprints
for r = 1:size(theta,1)
    %calculate the footprint orientation
    if r == 1  || end_flag(r)-end_flag(r-1) == 0 %only angle pointed forwards
        theta(r,1) = atan2d((norths(r+1)-norths(r)),(easts(r+1)-easts(r))); theta(r,2) = theta(r,1);
        footlength = default_length;
    elseif r == size(theta,1) || end_flag(r)-end_flag(r+1) == 0 %only angle pointed backwards
        theta(r,1) = atan2d((norths(r)-norths(r-1)),(easts(r)-easts(r-1))); theta(r,2) = theta(r,1);
        footlength = default_length;
    else %calculate angles in each direction
        theta(r,1) = atan2d((norths(r)-norths(r-1)),(easts(r)-easts(r-1)));
        theta(r,2) = atan2d((norths(r+1)-norths(r)),(easts(r+1)-easts(r)));
        footlength = sqrt((norths(r+1)-norths(r-1)).^2 + (easts(r+1)-easts(r-1)).^2)/2;
    end
    
    %find box edges along the RGT
    back_x = easts(r)-(footlength/2)*cosd(theta(r,1)); back_y = norths(r)-(footlength/2)*sind(theta(r,1));
    front_x = easts(r)+(footlength/2)*cosd(theta(r,2)); front_y = norths(r)+(footlength/2)*sind(theta(r,2));
    
    %find box edges perpendicular to the centroid
    xc(r,1) = easts(r)+(footwidth/2)*cosd(nanmean(theta(r,:))+90); yc(r,1) = norths(r)+(footwidth/2)*sind(nanmean(theta(r,:))+90);
    xc(r,2) = easts(r)+(footwidth/2)*cosd(nanmean(theta(r,:))-90); yc(r,2) = norths(r)+(footwidth/2)*sind(nanmean(theta(r,:))-90);
    
    %solve for corner coordinates
    xc(r,3) = back_x+(footwidth/2)*cosd(theta(r,1)+90); yc(r,3) = back_y+(footwidth/2)*sind(theta(r,1)+90);
    xc(r,4) = back_x+(footwidth/2)*cosd(theta(r,1)-90); yc(r,4) = back_y+(footwidth/2)*sind(theta(r,1)-90);
    xc(r,5) = front_x+(footwidth/2)*cosd(theta(r,2)-90); yc(r,5) = front_y+(footwidth/2)*sind(theta(r,2)-90);
    xc(r,6) = front_x+(footwidth/2)*cosd(theta(r,2)+90); yc(r,6) = front_y+(footwidth/2)*sind(theta(r,2)+90);
    clear back_* front_*;
end
theta = theta(:,1);