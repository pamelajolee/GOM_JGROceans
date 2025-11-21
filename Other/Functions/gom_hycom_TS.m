%% FUNCTION - Retrieves the SSH from HYCOM
% Uses the same format at "gom_adt", but does not remove the spatial mean
% since HYCOM is central to the GoM. Still removing the shallow water and
% Caribbean from final output.

%%
function [lon_hycom, lat_hycom, temp, salt, depth] = gom_hycom_TS(year, month, day)

% ssh will have values for the entire gulf of mexico but have the mean
% removed for only deepwater (> 200m). ssh_masked will only have the values
% for the central gom

path1='/Volumes/PamelaResearch/Matlab_files/HYCOM/GOMb0.04_reanalysis/Daily_00_3z/';

% Construct date strings
date1 = num2str(year, '%04d');
date2 = num2str(month, '%02d');
date3 = num2str(day, '%02d');

% Get file for SSH
% Defining NumDays for files that use Julian
NumDays = datenum(year, month, day) - datenum(year-1, 12, 31);
NumDays = num2str(NumDays, '%03d');

% For SSH (HYCOM)
path1a = [path1 num2str(year) '/'];

if ismember(str2double(date1), [2021, 2022, 2023]) % 035_archv.2021_001_00_3z.nc
    fileN1=dir([path1a,'035_archv.' date1 '_' NumDays '*.nc']);

else % 031_archv.2018_280_00_3z.nc
    fileN1=dir([path1a,'031_archv.' date1 '_' NumDays '*.nc']);
end

if exist("fileN1", "var")

    fname1 = [path1a fileN1.name];

    top_file = '/Volumes/PamelaResearch/Matlab_files/w100n40.nc';

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

    %% Grabbing the lat and lon from HYCOM
    % Don't need to crop since already GoM

    lon = ncread(fname1, 'Longitude');
    lat = ncread(fname1, 'Latitude');


    %% Interp topogrphy to ssh grid
    [X1,Y1] = meshgrid(lon_topo,lat_topo);
    [X2,Y2] = meshgrid(lon,lat);
    Topo_interp = interp2(X1,Y1,topo',X2,Y2);

    %% take caribbean ocean out of gom ssh
    xy_mexico = [-86.6 21.2];
    xy_cuba = [-85.1 21.8];

    m = (xy_cuba(2) - xy_mexico(2))/(xy_cuba(1) - xy_mexico(1));
    b = xy_mexico(2) - m*xy_mexico(1);

    x = -91:-80;
    y = m*x + b;

    id_nan = Y2 - m*X2 - b < 0 | X2 > -82;
    Topo_interp(id_nan) = nan;

    %% nan if shallower than 200m
    Topo_interp(Topo_interp >-200) = nan;

    id_var_nan = find(isnan(Topo_interp));

    %% Set W_vel so that it has caribbean and shallow water removed

    temp_total = ncread(fname1,'water_temp');
    temp = permute(temp_total, [2 1 3]); % reorder the matrix so that its [lat lon depth]

    salt_total = ncread(fname1, 'salinity');
    salt = permute(salt_total, [2 1 3]); 

    depth = ncread(fname1, 'Depth');

    % %Apply the mask to remove shollower than 200 m, the Caribbean waters, and Atlantic
    % temp_mask = temp_total;
    % temp_mask(id_var_nan)=nan;
    % 
    % salt_mask = salt_total;
    % salt_mask(id_var_nan) = nan;
    % 
    % %Calculate and remove seasonal signal from the ssh masked region
    % temp_mean_gom = nanmean(temp_mask(:));
    % salt_mean_gom = nanmean(salt_mask(:));
    % 
    % temp = temp_total - temp_mean_gom; % full region with mean removed from >-200
    % salt = salt_total - salt_mean_gom;

    %% Reassign variables for easy function use
    lon_hycom = X2;
    lat_hycom = Y2;

else
    disp(['File not found for date: '  date2 ' ' date3 ' ' date1]);
    return
end
end