%% Figure 5 - Four 3D scatter plots that show Chl-a for LCFE vs. Day of the Year
% X variables are Day of the year that each eddy appears, Y variables are
% chlorophyll values for when eddies appear

clear;clc;close all;

% Load data from GoM folder
addpath(genpath('/Users/pameladoran/Documents/Toolbox-19May2024'));
addpath(genpath('/Volumes/PamelaResearch/Luna_project/Fig5_ThreeD_plots/'));
load('/Volumes/PamelaResearch/Luna_project/GoM_data/mat_files/LCFE_values_all.mat');
load('/Volumes/PamelaResearch/Luna_project/GoM_data/mat_files/LC_values_all_200m.mat');
load('/Volumes/PamelaResearch/Luna_project/GoM_data/mat_files/LCFE_chlor_500m.mat')
load('/Volumes/PamelaResearch/Luna_project/GoM_data/mat_files/discharge_ts.mat')

%% Organize Tables
river_table = table(DT, miss_ds, atch_ds);
LCFE_table = struct2table(LCFE_values);
total_table = struct2table(total_LCFE);
LC_table = struct2table(LC_values); % has all DINEOF dates from 2018 to 2024
LC_dates = [LCFE_values.date]';
LCFE_dates = [total_LCFE.date]';

% Crop the dates of River discharge to match eddy dates
total_ds = (river_table.atch_ds + river_table.miss_ds) ./ 1000; % in 10^4 m3/s
river_true = ismember(DT, LCFE_dates);
river_dates = DT(river_true, :); 
river_day = day(river_dates, 'dayofyear'); % X-value
total_ds_all = total_ds(river_true); % Y-value

% Remove NaNs from total_table
chlor_true = ~isnan(total_table.chlorIN_LCFE);
total_dates = LCFE_dates(chlor_true);
total_day = day(total_dates, 'dayofyear'); % X-value
LCFE_chlor = total_table.chlorIN_LCFE(chlor_true); % Use as Y value

% Remove NaNs from WFCE
chlor_true = ~isnan(LCFE_table.chlorIN_WFCE);
WFCE_dates = LCFE_dates(chlor_true); 
WFCE_day = day(WFCE_dates, 'dayofyear'); % X-value
WFCE_chlor = LCFE_table.chlorIN_WFCE(chlor_true); % Use as Y value

% Remove NaNs from CBCE
chlor_true = ~isnan(LCFE_table.chlorIN_CBCE);
CBCE_dates = LCFE_dates(chlor_true);
CBCE_day = day(CBCE_dates, "dayofyear"); % X-value
CBCE_chlor = LCFE_table.chlorIN_CBCE(chlor_true);% Use as Y value

% Remove NaNs from NCE
chlor_true = ~isnan(LCFE_table.chlorIN_NCE);
NCE_dates = LCFE_dates(chlor_true);
NCE_day = day(NCE_dates, 'dayofyear'); % X-Value
NCE_chlor = LCFE_table.chlorIN_NCE(chlor_true); % Use as Y value

%% Aggregate by day so dates match up
[total_river_day, total_ds_mean, total_ds_std] = aggregate_by_day_of_year(river_day, total_ds_all, river_day); %365
[total_chlor_day, total_chlor_mean, total_chlor_std] = aggregate_by_day_of_year(total_day, LCFE_chlor, total_day); %365
[WFCE_chlor_day, WFCE_mean, WFCE_std] = aggregate_by_day_of_year(WFCE_day, WFCE_chlor, WFCE_day); %232
[CBCE_chlor_day, CBCE_mean, CBCE_std] = aggregate_by_day_of_year(CBCE_day, CBCE_chlor, CBCE_day); %208
[NCE_chlor_day, NCE_mean, NCE_std] = aggregate_by_day_of_year(NCE_day, NCE_chlor, NCE_day); %261

%% Interpolate river discharge to match with only eddy days
% e.g. interp DS to that the first value for WFCE_interp_ds is the same value found on day 40
WFCE_interp_ds = interp1(total_river_day, total_ds_mean, WFCE_chlor_day); 
CBCE_interp_ds = interp1(total_river_day, total_ds_mean, CBCE_chlor_day);
NCE_interp_ds = interp1(total_river_day, total_ds_mean, NCE_chlor_day);

%% Plotting - All Chl-a vs. DOY w/ River Dis. as color
figure('Position',[12 154 1634 1170]);
tiledlayout(2,2, 'TileSpacing','compact', 'Padding','loose');
fontsz = 20;

% Tile 1 - Total Chlor 
threeD_subplot(total_chlor_day, total_chlor_mean, total_chlor_std, total_ds_mean, 'TOTAL', fontsz, 1)

% Tile 2 - WFCE
threeD_subplot(WFCE_chlor_day, WFCE_mean, WFCE_std, WFCE_interp_ds, 'WFCE', fontsz, 2)

% Tile 3 = CBCE
threeD_subplot(CBCE_chlor_day, CBCE_mean, CBCE_std, CBCE_interp_ds, 'CBCE', fontsz, 3)

% Tile 4 - NCE
threeD_subplot(NCE_chlor_day, NCE_mean, NCE_std, NCE_interp_ds, 'NCE', fontsz, 4)

% Common Colorbar 
cb = colorbar;
set(cb, 'Position', [0.945 0.086 0.008 0.84])
cb.Label.String = 'River Discharge (x10^4 m^3/s)';
cb.Label.FontSize = fontsz+2;

% Save figure 
savepath =  '/Volumes/PamelaResearch/Luna_project/Fig5_ThreeD_plots/';
figname = fullfile(savepath, 'Fig5_LCFE_chlor_vs_doy.tiff');
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

function threeD_subplot(x_raw, y_raw, y_std, z_raw, region_title, fontsz, tile_num)
    nexttile(tile_num);

    % Show error bars every 15th point
    spacing = 15;
    idx = 1:spacing:length(x_raw);
    errorbar(x_raw(idx), y_raw(idx), y_std(idx), 'o', ...
        'MarkerFaceColor', 'k', ...
        'Color', 'k', 'MarkerSize', 6, 'CapSize', 7, 'LineWidth', 1.5);

    hold on;
    x_raw = smoothdata(x_raw, 'gaussian');
    scatter(x_raw,y_raw,[],z_raw,'filled')
    colormap(gca, summer(100))
    clim([0 60])
    set(gca, 'Box', 'on','YGrid', 'on', 'GridLineWidth', 2)
    set(gca, 'FontSize', fontsz - 2, 'FontName' , 'TimesNewRoman')
   
    % X-Lables on only the bottom row
    if ismember(tile_num, [3 4])
     xlabel('Day of the Year', 'FontSize', fontsz+4);

    end
    
    % Show ylabel only for first column
    if ismember(tile_num, [1 3])
        ylabel('Chlorophyll-a in LCFE (mg/m^3)', 'FontSize', fontsz+2);
    else
        %yticks([]);
        %yticklabels([]);
    end
    
    % Rgion Titles - Upper left corner
     text(0.02, 0.95, region_title, 'Units', 'normalized', ...
         'HorizontalAlignment', 'left', 'VerticalAlignment', 'top', ...
         'FontSize', fontsz +8, 'Color', 'k')

     % Number of samples - upper right corner
     text(0.84, 0.95, ['n = ', num2str(length(x_raw))], 'Units', 'normalized', ...
         'HorizontalAlignment','left', 'VerticalAlignment', 'top', ...
         'FontSize', fontsz + 8, 'Color', 'k')

    xlim([0 366])
    patch([121 304 304 121], [0 0 0.6 0.6], 'k', 'FaceAlpha', 0.05, 'EdgeColor', 'k', 'LineWidth', 1); 
    % May 1st to Oct 31st
        
   
    % Add letter to corresponding subplot
    letters = 'abcdefghi';
    letter_label = ['(' letters(tile_num) ')'];
    
    text(0.95, 0.02, letter_label, 'Units', 'normalized', ...
        'HorizontalAlignment', 'right', 'VerticalAlignment', 'bottom', ...
         'FontSize', fontsz + 10, 'Color', [0 0 0 0.7]);
    set(gca, 'Box', 'on','YGrid', 'on','XGrid', 'on', 'GridLineWidth', 2)
    ylim([0 0.4])

end