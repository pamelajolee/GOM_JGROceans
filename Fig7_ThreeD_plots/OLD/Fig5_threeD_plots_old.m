%% Different variables against chl-a inside each eddy region

clear;
close all;
clc;
addpath(genpath('/Users/pameladoran/Documents/Toolbox-19May2024'));
load('/Volumes/PamelaResearch/Luna_project/GoM_data/LCFE_values_all.mat');
load('/Volumes/PamelaResearch/Luna_project/GoM_data/LC_values_all.mat');
load('/Volumes/PamelaResearch/Ricky_Project/GOM-GRL/Fig_1/discharge_ts.mat')

LC_table = struct2table(LC_values);
LCFE_table = struct2table(LCFE_values);
dates = [LCFE_values.date]';

river_table = table(DT, miss_ds, atch_ds); %(date, MR discharge, Atch river Discharge)

river_true = ismember(DT, dates);  % Finds matching datetimes (2/9/2018 to 12/31/23)

DT_matched = DT(river_true, :);  % Keep only matching rows

%% Keep only matching dates
dates_true = ismember(dates, DT_matched); %2402x1 logical
dates_matched = dates(dates_true, :); % 2151x1 datetime
LCFE_table = LCFE_table(dates_true, :); % 2151x15 table
LC_table = LC_table(dates_true, :); % 2151x5 table
river_table = river_table(dates_true, :); %(2151x3 table)

%% Extract from tables, remove NaNs and find indicies

max_LC = table2array(LC_table(:,"max_LC")); % first row y value
day_of_year = day(dates_matched, 'dayofyear'); % Second row y value
total_ds = river_table.atch_ds + river_table.miss_ds; % Third y value
total_ds = total_ds./1000; % Colorbar needs to have (x10^4)

% First column of plots - WFCE
WFCE_chlor = table2array(LCFE_table(:,"chlorIN_WFCE")); 
WFCE_lat = table2array(LCFE_table(:,"max_WFCE_lat"));
WFCE_idx = find(~isnan(WFCE_chlor)); 

WFCE_chlor = WFCE_chlor(WFCE_idx); 
WFCE_lat = WFCE_lat(WFCE_idx);

WFCE_max_LC_lat = max_LC(WFCE_idx);
WFCE_day_of_year = day_of_year(WFCE_idx);
WFCE_river = total_ds(WFCE_idx);

% Second Column of Plots - CBCE
CBCE_chlor = table2array(LCFE_table(:,"chlorIN_CBCE")); 
CBCE_lat = table2array(LCFE_table(:,"max_CBCE_lat"));
CBCE_idx = find(~isnan(CBCE_chlor)); 

CBCE_chlor = CBCE_chlor(CBCE_idx); 
CBCE_lat = CBCE_lat(CBCE_idx);

CBCE_max_LC_lat = max_LC(CBCE_idx);
CBCE_day_of_year = day_of_year(CBCE_idx);
CBCE_river = total_ds(CBCE_idx);

% Third Column of plots - NCE
NCE_chlor = table2array(LCFE_table(:,"chlorIN_NCE")); 
NCE_lat = table2array(LCFE_table(:,"max_NCE_lat"));
NCE_idx = find(~isnan(NCE_chlor)); 

NCE_chlor = NCE_chlor(NCE_idx);  
NCE_lat = NCE_lat(NCE_idx);

NCE_max_LC_lat = max_LC(NCE_idx);
NCE_day_of_year = day_of_year(NCE_idx);
NCE_river = total_ds(NCE_idx);

% First Column  - All LCFEs

%% Make figure - 3D plots
addpath(genpath('/Volumes/PamelaResearch/Matlab_Codes/LCFE/Functions/'))
load('LCFE_colors.mat')
%colors = {teal, cab, gold};
figure('Units','normalized','OuterPosition',[0 0.05 0.75 0.85]);
tiledlayout(2,3, 'TileSpacing','compact', 'Padding','loose');
fontsz = 26;

% WFCE Max lat
threeD_subplot(WFCE_lat, WFCE_chlor,WFCE_river, 'WFCE', fontsz, 1)

% CBCE Max Lat
threeD_subplot(CBCE_lat, CBCE_chlor,CBCE_river, 'CBCE', fontsz, 2)

% NCE Max Lat
threeD_subplot(NCE_lat, NCE_chlor,NCE_river, 'NCE', fontsz, 3)

% WFCE day of year
threeD_subplot(WFCE_day_of_year, WFCE_chlor, WFCE_river, 'WFCE', fontsz, 4)

% CBCE day of year
threeD_subplot(CBCE_day_of_year, CBCE_chlor,CBCE_river, 'CBCE', fontsz, 5)

% NCE day of year
threeD_subplot(NCE_day_of_year, NCE_chlor,NCE_river, 'NCE', fontsz, 6)


% Common Colorbar
% Colorbar with labels and font
cb = colorbar;
set(cb, 'Position', [0.96 0.08 0.005 0.85]);
cb.Label.String = 'River Discharge (x10^4 m^3/s)';
cb.Label.FontSize = fontsz;
cb.FontName = 'Times New Roman';
grid on


% Save the Figure
savepath =  '/Volumes/PamelaResearch/Luna_project/Fig5_ThreeD_plots/';
figname = [savepath 'Fig5_ThreeD_plots.tiff'];
set(gcf, 'InvertHardcopy', 'off');
exportgraphics(gcf, figname, 'BackgroundColor', 'none');

disp('Finished');


function threeD_subplot(x_raw, y_raw,z_raw, region_title, fontsz, tile_num)
    nexttile(tile_num);

    scatter(x_raw,y_raw,[],z_raw,'filled')
    colormap(gca, summer(100))
    clim([0 60])
    set(gca, 'Box', 'on','YGrid', 'on', 'GridLineWidth', 2)

       % X-Lables on only the bottom row
    if ismember(tile_num, [1 2 3])
     xlabel('Max LCFE Latitude', 'FontSize', fontsz - 6);
     xlim([23 29])
    end
    
   
    % X-Lables on only the bottom row
    if ismember(tile_num, [4 5 6])
     xlabel('Day of the Year', 'FontSize', fontsz - 6);
     xlim([0 400])
     patch([121 304 304 121], [0 0 0.6 0.6], 'k', 'FaceAlpha', 0.05, 'EdgeColor', 'k', 'LineWidth', 1); 
     % May 1st to Oct 31st

    end
    
    % Show ylabel only for first column
    if ismember(tile_num, [1 4])
        ylabel('Chlorophyll-a in LCFE (mg/m^3)', 'FontSize', fontsz);
    else
        %yticks([]);
        %yticklabels([]);
    end
    
    % Titles for only top row
    if ismember(tile_num, [1 2 3])
     title(region_title, 'FontWeight', 'bold', 'FontSize', fontsz);
    end

    set(gca, 'FontSize', fontsz - 6)
        
   
    % Add letter to corresponding subplot
    letters = 'abcdefghi';
    letter_label = ['(' letters(tile_num) ')'];
    
    text(0.95, 0.02, letter_label, 'Units', 'normalized', ...
        'HorizontalAlignment', 'right', 'VerticalAlignment', 'bottom', ...
         'FontSize', fontsz + 4, 'Color', [0 0 0 0.7]);
    set(gca, 'Box', 'on','YGrid', 'on','XGrid', 'on', 'GridLineWidth', 2)
    %ylim([0 0.5])

end

