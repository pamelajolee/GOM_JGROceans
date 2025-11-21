%% FUNCTION - Calculates the DINEOF3 mean for each daily file
%% over the Gulf of Mexico where typical cholorphyll vaues are
%% less than 10 mg/m3 (~100 m depth). Adopted from gom_adt script

%%
function [lon_chlor, lat_chlor, chlor_total] = gom_dineof_deep(year, month, day)

dineof3_path = '/Volumes/Lacie-SAN/SAN2/CoastWatchOceanColor/chlora/dineof3/';
%load('/Volumes/PamelaResearch/Luna_project/LC_data/LC_values_all.mat');


% Construct date strings
date1 = num2str(year, '%04d');
date2 = num2str(month, '%02d');
date3 = num2str(day, '%02d');

% Defining NumDays for files that use Julian
NumDays = datenum(year, month, day) - datenum(year-1, 12, 31);
NumDays = num2str(NumDays, '%03d');

% For Ocean Color (DINEOF3)
path2a = [dineof3_path num2str(year) '/'];

if year == 2024
    fileN2 = dir([path2a, 'B' date1 NumDays '*.nc']);
else
    fileN2 = dir([path2a, 'V' date1 NumDays '*.nc']);
end

if exist("fileN2", "var")

    fname2 = [path2a fileN2.name];

    %% Domain - min and max lat and lon values
    % Need to swap initial and final latitude because dienof dataset has
    % highest latitude first 

    lat_i = 32; lat_f = 17;
    lon_i = -98; lon_f = -78;

    [lon_topo, lat_topo, topo] = gom_topo;

    %% DINEOF grid reading and cropping
    longitude = ncread(fname2, 'lon');
    latitude =  ncread(fname2, 'lat');

    [~,xi] = min(abs(longitude - lon_i));[~,xf] = min(abs(longitude - lon_f));
    dx = xf - xi + 1;

    [~,yi] = min(abs(latitude - lat_i));[~,yf] = min(abs(latitude - lat_f));
    dy = yf - yi + 1;

    lon = longitude(xi:xf); %
    lat = latitude(yi:yf); % i = 32, f = 17

    %% Interp topogrphy to dineof grid
    [X1,Y1] = meshgrid(lon_topo,lat_topo);
    [X2,Y2] = meshgrid(lon,lat);
    Topo_interp = interp2(X1,Y1,topo ,X2,Y2);

    %% take caribbean ocean out of gom adt
    % Probably not nexcessary, but easier to follow other script
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
    % chlor-a structure = (time, atltitude, lat, lon)

    chlor_total = ncread(fname2,'chlor_a',[xi yi 1 1],[dx dy 1 1]);
    chlor_total = chlor_total';
    chlor_total(id_adt_nan) = nan;

    % Apply the mask to remove shollower than 100 m, the Caribbean waters, and Atlantic
    % chlor_masked = chlor_total;
    % chlor_masked(id_adt_nan)=nan;

    %chlor_avg = 0.17;

    % % Calculate and remove seasonal signal from the ADT masked region
    % chlor_mean_gom = nanmean(chlor_masked(:));
    % % clear adt_masked
    % 
    % chlor_anom = chlor_total - chlor_mean_gom; % full region with mean removed from >-100
    % chlor_masked = chlor_masked - chlor_mean_gom; % only GoM to plot LCFE and not Gulf Stream
    %chlor_masked = chlor_masked - chlor_avg;

    %% Reassign variables for easy function use
    lon_chlor = X2;
    lat_chlor = Y2;

else
    disp(['File not found for date: '  date2 ' ' date3 ' ' date1]);
    return

end
end
