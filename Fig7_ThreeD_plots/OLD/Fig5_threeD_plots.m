%% Figure 6 - 3D plots of LCFE Chl-a, LCFE Lat, River Discharge, and time
clear;
close all;
clc;
addpath(genpath('/Users/pameladoran/Documents/Toolbox-19May2024'));
load('/Volumes/PamelaResearch/Luna_project/GoM_data/LCFE_values_all.mat');
load('/Volumes/PamelaResearch/Luna_project/GoM_data/LC_values_all.mat');
load('/Volumes/PamelaResearch/Ricky_Project/GOM-GRL/Fig_1/discharge_ts.mat')

LCFE_table = struct2table(LCFE_values);
LC_table = struct2table(LC_values);
dates = [LCFE_values.date]';

river_table = table(DT, miss_ds, atch_ds); %(date, MR discharge, Atch river Discharge)

% Match river and eddy dates
river_true = ismember(DT, dates);
DT_matched = DT(river_true, :);
dates_true = ismember(dates, DT_matched);

dates_matched = dates(dates_true);
LCFE_table = LCFE_table(dates_true, :);
LC_table = LC_table(dates_true, :);
river_table = river_table(river_true, :);

% Extract variables for river discharge, scaled as in original scripts
total_ds = (river_table.atch_ds + river_table.miss_ds) ./ 1000; % in 10^4 m3/s
day_of_year = day(dates_matched, 'dayofyear');

% Extract chlorophyll & latitudes for each region
WFCE_chlor = LCFE_table.chlorIN_WFCE;
WFCE_lat = LCFE_table.max_WFCE_lat;

CBCE_chlor = LCFE_table.chlorIN_CBCE;
CBCE_lat = LCFE_table.max_CBCE_lat;

NCE_chlor = LCFE_table.chlorIN_NCE;
NCE_lat = LCFE_table.max_NCE_lat;

% --- Create combined total LCFE chlorophyll and max latitude ---
% Sum chlorophyll from all 3 regions, ignoring NaNs by treating NaNs as 0 for sum
chlor_all = nansum([WFCE_chlor, CBCE_chlor, NCE_chlor], 2);

% For max latitude take max across all three lat columns ignoring NaNs
max_lat_all = max([WFCE_lat, CBCE_lat, NCE_lat], [], 2, 'omitnan');

% Indices where combined chlorophyll is NOT NaN (i.e., sum not zero or all NaNs)
all_idx = ~isnan(chlor_all);

chlor_all = chlor_all(all_idx);
max_lat_all = max_lat_all(all_idx);
total_ds_all = total_ds(all_idx);
day_of_year_all = day_of_year(all_idx);

% --- Aggregate combined total LCFE by day of year ---
[day_x_all, chlor_avg_all, chlor_std_all] = aggregate_by_day_of_year(day_of_year_all, chlor_all, day_of_year_all);
[day_x_all_lat, lat_avg_all, lat_std_all] = aggregate_by_day_of_year(day_of_year_all, max_lat_all, day_of_year_all);
[day_x_all_ds, ds_avg_all, ds_std_all] = aggregate_by_day_of_year(day_of_year_all, total_ds_all, day_of_year_all);

% Prepare regional data as before (for individual regions)
regions = {
    'WFCE', 'chlorIN_WFCE', 'max_WFCE_lat', WFCE_chlor, WFCE_lat;
    'CBCE', 'chlorIN_CBCE', 'max_CBCE_lat', CBCE_chlor, CBCE_lat;
    'NCE',  'chlorIN_NCE',  'max_NCE_lat',  NCE_chlor,  NCE_lat
};

agg_data = cell(3,1);
for i = 1:3
    chlor = regions{i,4};
    lat = regions{i,5};
    idx = ~isnan(chlor);
    chlor = chlor(idx);
    lat = lat(idx);
    river = total_ds(idx);
    doy = day_of_year(idx);

    [r_avg, c_avg, c_std] = aggregate_by_day_of_year(river, chlor, doy);
    [day_x, r_doy_avg, r_doy_std] = aggregate_by_day_of_year(doy, river, doy);
    [~, lat_avg, lat_std] = aggregate_by_day_of_year(doy, lat, doy);

    agg_data{i} = struct('region', regions{i,1}, ...
        'chlor_avg', c_avg, 'chlor_std', c_std, ...
        'river_avg', r_avg, ...
        'day_x', day_x, 'r_doy_avg', r_doy_avg, 'r_doy_std', r_doy_std, ...
        'lat_avg', lat_avg, 'lat_std', lat_std);
end

%% Plotting 

figure('Units','normalized','OuterPosition',[0 0.1396 0.9492 0.7882]);
tiledlayout(2,2, 'TileSpacing','compact', 'Padding','loose');
fontsz = 20;

% Letters for subplots
letters = 'abcd';

% First row: Chlorophyll vs Max LCFE Latitude (aggregated by day)
for idx = 1:4
    nexttile(idx);
    if idx == 1
        scatter(lat_avg_all, chlor_avg_all, 60, ds_avg_all, 'filled');
        xlabel('Max LCFE Latitude');
        ylabel('Chlorophyll-a (mg/m^3)');
        xlim([23 29]);
        ylim([0 0.3]);
        title('Total LCFE');
    else
        d = agg_data{idx-1};
        scatter(d.lat_avg, d.chlor_avg, 60, d.river_avg, 'filled');
        xlabel('Max LCFE Latitude');
        xlim([23 29]);
        ylim([0 0.3]);
        title(d.region);
    end
    colormap(summer(100));
    clim([0 60]);
    set(gca, 'FontSize', fontsz, 'Box', 'on', 'GridLineWidth', 2);
    grid on;

    % Add subplot letter in upper left, with slight offset
    ax = gca;
    xlims = xlim(ax);
    ylims = ylim(ax);
    text(xlims(1) + 0.5*(xlims(2)-xlims(1))*0.05, ylims(2) - 0.05*(ylims(2)-ylims(1)), ...
        ['(' letters(idx) ')'], 'FontSize', fontsz+10, 'VerticalAlignment', 'top');
end

% Second row: Chlorophyll vs Day of Year (aggregated by day)
for idx = 1:4
    nexttile(idx);
    if idx == 1 
        scatter(day_x_all, chlor_avg_all, 60, ds_avg_all, 'filled');
        xlabel('Day of the Year');
        ylabel('Chlorophyll-a (mg/m^3)');
        xlim([0 366]);
        ylim([0 0.3]);
    else
        d = agg_data{idx-1};
        scatter(d.day_x, d.chlor_avg, 60, d.river_avg, 'filled');
        xlabel('Day of Year');
        xlim([0 366]);
        ylim([0 0.3]);
    end
    colormap(summer(100));
    clim([0 60]);
    set(gca, 'FontSize', fontsz, 'Box', 'on', 'GridLineWidth', 2);
    grid on;

    % Add subplot letter in upper left
    ax = gca;
    xlims = xlim(ax);
    ylims = ylim(ax);
    text(xlims(1) + 0.05*(xlims(2)-xlims(1)), ylims(2) - 0.05*(ylims(2)-ylims(1)), ...
        ['(' letters(idx) ')'], 'FontSize', fontsz+10, 'VerticalAlignment', 'top');

    % Add patch for May 1st (DOY=121) to Oct 31st (DOY=304)
    patch([121 304 304 121], [0 0 0.6 0.6], 'k', ...
        'FaceAlpha', 0.05, 'EdgeColor', 'k', 'LineWidth', 1);
end

% Common Colorbar 
cb = colorbar;
set(cb, 'Position', [0.968 0.1 0.005 0.82]);
cb.Label.String = 'River Discharge (x10^4 m^3/s)';
cb.Label.FontSize = fontsz;

% Save figure 
savepath =  '/Volumes/PamelaResearch/Luna_project/Fig5_ThreeD_plots/';
figname = fullfile(savepath, 'Fig_Combined_LCFE.tiff');
set(gcf, 'InvertHardcopy', 'off');
exportgraphics(gcf, figname, 'BackgroundColor', 'none');

disp('Finished');


%% Functions
function [x_mean, y_mean, y_std] = aggregate_by_day_of_year(x, y, day_of_year)
    days = 1:366;
    x_mean = nan(366,1);
    y_mean = nan(366,1);
    y_std = nan(366,1);
    for d = days
        idx = day_of_year == d;
        if any(idx)
            x_mean(d) = mean(x(idx), 'omitnan');
            y_mean(d) = mean(y(idx), 'omitnan');
            y_std(d) = std(y(idx), 'omitnan');
        end
    end
    valid = ~isnan(x_mean) & ~isnan(y_mean);
    x_mean = x_mean(valid);
    y_mean = y_mean(valid);
    y_std = y_std(valid);
end

