%% FUNCTION - Calculates the ADT mean for each CMEMS file over
%% the Gulf of Mexico deepwater (>200 m depth) following Leben et al., 2005
%% definition and adapted from Luna Hiron script

%%
function [lon_adt, lat_adt, adt_anom, adt_masked] = gom_adt(year, month, day)

% adt_anom will have values for the entire gulf of mexico but have the mean
% removed for only deepwater (> 200m). adt_masked will only have the values
% for the central gom

path1 = '/Volumes/PamelaResearch/UGOS3/Draft/Data/CMEMS/';

% Construct date strings
date1 = num2str(year, '%04d');
date2 = num2str(month, '%02d');
date3 = num2str(day, '%02d');

% For Altimetry (CMEMS)
path1a = [path1 num2str(year) '/'];
if year == 2024 %nrt_global_allsat_phy_l4_20240101_20240107.nc
    fileN1 = dir([path1a,'nrt_global_allsat_phy_l4_' date1 date2 date3 '*.nc']);

elseif year == 2023 % nrt_global_allsat_phy_l4_20230101_20230107.nc
    fileN1 = dir([path1a,'nrt_global_allsat_phy_l4_' date1 date2 date3 '*.nc']);

else
    fileN1 = dir([path1a, 'dt_global_allsat_phy_l4_' date1 date2 date3 '*.nc']);
end

if exist("fileN1", "var")

    fname1 = [path1a fileN1.name];

    top_file = '/Volumes/PamelaResearch/Luna_project/GoM_data/w100n40.nc';

    %% Domain - min and max lat and lon values

    lat_i = 17; lat_f = 32;
    lon_i = -98; lon_f = -78;

    %% Topography reading and cropping

    lon_t = ncread(top_file, 'x');
    lat_t = ncread(top_file, 'y');

    % min(abs) - returns indces for corresponding lat and lon
    [~,xi] = min(abs(lon_t - lon_i));
    [~,xf] = min(abs(lon_t - lon_f));
    dx = xf - xi + 1;

    [~,yi] = min(abs(lat_t - lat_i));
    [~,yf] = min(abs(lat_t - lat_f));
    dy = yf - yi + 1; % Need to include plus 1 when subtracting

    % topography for only GoM
    topo = ncread(top_file, 'z', [xi yi], [dx dy]); 
    lon_topo = lon_t(xi:xf);
    lat_topo = lat_t(yi:yf);
    
    %% ADT grid reading and cropping
    longitude = ncread(fname1, 'longitude');
    latitude = ncread(fname1, 'latitude');

    [~,xi] = min(abs(longitude - lon_i));[~,xf] = min(abs(longitude - lon_f));
    dx = xf - xi + 1;
    
    [~,yi] = min(abs(latitude - lat_i));[~,yf] = min(abs(latitude - lat_f));
    dy = yf - yi + 1;
    
    lon = longitude(xi:xf);
    lat = latitude(yi:yf);

    %% Interp topogrphy to adt grid
    [X1,Y1] = meshgrid(lon_topo,lat_topo);
    [X2,Y2] = meshgrid(lon,lat);
    Topo_interp = interp2(X1,Y1,topo',X2,Y2);

    %% take caribbean ocean out of gom adt
    xy_mexico = [-86.6 21.2];
    xy_cuba = [-85.1 21.8];
    
    m = (xy_cuba(2) - xy_mexico(2))/(xy_cuba(1) - xy_mexico(1));
    b = xy_mexico(2) - m*xy_mexico(1);
    
    x = -91:-80;
    y = m*x + b;
    
    id_nan = find(Y2 - m*X2 - b < 0 | X2 > -82);
    Topo_interp(id_nan) = nan;

    %% nan if shallower than 200m
    Topo_interp(Topo_interp >-200) = nan;
    
    id_adt_nan = find(isnan(Topo_interp));

    %% ADT mean removal for GoM when topo > 200m

    adt_total = ncread(fname1,'adt',[xi yi 1],[dx dy 1])';
    
    % Apply the mask to remove shollower than 200 m, the Caribbean waters, and Atlantic 
    adt_masked = adt_total;
    adt_masked(id_adt_nan)=nan;

    % Calculate and remove seasonal signal from the ADT masked region
    adt_mean_gom = nanmean(adt_masked(:));
    % clear adt_masked

    adt_anom = adt_total - adt_mean_gom; % full region with mean removed from >-200
    adt_masked = adt_masked - adt_mean_gom; % only GoM to plot LCFE and not Gulf Stream


    %% Reassign variables for easy function use 
    lon_adt = X2;
    lat_adt = Y2;

else
    disp(['File not found for date: '  date2 ' ' date3 ' ' date1]);
    return
end
end