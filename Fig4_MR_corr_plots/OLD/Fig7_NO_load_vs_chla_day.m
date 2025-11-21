%% Figure 7 of JGR Oceans Paper
% finding correlations: seaonsal chlor vs. Loaded nitrate and seasonal
% chlor vs. MLD

clc; clear; close all;
addpath(genpath('/Users/pameladoran/Documents/Toolbox-19May2024'));
addpath(genpath('/Volumes/PamelaResearch/Luna_project/Fig7_MR_corr_plots/'))

% Load needed variables - no days with Nans values were saved, but some 
% sets are missing days instead
load('/Volumes/PamelaResearch/Luna_project/GoM_data/mat_files/HYCOM_MLD.mat');
load('/Volumes/PamelaResearch/Luna_project/GoM_data/mat_files/LC_values_all_200m.mat'); 
load('/Volumes/PamelaResearch/Luna_project/GoM_data/mat_files/discharge_ts.mat');       
load('/Volumes/PamelaResearch/Luna_project/GoM_data/mat_files/MR_Nitrate_2018to2024.mat'); 
load('LCFE_colors.mat');

%% Allign all day to matching from 2018 to 2024
% Remove timezones
Nitrate_TT.Time.TimeZone = '';
DT.TimeZone = '';
for i = 1:numel(MLD)
    MLD(i).date.TimeZone = '';
end

%% Convert nitrate to normal table
nitrate_table = timetable2table(Nitrate_TT);
nitrate_table.Properties.VariableNames = {'Time', 'Nitrate_mgL'};

% Only keep dates within common range (2018–2023) - nitrate has 2024
nitrate_start = datetime(2018,1,1);
nitrate_end = datetime(2023,12,31);
mask_nitrate = nitrate_table.Time >= nitrate_start & nitrate_table.Time <= nitrate_end;
nitrate_table = nitrate_table(mask_nitrate, :);

% Match discharge to same days
mask_discharge = DT >= nitrate_start & DT <= nitrate_end;
DT_sub = DT(mask_discharge);
discharge_sub = miss_ds(mask_discharge); % in m^3/s

% Intersect the dates so that they both match
[common_dates, ia_nitrate, ia_discharge] = intersect(nitrate_table.Time, DT_sub);

% Matched values
nitrate_vals = nitrate_table.Nitrate_mgL(ia_nitrate);         
discharge_vals = discharge_sub(ia_discharge);                
nitrate_dates = common_dates;

% Load east_chlor from LC_values
LC_table = struct2table(LC_values);
LC_dates = [LC_values.date]';

% match chl-a values to common_dates
mask_chlor = LC_dates >= nitrate_start & LC_dates <= nitrate_end;
east_chlor = LC_table.east_chlor(mask_chlor);
chlor_dates = LC_dates(mask_chlor);

%% Two-stage lag calculations
years = 2018:2023;
maxLag = 120; % ~ 4 months

% Match Nitrate to Discharge
lags_d2n = nan(length(years),1);
for i = 1:length(years)
    yr = years(i);
    idx = year(nitrate_dates) == yr;
    d = discharge_vals(idx);
    n = nitrate_vals(idx);

    % Ensure zero-mean signals
    d = d - mean(d);
    n = n - mean(n);

    % Cross-correlation: d leads n if lag > 0
    [acor, lag] = xcorr(d, n, maxLag, 'coeff');
    [~, I] = max(acor);
    lags_d2n(i) = lag(I);

    % Plot for inspection
    figure;
    plot(lag, acor, '-o');
    xlabel('Lag (days)'); ylabel('Correlation');
    title(sprintf('Discharge vs Nitrate Lag (Year %d)', yr));
    grid on;

    fprintf('Year %d: D → N lag = %d days\n', yr, lags_d2n(i));
end

% Compute average lag (positive lags only)
valid_d2n = lags_d2n >= 0;
avg_lag_d2n = round(mean(lags_d2n(valid_d2n), 'omitnan'));
fprintf('Average Discharge → Nitrate lag = %d days\n', avg_lag_d2n);


% Apply lag to nitrate based on sign of avg_lag_d2n
nitrate_shifted = nan(size(nitrate_vals));

if avg_lag_d2n > 0
    % Nitrate lags discharge → shift nitrate forward (later)
    nitrate_shifted((avg_lag_d2n+1):end) = nitrate_vals(1:end-avg_lag_d2n);
elseif avg_lag_d2n < 0
    % Nitrate leads discharge → shift nitrate backward (earlier)
    nitrate_shifted(1:end+avg_lag_d2n) = nitrate_vals((-avg_lag_d2n+1):end);
else
    % No lag
    nitrate_shifted = nitrate_vals;
end

% Recalculate loaded nitrate (shifted nitrate * discharge)
loaded_nitrate_shifted = nitrate_shifted .* discharge_vals * 86400 / 1e6;  % kg/day

% Align with chlorophyll
[final_dates, ia_chlor, ia_common] = intersect(chlor_dates, nitrate_dates);
final_chlor = east_chlor(ia_chlor);
final_discharge = discharge_vals(ia_common);
final_loaded_nitrate = loaded_nitrate_shifted(ia_common) ./ 1000;          %tonnes/day
final_nitrate = nitrate_shifted(ia_common);
final_dates = final_dates;

% Match Chlorophyll to Nitrate
lags_n2c = nan(length(years),1);
for i = 1:length(years)
    yr = years(i);
    idx = year(final_dates) == yr;
    n = final_loaded_nitrate(idx);
    c = final_chlor(idx);
    valid = ~isnan(n) & ~isnan(c);
    if sum(valid) < 10, continue; end
    n = n(valid) - mean(n(valid));
    c = c(valid) - mean(c(valid));
    [acor, lag] = xcorr(n, c, maxLag, 'coeff');
    [~, I] = max(acor);
    lags_n2c(i) = lag(I);
    fprintf('Year %d: Loaded Nitrate → Chlorophyll lag = %d days\n', yr, lags_n2c(i));
end
valid_n2c = lags_n2c >= 0;
avg_lag_n2c = round(mean(lags_n2c(valid_n2c), 'omitnan'));
fprintf('Average Loaded Nitrate → Chlorophyll lag = %d days\n', avg_lag_n2c);

% Apply lag to chlorophyll based on sign of avg_lag_n2c
final_loaded_nitrate_lagged = nan(size(final_loaded_nitrate));

if avg_lag_n2c > 0
    % Chlorophyll lags nitrate → shift nitrate forward (later)
    final_loaded_nitrate_lagged((avg_lag_n2c+1):end) = final_loaded_nitrate(1:end-avg_lag_n2c);
elseif avg_lag_n2c < 0
    % Chlorophyll leads nitrate → shift nitrate backward (earlier)
    final_loaded_nitrate_lagged(1:end+avg_lag_n2c) = final_loaded_nitrate((-avg_lag_n2c+1):end);
else
    % No lag
    final_loaded_nitrate_lagged = final_loaded_nitrate;
end


% DOY
chlor_doy = day(final_dates, 'dayofyear');
nitrate_doy = chlor_doy;
discharge_doy = chlor_doy;

% Align MLD to final_dates
MLD_table = struct2table(MLD);
MLD_table.Time = MLD_table.date;
MLD_table.date = [];
mask_mld = MLD_table.Time >= nitrate_start & MLD_table.Time <= nitrate_end;
MLD_table = MLD_table(mask_mld, :);
[~, ia_mld] = ismember(final_dates, MLD_table.Time);
final_mld = MLD_table.mld(ia_mld);
mld_doy = day(final_dates, 'dayofyear');

%% Aggregate by DOY (lagged nitrate)
[total_chlor_doy, chlor_mean, chlor_std] = aggregate_by_day_of_year(chlor_doy, final_chlor, chlor_doy);
[total_nitrate_doy, nitrate_mean_lagged, n_std] = aggregate_by_day_of_year(chlor_doy, final_loaded_nitrate_lagged, chlor_doy);
[total_ds_doy, discharge_mean, discharge_std] = aggregate_by_day_of_year(discharge_doy, final_discharge / 10000, discharge_doy);
[~, mld_mean, ~] = aggregate_by_day_of_year(mld_doy, final_mld, mld_doy);

%% Group by Season - matching start and end days to Fig 1 results

day_start = 130;
day_end = 250;
chlor_summer = chlor_mean(day_start:day_end, :); 
nitrate_summer = nitrate_mean_lagged(day_start:day_end, :);

chlor_winter1 = chlor_mean(1:day_start -1, :);
chlor_winter2 = chlor_mean(day_end +1:365, :);
chlor_winter = cat(1, chlor_winter1, chlor_winter2);

n_winter1 = nitrate_mean_lagged(1:day_start -1, :);
n_winter2 = nitrate_mean_lagged(day_end +1:365, :);
nitrate_winter = cat(1, n_winter1, n_winter2);

mld_summer = mld_mean(day_start:day_end, :);
mld_winter1 = mld_mean(1:day_start-1, :);
mld_winter2 = mld_mean(day_end+1:365, :);
mld_winter = cat(1, mld_winter1, mld_winter2);

sum_chlor_std = chlor_std(day_start:day_end);   
win_chlor_std = [chlor_std(1:day_start-1); chlor_std(day_end+1:end)];

%% Plot 2x2 Layout
figure('Position', [412 152 1678 1130]);
tiledlayout(2,2, 'TileSpacing','compact', 'Padding','loose');
fontsz = 18;

% (1) Top Left: Chlorophyll vs. Nitrate (Summer) -- Using lagged nitrate
TwoD_subplot(nitrate_summer, chlor_summer, [], ...
    fontsz, 1, dgreen, true, ...
    'Loaded Nitrate (tonnes/day)', ... % X-label
    'Summer Surface Chlorophyll-a (mg/m^{3})', ... % Y-Label
    true, true); 

% (2) Top Right: Chlorophyll vs. MLD (Summer)
TwoD_subplot(mld_summer, chlor_summer, [], ...
    fontsz, 2, blue, true, ...
    'Mixed Layer Depth (m)', ...
    'Summer Surface Chlorophyll-a (mg/m^{3})', ...
    true, true); 

% (3) Bottom Left: Chlorophyll vs. Nitrate (Winter) -- Using lagged nitrate
TwoD_subplot(nitrate_winter, chlor_winter, [], ...
    fontsz, 3, dgreen, true, ...
    'Loaded Nitrate (tonnes/day)', ...
    'Winter Surface Chlorophyll-a (mg/m^{3})', ...
    true, true);  

% (4) Bottom Right: Chlorophyll vs. MLD (Winter)
TwoD_subplot(mld_winter, chlor_winter, [], ...
    fontsz, 4, blue, true, ...
    'Mixed Layer Depth (m)', ...
    'Winter Surface Chlorophyll-a (mg/m^{3})', ...
    true, true); 

%% Export
savepath = '/Volumes/PamelaResearch/Luna_project/Fig7_MR_corr_plots/';
figname = [savepath 'Fig7_MR_corr_plots_day.tiff'];
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
    if ~isempty(y_std)
        errorbar(x(idx), y(idx), y_std(idx), 'o', ...
            'MarkerFaceColor', color, ...
            'Color', color, 'MarkerSize', 5, 'CapSize', 4, 'LineWidth', 1.2);
    else
        plot(x(idx), y(idx), 'o', ...
            'MarkerFaceColor', color, ...
            'Color', color, 'MarkerSize', 5, 'LineWidth', 1.2);
    end

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

    ylim([0.1 0.25])
    set(gca, 'FontSize', fontsz , 'Box','on','LineWidth',1.2);
    grid on;
    % 
    % if ismember(tile_num, 1)
    %     xlim([1 3])
    % elseif ismember(tile_num, 3)
    %     xlim([0.5 3.5])
    % elseif ismember(tile_num, 2)
    %     xlim([5 25])
    % elseif ismember(tile_num, 4)
    %     xlim([10 70])
    % end

     % Subplot letter
    labels = 'abcdefgh';
    text(0.98, 0.02, ['(' labels(tile_num) ')'], 'Units', 'normalized', ...
        'HorizontalAlignment', 'right', 'VerticalAlignment', 'bottom', ...
        'FontSize', fontsz +10, 'Color', [0 0 0]);
end
