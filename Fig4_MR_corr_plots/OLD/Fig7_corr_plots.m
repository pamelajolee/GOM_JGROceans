%% Figure 7 - Correlation between only MR discharge vs. Chl-a and Nitrate
% Using same format as Fig6 so that days are aggregated correctly. 
% Discharge on Y axis, chl-a and nitrate on x-axis. 1 by 2 tilelayout

clc;clear;close all;

% Add Paths and Load Data
addpath(genpath('/Users/pameladoran/Documents/Toolbox-19May2024'));
addpath(genpath('/Volumes/PamelaResearch/Luna_project/Fig6_TwoD_plots/'))
load('/Volumes/PamelaResearch/Luna_project/GoM_data/mat_files/HYCOM_MLD.mat');
load('/Volumes/PamelaResearch/Luna_project/GoM_data/mat_files/LC_values_all_200m.mat');
load('/Volumes/PamelaResearch/Luna_project/GoM_data/mat_files/discharge_ts.mat');
load('/Volumes/PamelaResearch/Luna_project/GoM_data/mat_files/MR_Nitrate_2018to2024.mat');
load('LCFE_colors.mat'); 

%% Organize Tables and Dates
LC_table = struct2table(LC_values);
river_table = table(DT, miss_ds, atch_ds);
nitrate_table = timetable2table(Nitrate_TT);
mld_table = struct2table(MLD);
dates = [LC_values.date]';

% Crop the dates of River discharge to match other variables - only MR
total_ds = (river_table.miss_ds) ./ 1000; % in 10^4 m3/s
river_true = ismember(DT, dates);
river_dates = DT(river_true, :); 
river_day = day(river_dates, 'dayofyear'); % X-value
total_ds_all = total_ds(river_true); % Y-value

% Remove the associated timezone from Nitrate
nitrate_unzoned = nitrate_table.Time; 
nitrate_unzoned.TimeZone = '';
nitrate_table = table(nitrate_unzoned, nitrate_table.Nitrate_mgL);

% Crop the dates of the nitrate table to match east_chlor
nitrate_true = ismember(nitrate_unzoned, dates);
nitrate_dates = nitrate_table.nitrate_unzoned(nitrate_true, :);
nitrate_day = day(nitrate_dates, 'dayofyear'); % X
total_nitrate = nitrate_table.Var2(nitrate_true); % Y

% Extract variables from each table
chlor_day = day(dates, 'dayofyear'); % X-value
east_chlor = LC_table.east_chlor; % Use as Y value


%% Aggregagte by day so dates all match up
[total_river_day, total_ds_mean, total_ds_std] = aggregate_by_day_of_year(river_day, total_ds_all, river_day); %365
[total_chlor_day, total_chlor_mean, total_chlor_std] = aggregate_by_day_of_year(chlor_day, east_chlor, chlor_day); %365
[total_nitrate_day, total_nitrate_mean, total_nitrate_std] = aggregate_by_day_of_year(nitrate_day, total_nitrate, nitrate_day);

%% Plotting
figure('Position', [412 594 1458 688]);
tiledlayout(1,2, 'TileSpacing','compact', 'Padding','loose');
fontsz = 18;

% TwoD_subplot(x, y, y_std, fontsz, tile_num, color, do_fit, xlab, ylab, show_xlabel, show_ylabel)

% (1) Top-left: MR vs. Chl-a
TwoD_subplot(total_chlor_mean, total_ds_mean, total_ds_std, ...
    fontsz, 1, magenta, true, ...
    'Eastern GoM Chlorophyll-a (mg/m^{3})', 'MR River Discharge (x10^4 m^3/s)', ...
    true, true); 

% (2) Top-right: MLD
TwoD_subplot(total_nitrate_mean, total_ds_mean, total_ds_std, ...
    fontsz, 2, dgreen, true, ...
    'Nitrate Concentration (mg/L)', 'MR River Discharge (x10^4 m^3/s)', ...
    true, false);  


%% Export
savepath = '/Volumes/PamelaResearch/Luna_project/Fig7_MR_corr_plots/';
figname = [savepath 'Fig7_MR_corr_plots.tiff'];
exportgraphics(gcf, figname, 'BackgroundColor', 'none', 'Resolution', 300);
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

function TwoD_subplot(x, y, y_std, fontsz, tile_num, color, do_fit, xlab, ylab, show_xlabel, show_ylabel)
    nexttile(tile_num);
    hold on;
    spacing = 10;
    idx = 1:spacing:length(x);
    errorbar(x(idx), y(idx), y_std(idx), 'o', ...
        'MarkerFaceColor', color, ...
        'Color', color, 'MarkerSize', 5, 'CapSize', 4, 'LineWidth', 1.2);
    plot(x, y, '.', 'Color', color, 'MarkerSize', 15);

    if do_fit
        p = polyfit(x, y, 1);
        x_fit = linspace(min(x), max(x), 100);
        y_fit = polyval(p, x_fit);
        plot(x_fit, y_fit, '-', 'Color', 'k', 'LineWidth', 2);

        R = corrcoef(x, y, 'Rows','complete');
        r = R(1,2);
        eqn_str = sprintf('y = %.2fx + %.2f\nr = %.2f', p(1), p(2), r);
        text(0.75, 0.92, eqn_str, 'Units', 'normalized', ...
            'FontSize', fontsz-2, 'BackgroundColor','w');
    end

    if show_xlabel
        xlabel(xlab, 'FontSize', fontsz+2);
    else
        xticklabels([]);
    end

    if show_ylabel
        ylabel(ylab, 'FontSize', fontsz+2);
    else
        yticklabels([]);
    end

    set(gca, 'FontSize', fontsz , 'Box','on','LineWidth',1.2);
    grid on;
    

     % Subplot letter
    labels = 'abcdefgh';
    text(0.98, 0.02, ['(' labels(tile_num) ')'], 'Units', 'normalized', ...
        'HorizontalAlignment', 'right', 'VerticalAlignment', 'bottom', ...
        'FontSize', fontsz +10, 'Color', [0 0 0]);
end
