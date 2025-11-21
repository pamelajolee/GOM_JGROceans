%% Figure 6 - Four day of year averages: Eastern GoM (200m), MLD, DS, & Nitrate
% Using the same method as figure 5 to organize and calcuate the day of
% year averages, but plotting as timeseries with error bars of std.

clc;clear;close all;

% Add Paths and Load Data
addpath(genpath('/Users/pameladoran/Documents/Toolbox-19May2024'));
addpath(genpath('/Volumes/PamelaResearch/Luna_project/Fig6_TwoD_plots/'))
load /Users/pameladoran/HardDrive/MATLAB/USC/LCFE/GoM_data/mat_files/HYCOM_MLD.mat
load /Users/pameladoran/HardDrive/MATLAB/USC/LCFE/GoM_data/mat_files/LC_values_all.mat
load /Users/pameladoran/HardDrive/MATLAB/USC/LCFE/GoM_data/mat_files/discharge_ts.mat
load /Users/pameladoran/HardDrive/MATLAB/USC/LCFE/GoM_data/mat_files/MR_Nitrate_2018to2024.mat
load /Users/pameladoran/HardDrive/MATLAB/USC/LCFE/GoM_data/Colors/LCFE_colors.mat

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

% Detmined final days to use and chlor values
[final_dates, ia_chlor, ia_common] = intersect(chlor_dates, nitrate_dates);
final_chlor = east_chlor(ia_chlor);

% Match MLD to common dates
MLD_table = struct2table(MLD);
MLD_table.Time = MLD_table.date;
MLD_table.date = [];
mask_mld = MLD_table.Time >= nitrate_start & MLD_table.Time <= nitrate_end;
MLD_table = MLD_table(mask_mld, :);
[~, ia_mld] = ismember(final_dates, MLD_table.Time);
final_mld = MLD_table.mld(ia_mld);

% Make DOY variable (same for all four)
day_of_year = day(final_dates, 'dayofyear');

%%  Calcuate Loaded Nitrate - tons/day
loaded_nitrogen = nitrate_vals .* discharge_vals; % mg/L * m^3/s
loaded_nitrogen = loaded_nitrogen .* 1000;        % eliminate m^3/ L
loaded_nitrogen = loaded_nitrogen .* 86400;       % seconds to days
loaded_nitrogen = loaded_nitrogen ./ 1e9;         % mg to tons

%% Aggregate by Day of the Year and Save
[chlor_doy, chlor_mean, chlor_std] = aggregate_by_day_of_year(day_of_year, final_chlor, day_of_year);
[~, nitrate_mean, n_std] = aggregate_by_day_of_year(day_of_year, nitrate_vals, day_of_year);
[nitrate_doy, loading_mean, load_std] = aggregate_by_day_of_year(day_of_year, loaded_nitrogen, day_of_year);
[ds_doy, discharge_mean, discharge_std] = aggregate_by_day_of_year(day_of_year, discharge_vals, day_of_year);
[mld_doy, mld_mean, mld_std] = aggregate_by_day_of_year(day_of_year, final_mld, day_of_year);

save doy_averages.mat chlor_mean discharge_mean loading_mean loaded_nitrogen mld_mean nitrate_mean nitrate_doy

%% Plotting
figure('Position',[12 154 1634 1170]);
tiledlayout(2,2, 'TileSpacing','compact', 'Padding','loose');
fontsz = 20;


% TwoD_subplot(x, y, y_std, fontsz, tile_num, color, do_fit, xlab, ylab, show_xlabel, show_ylabel)

% (1) Top-left: Eastern GoM Chl-a
TwoD_subplot(chlor_doy, chlor_mean, chlor_std, ...
    fontsz, 1, magenta, false, ...
    'Day of the Year', 'Eastern GoM Chlorophyll-a (mg/m^{3})', ...
    true, true); 

% (2) Top-right: MLD
TwoD_subplot(mld_doy, mld_mean, mld_std, ...
    fontsz, 2, blue, false, ...
    'Day of the Year', 'Mean Mixed Layer Depth (m)', ...
    true, true);  

% (4) Bottom-right: Loaded Nitrate
TwoD_subplot(nitrate_doy, loading_mean, load_std, ...
    fontsz, 4, dgreen, false, ...
    'Day of the Year', 'Nitrogen Loading (ton/day)', ...
    true, true);  

% (3) Bottom-left: Nitrate
TwoD_subplot(nitrate_doy, nitrate_mean, n_std, ...
    fontsz, 3, purp, false, ...
    'Day of the Year', 'Nitrogen Concentration (mg/L)', ...
    true, true); 

%% Export
savepath = '/Volumes/PamelaResearch/Luna_project/Fig6_TwoD_plots/';
figname = [savepath 'Fig6_doy_std_loaded.tiff'];
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
        'Color', color, 'MarkerSize', 6, 'CapSize', 7, 'LineWidth', 1.5);
    plot(x, y, '.', 'Color', color, 'MarkerSize', 15);
    set(gca, 'FontSize', fontsz - 2, 'FontName' , 'TimesNewRoman', 'Box', 'on')


    if do_fit
        p = polyfit(x, y, 1);
        x_fit = linspace(min(x), max(x), 100);
        y_fit = polyval(p, x_fit);
        plot(x_fit, y_fit, '-', 'Color', 'k', 'LineWidth', 2);

        R = corrcoef(x, y, 'Rows','complete');
        r = R(1,2);
        eqn_str = sprintf('y = %.2fx + %.2f\nr = %.2f', p(1), p(2), r);
        text(0.8, 0.9, eqn_str, 'Units', 'normalized', ...
            'FontSize', fontsz-2, 'BackgroundColor','w');
    end

    if show_xlabel
        xlabel(xlab, 'FontSize', fontsz+4);
    else
        xticklabels([]);
    end

    if show_ylabel
        ylabel(ylab, 'FontSize', fontsz+4);
    else
        yticklabels([]);
    end

    grid on;
    xlim([0 366])
    % ylim([min(y) max(y)])

     % Subplot letter
    labels = 'abcdefgh';
    text(0.98, 0.02, ['(' labels(tile_num) ')'], 'Units', 'normalized', ...
        'HorizontalAlignment', 'right', 'VerticalAlignment', 'bottom', ...
        'FontSize', fontsz +10, 'Color', [0 0 0]);
end
