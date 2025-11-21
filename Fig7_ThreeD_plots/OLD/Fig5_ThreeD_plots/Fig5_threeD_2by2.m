%% Figure 5 - Four 3D scatter plots that show Chl-a for LCFE vs. Day of the Year
clear;clc;close all;

% Load data from GoM folder
addpath(genpath('/Users/pameladoran/Documents/Toolbox-19May2024'));
addpath(genpath('/Volumes/PamelaResearch/Luna_project/Fig5_ThreeD_plots/'));
load('/Volumes/PamelaResearch/Luna_project/GoM_data/LCFE_values_all.mat');
load('/Volumes/PamelaResearch/Luna_project/GoM_data/LC_values_all.mat');
load('/Volumes/PamelaResearch/Ricky_Project/GOM-GRL/Fig_1/discharge_ts.mat')

%% Organize Tables

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

% Extract variables 
total_ds = (river_table.atch_ds + river_table.miss_ds) ./ 1000; % in 10^4 m3/s
day_of_year = day(dates_matched, 'dayofyear');

WFCE_chlor = LCFE_table.chlorIN_WFCE;
CBCE_chlor = LCFE_table.chlorIN_CBCE;
NCE_chlor = LCFE_table.chlorIN_NCE;
chlor_all = nanmean([WFCE_chlor, CBCE_chlor, NCE_chlor], 2); % mean instead of sum

% Indices where combined chlorophyl is not Nan
all_idx = ~isnan(chlor_all);
chlor_all = chlor_all(all_idx);
total_ds_all = total_ds(all_idx);
day_of_year_all = day_of_year(all_idx);

% Group the combined mean LCFE by day of year 
[day_x_all, chlor_avg_all, chlor_std_all] = aggregate_by_day_of_year(day_of_year_all, chlor_all, day_of_year_all);
[day_x_all_ds, ds_avg_all, ds_std_all] = aggregate_by_day_of_year(day_of_year_all, total_ds_all, day_of_year_all);

% Prepare regional data and aggregate
regions = {
    'WFCE', 'chlorIN_WFCE', WFCE_chlor;
    'CBCE', 'chlorIN_CBCE', CBCE_chlor;
    'NCE',  'chlorIN_NCE',  NCE_chlor
};


agg_data = cell(3,1);
for i = 1:3
    chlor = regions{i,3};
    idx = ~isnan(chlor);
    chlor = chlor(idx);
    river = total_ds(idx);
    doy = day_of_year(idx);

    [r_avg, c_avg, c_std] = aggregate_by_day_of_year(river, chlor, doy);
    [day_x, r_doy_avg, r_doy_std] = aggregate_by_day_of_year(doy, river, doy);

    agg_data{i} = struct('region', regions{i,1}, ...
        'chlor_avg', c_avg, 'chlor_std', c_std, ...
        'river_avg', r_avg, ...
        'day_x', day_x, 'r_doy_avg', r_doy_avg, 'r_doy_std', r_doy_std);
end

%% Plotting - All Chl-a vs. DOY w/ River Dis. as color
figure('Position',[12 154 1634 1170]);
tiledlayout(2,2, 'TileSpacing','compact', 'Padding','loose');
fontsz = 20;

% Tile 1 - Total Chlor 
threeD_subplot(day_x_all, chlor_avg_all,chlor_std_all,ds_avg_all, 'TOTAL', fontsz, 1)

% Tile 2 - WFCE
threeD_subplot(agg_data{1,1}.day_x, agg_data{1,1}.chlor_avg, agg_data{1,1}.chlor_std, agg_data{1,1}.r_doy_avg, 'WFCE', fontsz, 2)

% Tile 3 = CBCE
threeD_subplot(agg_data{2,1}.day_x, agg_data{2,1}.chlor_avg, agg_data{2,1}.chlor_std, agg_data{2,1}.r_doy_avg, 'CBCE', fontsz, 3)

% Tile 4 - NCE
threeD_subplot(agg_data{3,1}.day_x, agg_data{3,1}.chlor_avg, agg_data{3,1}.chlor_std, agg_data{3,1}.r_doy_avg, 'NCE', fontsz, 4)

% Common Colorbar 
cb = colorbar;
set(cb, 'Position', [0.95 0.09 0.005 0.84]);
cb.Label.String = 'River Discharge (x10^4 m^3/s)';
cb.Label.FontSize = fontsz+2;

% Save figure 
savepath =  '/Volumes/PamelaResearch/Luna_project/Fig5_ThreeD_plots/';
figname = fullfile(savepath, 'Fig5_Mean_LCFE_2by2.tiff');
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

    % Show error bars every 10th point
    spacing = 15;
    idx = 1:spacing:length(x_raw);
    errorbar(x_raw(idx), y_raw(idx), y_std(idx), 'o', ...
        'MarkerFaceColor', 'k', ...
        'Color', 'k', 'MarkerSize', 5, 'CapSize', 5, 'LineWidth', 1);

    hold on;
    scatter(x_raw,y_raw,[],z_raw,'filled')
    colormap(gca, summer(100))
    clim([0 60])
    set(gca, 'Box', 'on','YGrid', 'on', 'GridLineWidth', 2)
    set(gca, 'FontSize', fontsz - 4)
   
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

    xlim([0 366])
    patch([121 304 304 121], [0 0 0.6 0.6], 'k', 'FaceAlpha', 0.05, 'EdgeColor', 'k', 'LineWidth', 1); 
    % May 1st to Oct 31st
        
   
    % Add letter to corresponding subplot
    letters = 'abcdefghi';
    letter_label = ['(' letters(tile_num) ')'];
    
    text(0.95, 0.02, letter_label, 'Units', 'normalized', ...
        'HorizontalAlignment', 'right', 'VerticalAlignment', 'bottom', ...
         'FontSize', fontsz + 4, 'Color', [0 0 0 0.7]);
    set(gca, 'Box', 'on','YGrid', 'on','XGrid', 'on', 'GridLineWidth', 2)
    ylim([0 0.4])

end