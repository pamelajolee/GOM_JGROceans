%% Looking at Chl-a advection of Chl-a in 2020
% A total of five functions are needed to run the script:
% First two for collecting data:
% 1. track_LCFE_center
% 2. chlor_flux_data
% The track_LCFE_center needs a range of dates, and a mask region so that
% it only track the wanted LCFE. The home_vert_data will then also need the
% same range of dates, and the center_data structure to find the center lat
% and lon for each day.

% Three seperate plotting functions are needed to complete the figure:
% 1. chlor_subplot
% 2. density_subplot
% 3. advection_plot
% Each plotting function will read in the required variables and only
% require an entry of year, month, day, fontsz, and tilenum

% Added additonal calcuation that determine the horizotnal transport 
% (or advective flux of chl-a) in mg/day. Making timeseries instead of Homv
% plot

clear;clc;close all;

addpath(genpath('/Users/pameladoran/Documents/Toolbox-19May2024'));
addpath(genpath('/Volumes/PamelaResearch/Luna_project/GoM_data/Functions/'));
addpath(genpath('/Volumes/PamelaResearch/Luna_project/Fig8_2020_HYCOM_Panels/'))

%% Make the Figure 
figure(1)
set(gcf,'Position',[15 110 1435 1227])
t = tiledlayout(3,3);
t.TileSpacing = 'tight';
t.Padding = 'compact';
fontsz = 20;

%% Determine the Center of the LCFE

% Get sample adt to make the mask
yr = 2020;mo=3;dy=17;
[lon_adt, lat_adt, adt_anom, adt_masked] = gom_adt(yr, mo, dy);
[lon_ssh, lat_ssh, ssh_ssh_masked] = gom_hycom_ssh(yr, mo, dy);

% Mask the unwanted LCFEs - Was originally in the chlor-subplot function
%mask = (lon_adt >= -87) & (lon_adt <= -85) & (lat_adt >= 25); % 2019
adt_mask = (lat_adt >=25); % 2020 NCE
ssh_mask = (lat_ssh >= 25);
% mask = (lat <= 25); 2020 CBCE
% mask = (lon_adt >=-87); % 2021
% adt_masked(~mask) = NaN;  % Keep only within the region, NaN everything else
% m_contour(lon_adt, lat_adt, adt_masked, [-0.28 -0.28], 'Color', 'w', 'LineWidth', 3);
% hold on

% Get the center, vertical velocity, and mld for the span on dates that the
% LCFE in question exist - Determined by watching animations
dates = datetime(2020,1,26):datetime(2020,3,23);
[center_data] = track_HYCOM_LCFE(dates, ssh_mask);

% Convert to Table to easier viewing
center_table = struct2table(center_data);

% Extract coordinates
n   = numel(center_data);
lat = [center_data.center_lat];
lon = [center_data.center_lon];

% Convert dates to numeric time
time = datenum([center_data.date]);

% Only interpolate if there are NaNs in lat or lon
if any(isnan(lat)) || any(isnan(lon))
    % Interpolate missing data (ignoring NaNs in the input)
    lat_interp = interp1(time(~isnan(lat)), lat(~isnan(lat)), time, 'linear');
    lon_interp = interp1(time(~isnan(lon)), lon(~isnan(lon)), time, 'linear');

    % Update the structure with interpolated values
    for i = 1:n
        center_data(i).center_lat = lat_interp(i);
        center_data(i).center_lon = lon_interp(i);
    end

    disp('Coordinates interpolated.');
else
    disp('No interpolation needed.');
end


%% Density profile panels
% center ocations are decided from LCFE_values
% addpath(genpath('/Volumes/PamelaResearch/Luna_project/GoM_data/mat_files/'))
% load LCFE_values_all.mat LCFE_values % Used for finding center location

% 2020 - appear
yr = year(dates(1));mo=month(dates(1));dy=day(dates(1));
% current_date = datetime(year,month,day);
% idx = LCFE_table.date == current_date;
% center = LCFE_values(idx).center_CBCE(:)';
target_lat = center_data(1).center_lat;
target_lon = center_data(1).center_lon;
density_subplot(yr, mo, dy, fontsz, 4, target_lat, target_lon)
cb4 = colorbar(gca);
cb4.TickLabels = [];
cb4.Location = "south";
cb4.Visible = 'off';
freezeColors(gca)
freezeColors(cb4)

% 2020 - max chl-a
% find index of when maximum chl-a occurs inside LCFE
[max, idx] = max([center_data.chlorIN]);
% find dates
max_date = [center_table(idx,:).date];
yr = year(max_date);mo=month(max_date);dy=day(max_date);
% current_date = datetime(year,month,day);
% idx = LCFE_table.date == current_date;
% center = LCFE_values(idx).center_CBCE(:)';
target_lat = center_data(idx).center_lat;
target_lon = center_data(idx).center_lon;
density_subplot(yr, mo, dy, fontsz, 5, target_lat, target_lon)
cb5 = colorbar(gca);
cb5.TickLabels = [];
cb5.Location = 'south';
cb5.Visible = 'off';
freezeColors(gca)
freezeColors(cb5)

% 2020 - seperation
yr = year(dates(end));mo=month(dates(end));dy=day(dates(end));
% current_date = datetime(year,month,day);
% idx = LCFE_table.date == current_date;
% center = LCFE_values(idx).center_CBCE(:)';
target_lat = center_data(end).center_lat;
target_lon = center_data(end).center_lon;
density_subplot(yr, mo, dy, fontsz, 6, target_lat, target_lon)
freezeColors(gca)

% Density Colorbar
cb2 = colorbar(gca, "eastoutside");
cb2.Label.String = 'Density (kg/m^3)';
cb2.Label.FontSize = fontsz;
freezeColors(gca)
freezeColors(cb2);

%% Timeseries - Calcuate Surface Horizontal Advection of Chl-a

% Use the determined center_data to obtain the vertical velocity for the
% center of the LCFE
[u_data, v_data, mld_data, depth, nDays] = chlor_flux_data(dates, center_data);

% Make the Plot
ax7 = nexttile(7,[1 3]);
time_plot(dates, center_data, u_data, v_data, mld_data, max_date, fontsz)
freezeColors(ax7)

text(ax7, 0.01, 0.98, '(g)', ...
    'Units', 'normalized', ...
    'FontSize', fontsz +10, ...
    'HorizontalAlignment', 'left', ...
    'VerticalAlignment', 'top', ...
    'BackgroundColor', 'white', ...
    'FontName', 'Times New Roman');


%% Chlorophyll-a spatial panels - Use the same mask from the Homvoller plot
% Must be last because the colormap is logorithmic, and freezeColors will
% not work if not last

% 2020 - LCFE appears
yr = year(dates(1));mo=month(dates(1));dy=day(dates(1));
%ax1 = nexttile(t1, 1);
chlor_subplot(yr, mo, dy, fontsz, 1, ssh_mask)
freezeColors(gca)

% 2020 - max chl-a inside LCFE
yr = year(max_date);mo=month(max_date);dy=day(max_date);
%ax2 = nexttile(t1, 2);
chlor_subplot(yr, mo, dy, fontsz, 2, ssh_mask)
freezeColors(gca)

% 2020 - LCE seperation
yr = year(dates(end));mo=month(dates(end));dy=day(dates(end));
%ax3 = nexttile(t1, 3);
chlor_subplot(yr, mo, dy, fontsz, 3, ssh_mask)
freezeColors(gca)

% Chl-a Colorbar
cb1 = colorbar(gca, "eastoutside");
set(cb1, 'Position', [0.9330 0.68 0.0084 0.2825]);
cb1.Label.String = 'Log(Chlorophyll-a (mg/m^3))';
cb1.Label.FontSize = fontsz;
set(gca,'colorscale','log');
freezeColors(gca)
freezeColors(cb1);

%% Save the Figure
savepath = '/Volumes/PamelaResearch/Luna_project/Fig8_2020_HYCOM_Panels/';
figname = [savepath 'Fig8_2020_Panels_magnitude_HYCOM.tiff'];
set(gcf, 'InvertHardcopy', 'off');
exportgraphics(gcf, figname, 'BackgroundColor', 'none');

disp('Finished');
