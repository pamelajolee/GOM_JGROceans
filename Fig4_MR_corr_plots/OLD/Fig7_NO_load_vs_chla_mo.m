clc; clear; close all;

%% === Paths & Data ===
addpath(genpath('/Users/pameladoran/Documents/Toolbox-19May2024'));
addpath(genpath('/Volumes/PamelaResearch/Luna_project/Fig6_TwoD_plots/'))

% Load Data
load('/Volumes/PamelaResearch/Luna_project/GoM_data/mat_files/discharge_ts.mat');     % DT, miss_ds
load('/Volumes/PamelaResearch/Luna_project/GoM_data/mat_files/MR_Nitrate_2018to2024.mat'); % Nitrate_TT
load('/Volumes/PamelaResearch/Luna_project/GoM_data/mat_files/LC_values_all_200m.mat');   % LC_values
load('LCFE_colors.mat'); % for plotting color

%% === Prep Data ===

% Extract east_chlor and corresponding dates
LC_dates = [LC_values.date]';
east_chlor = [LC_values.east_chlor]';

% Convert Nitrate timetable to table, remove timezone
nitrate_table = timetable2table(Nitrate_TT);
nitrate_table.Time.TimeZone = '';

% Discharge table (in m³/s)
DT.TimeZone = '';
discharge_table = table(DT, miss_ds);  % Using only Mississippi River (miss_ds)

% Align dates: Feb 9, 2018 to Dec 31, 2023
start_date = datetime(2018,2,9);
end_date   = datetime(2023,12,31);

% Filter nitrate
nitrate_table = nitrate_table(nitrate_table.Time >= start_date & nitrate_table.Time <= end_date, :);

% Filter discharge
discharge_table = discharge_table(discharge_table.DT >= start_date & discharge_table.DT <= end_date, :);

% Filter east_chlor
valid_chlor = LC_dates >= start_date & LC_dates <= end_date;
east_chlor_filtered = east_chlor(valid_chlor);
chlor_dates = LC_dates(valid_chlor);

%% === Match Dates ===
% Create intersection of all three datasets
[common_dates, idx_nit, idx_dis] = intersect(nitrate_table.Time, discharge_table.DT);
[common_dates, idx_chl, idx_com] = intersect(chlor_dates, common_dates);

% Final aligned vectors
final_dates = common_dates;
final_nitrate = nitrate_table.Nitrate_mgL(idx_nit(idx_com));
final_discharge = discharge_table.miss_ds(idx_dis(idx_com)); % in m³/s
final_chlor = east_chlor_filtered(idx_chl);

% === Compute Nitrate Load ===
% Load = Nitrate (mg/L) * Discharge (m³/s) * 86400 s/day / 1e6 → kg/day
final_loaded_nitrate = final_nitrate .* final_discharge * 86400 / 1e6; % kg/day

%% === Monthly Aggregation ===
[chl_monthly_mean, nitrate_monthly_mean, nitrate_monthly_std] = ...
    aggregate_by_month(final_dates, final_chlor, final_loaded_nitrate);

%% === Plotting ===
figure('Position', [300 400 1000 500]);
fontsz = 18;

TwoD_subplot(chl_monthly_mean, nitrate_monthly_mean, nitrate_monthly_std, ...
    fontsz, 1, magenta, true, ...
    'Monthly Mean Chlorophyll-a (mg/m^{3})', ...
    'Monthly Mean Nitrate Load (kg/day)', ...
    true, true);

% Export
savepath = '/Volumes/PamelaResearch/Luna_project/Fig7_MR_corr_plots/';
if ~exist(savepath, 'dir'), mkdir(savepath); end
exportgraphics(gcf, [savepath 'Fig7_Monthly_LoadedNitrate_vs_Chlor.tiff'], ...
    'BackgroundColor', 'none', 'Resolution', 300);
disp('✅ Plot exported successfully!');

%% === FUNCTIONS ===

function [x_monthly_mean, y_monthly_mean, y_monthly_std] = aggregate_by_month(dates, x, y)
    % Convert to year-month index
    ym = year(dates) * 100 + month(dates);
    unique_months = unique(ym);

    x_monthly_mean = nan(length(unique_months), 1);
    y_monthly_mean = nan(length(unique_months), 1);
    y_monthly_std  = nan(length(unique_months), 1);

    for i = 1:length(unique_months)
        idx = ym == unique_months(i);
        if any(idx)
            x_monthly_mean(i) = mean(x(idx), 'omitnan');
            y_monthly_mean(i) = mean(y(idx), 'omitnan');
            y_monthly_std(i)  = std(y(idx), 'omitnan');
        end
    end

    % Remove NaNs
    valid = ~isnan(x_monthly_mean) & ~isnan(y_monthly_mean);
    x_monthly_mean = x_monthly_mean(valid);
    y_monthly_mean = y_monthly_mean(valid);
    y_monthly_std  = y_monthly_std(valid);
end

function TwoD_subplot(x, y, y_std, fontsz, tile_num, color, do_fit, xlab, ylab, show_xlabel, show_ylabel)
    nexttile(tile_num);
    hold on;
    spacing = 1;

    if ~isempty(y_std)
        errorbar(x(1:spacing:end), y(1:spacing:end), y_std(1:spacing:end), 'o', ...
            'MarkerFaceColor', color, ...
            'Color', color, 'MarkerSize', 5, 'CapSize', 4, 'LineWidth', 1.2);
    else
        plot(x(1:spacing:end), y(1:spacing:end), 'o', ...
            'MarkerFaceColor', color, ...
            'Color', color, 'MarkerSize', 5, 'LineWidth', 1.2);
    end

    plot(x, y, '.', 'Color', color, 'MarkerSize', 14);

    if do_fit
        p = polyfit(x, y, 1);
        x_fit = linspace(min(x), max(x), 100);
        y_fit = polyval(p, x_fit);
        plot(x_fit, y_fit, '-', 'Color', 'k', 'LineWidth', 2);

        R = corrcoef(x, y, 'Rows','complete');
        r = R(1,2);
        eqn_str = sprintf('y = %.2fx + %.2f\nr = %.2f', p(1), p(2), r);
        text(0.65, 0.90, eqn_str, 'Units', 'normalized', ...
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

    % Subplot label
    labels = 'abcdefgh';
    text(0.98, 0.02, ['(' labels(tile_num) ')'], 'Units', 'normalized', ...
        'HorizontalAlignment', 'right', 'VerticalAlignment', 'bottom', ...
        'FontSize', fontsz +10, 'Color', [0 0 0]);
end
