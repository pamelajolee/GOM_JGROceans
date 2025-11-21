%% First Figure for JGR Oceans Paper with map of LCFE regions - AGU quality

clear;
clc;
close all;
addpath(genpath('/Users/pameladoran/Documents/Toolbox-19May2024'));
addpath(genpath('/Volumes/PamelaResearch/Luna_project/Fig1_Region_map/'));
savepath = '/Volumes/PamelaResearch/Luna_project/Fig1_Region_map/'; 
load ('Green_map.mat');
load('LCFE_colors.mat');

year = 2018; month = 5; day = 21;


% Retrieve data
[lon_adt, lat_adt, adt_anom, adt_masked] = gom_adt(year, month, day);
[lon_chlor, lat_chlor, chlor_masked] = gom_dineof(year, month, day);

%% Make the Plot
figure(1)
set(gcf, 'Units', 'inches', 'Position', [1 1 7 5]) % 7x5 inches figure

% Plot and zoom on Gulf of Mexico
m_proj('mercator','longitude',[-92 -82],'latitude',[22 30]) 
load('coast');
hold on;

% Plot DINEOF Ocean color data
mask_chlor = find(chlor_masked > 0.25);  
chlor_masked(mask_chlor) = 0.25; 

m_contourf(lon_chlor, lat_chlor, chlor_masked, 'LineStyle', 'none')
shading interp;
clim([0.05 0.25])
colormap(Green_color);
hold on;

% Mask and contour lines
chlor_masked(lon_chlor <= -88) = NaN;
[C,h] = m_contour(lon_chlor, lat_chlor, chlor_masked,[0.07 0.07], 'Color', purp, 'LineWidth', 3);

adt_masked(lon_adt < -89.5) = NaN;
[C2,h2] = m_contour(lon_adt, lat_adt, adt_masked,[-0.28 -0.28], 'Color', blue, 'LineWidth', 3);
[C3,h3] = m_contour(lon_adt, lat_adt, adt_masked, [0.17 0.17], '-k', 'LineWidth', 3);

% % Land shading and grid
% m_gshhs_i('patch', [0.8 0.8 0.8]);
% m_grid('box', 'fancy', 'box', 'on', 'LineWidth', 2, 'FontSize', 14);

% Region boxes with colored edges and transparency
% m_patch([-92 -82 -82 -92], [26.5 26.5 30 30], gold, 'FaceAlpha', 0.15, 'EdgeColor', gold, 'LineWidth', 3); %NCE
% m_patch([-92 -86 -86 -92], [22 22 26.5 26.5], brown, 'FaceAlpha', 0.15, 'EdgeColor', brown, 'LineWidth', 3); % CBCE
% m_patch([-86 -82 -82 -86], [23 23 26.5 26.5], teal, 'FaceAlpha', 0.15, 'EdgeColor', teal, 'LineWidth', 3);% WFCE

m_patch([-92 -82 -82 -92], [26.5 26.5 30 30], gold, 'FaceAlpha', 0.25, 'LineWidth', 0.001); %NCE
m_patch([-92 -86 -86 -92], [22 22 26.5 26.5], brown, 'FaceAlpha', 0.25, 'LineWidth', 0.001); % CBCE
m_patch([-86 -82 -82 -86], [23 23 26.5 26.5], teal, 'FaceAlpha', 0.25, 'LineWidth', 0.001);% WFCE

% Add region labels
m_text(-85.3, 26, 'WFCE', 'FontSize', 18, 'FontWeight', 'bold', 'Color', teal);
m_text(-91, 24, 'CBCE', 'FontSize', 18, 'FontWeight', 'bold', 'Color', brown);
m_text(-84.5, 29, 'NCE', 'FontSize', 18, 'FontWeight', 'bold', 'Color', gold);

% Land shading and grid
m_gshhs_i('patch', [0.8 0.8 0.8]);
% Force grid with only odd latitudes
m_grid('box','fancy','LineWidth',2,'FontSize',14, ...
       'ytick',[23 25 27 29], ...        % odd latitudes
       'xtick',[-91 -89 -87 -85 -83]); 

% Set axis font and size
set(gca, 'FontName', 'Times New Roman', 'FontSize', 14);
set(gca, 'ColorScale', 'log');

% Colorbar with labels and font
cb = colorbar(gca, 'eastoutside');
cb.Label.String = 'Log(Chlorophyll-a (mg/m^3))';
cb.Label.FontSize = 16;
cb.FontName = 'Times New Roman';
cb.Ticks = [0.05 0.1 0.15 0.2 0.25];
cb.TickLabels = {'0.05', '0.1', '0.15', '0.2', '0.25'};

% Save high-res figure for submission
figname = fullfile(savepath, 'Fig1_Region_Map.tiff');
exportgraphics(gcf, figname, 'Resolution', 300, 'BackgroundColor', 'none');

disp('Finished')
