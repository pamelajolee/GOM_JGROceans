%% FUNCTION - Retrieves the SSH and MLD from HYCOM
% Uses the same format at "gom_adt", but does not remove the spatial mean
% since HYCOM is central to the GoM. Still removing the shallow water and
% Caribbean from final output.

%%
function [lon_ssh, lat_ssh, ssh, ssh_masked, mld] = gom_hycom_ssh(year, month, day)

% ssh will have values for the entire gulf of mexico but have the mean
% removed for only deepwater (> 200m). ssh_masked will only have the values
% for the central gom

path1='/Volumes/PamelaResearch/Matlab_files/HYCOM/GOMb0.04_reanalysis/Daily_00_2d/';

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

if ismember(year, [2021, 2022, 2023])
    fileN1=dir([path1a,'035_archv.' date1 '_' NumDays '*.nc']);
elseif ismember(year, 2024)
    fileN1 = dir([path1a, '037_archv.' date1 '_' NumDays '*.nc']);
else
    fileN1=dir([path1a,'031_archv.' date1 '_' NumDays '*.nc']);
end


if exist("fileN1", "var")

    fname1 = [path1a fileN1.name];

    top_file = '/Volumes/PamelaResearch/Matlab_files/w100n40.nc';

    %% Domain - min and max lat and lon values

    lat_i = 21; lat_f = 30;
    lon_i = -98; lon_f = -80;

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

    id_nan = find(Y2 - m*X2 - b < 0 | X2 > -82);
    Topo_interp(id_nan) = nan;

    %% nan if shallower than 200m
    Topo_interp(Topo_interp >-200) = nan;

    id_ssh_nan = find(isnan(Topo_interp));

    %% Set SSH so that it has caribbean and shallow water removed
    % Apply the mask to remove shollower than 200 m, the Caribbean waters, and Atlantic
    ssh_total = ncread(fname1,'ssh')';

    ssh_masked = ssh_total;
    ssh_masked(id_ssh_nan) = NaN;
    ssh_total(id_ssh_nan)= NaN;

    % Calculate and remove seasonal signal from the SSH masked region
    ssh_mean_gom = nanmean(ssh_masked(:));

    % SSH and SSH Masked are actuallly Sea Level Anomaly
    ssh = ssh_total; % full region with mean removed from >-200
    ssh_masked = ssh_masked - ssh_mean_gom; % only GoM to plot LCFE and not Gulf Stream

    % Retrieve Mixed Layer Thickness
    mld = ncread(fname1, 'mixed_layer_thickness')'; % Unit of Meters

    %% Reassign variables for easy function use
    lon_ssh = X2;
    lat_ssh = Y2;

else
    disp(['File not found for date: '  date2 ' ' date3 ' ' date1]);
    return
end
end