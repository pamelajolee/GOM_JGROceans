%% Fifth figure for JGR Ocean Paper
% making four timeseries in one plot that has number of LCFE and max lat of
% Loop Current (bar and line plot), then size of LCFE, avgerage chlorphyll
% inside that eddy and average chlorophyll on the boarder of the eddy for
% each of the three frontal eddy regions
clear;
clc;
close all;
addpath(genpath('/Users/pameladoran/Documents/Toolbox-19May2024'));
addpath(genpath('/Volumes/PamelaResearch/Luna_project/GoM_data/Functions/'))
addpath(genpath('/Volumes/PamelaResearch/Luna_project/Fig3_LCFE_timeseries/'))
savepath = '/Volumes/PamelaResearch/Luna_project/Fig3_LCFE_timeseries/'; %Figures

%% Load the LC_values struct that contains the three needed variables
load('/Volumes/PamelaResearch/Luna_project/GoM_data/mat_files/LC_values_all.mat');
load('/Volumes/PamelaResearch/Luna_project/GoM_data/mat_files/LCFE_values_all.mat');
load('LCFE_colors.mat'); %Same as Figure 1

%% Reasign variables for easy reading and smoothing
dates = [LC_values.date];
max_LC = [LC_values.max_LC];max_LC = smoothdata(max_LC, 'gaussian');
num_LCFE = [LCFE_values.num_LCFE];num_LCFE = smoothdata(num_LCFE, 'gaussian');
size_WFCE = [LCFE_values.size_WFCE];size_WFCE = smoothdata(size_WFCE, 'gaussian');
size_CBCE = [LCFE_values.size_CBCE];size_CBCE = smoothdata(size_CBCE, 'gaussian');
size_NCE = [LCFE_values.size_NCE];size_NCE = smoothdata(size_NCE, 'gaussian');
chlorON_WFCE = [LCFE_values.chlorON_WFCE];chlorON_WFCE = smoothdata(chlorON_WFCE);
chlorON_CBCE = [LCFE_values.chlorON_CBCE];chlorON_CBCE = smoothdata(chlorON_CBCE, 'gaussian');
chlorON_NCE = [LCFE_values.chlorON_NCE];chlorON_NCE = smoothdata(chlorON_NCE, 'gaussian');
chlorIN_WFCE = [LCFE_values.chlorIN_WFCE];chlorIN_WFCE = smoothdata(chlorIN_WFCE, 'gaussian');
chlorIN_CBCE = [LCFE_values.chlorIN_CBCE];chlorIN_CBCE = smoothdata(chlorIN_CBCE, 'gaussian');
chlorIN_NCE = [LCFE_values.chlorIN_NCE];chlorIN_NCE = smoothdata(chlorIN_NCE, 'gaussian');
max_LCFE_lat = [LCFE_values.max_LCFE_lat]; max_LCFE_lat = smoothdata(max_LCFE_lat, 'gaussian');

%% Making the plots
 
clf
figure(1)
t = tiledlayout(4,1);
t.TileSpacing = 'tight';
t.Padding = 'compact';
set(gcf, 'Units', 'inches', 'Position', [1 1 30 24]) % 30x24 inches

%% MAX LC and Number of LCFE
nexttile;
ax1 = gca;

yyaxis('left')
plot(dates, max_LC, 'LineWidth', 3, 'Color', purp); 
hold on;
plot(dates, max_LCFE_lat, 'LineWidth', 3, 'Color', blue, 'LineStyle', '-')
set(gca, 'ycolor', 'k')
ylim([23 30]); 
set(ax1, 'Fontsize', 12, 'LineWidth', 3)
ylabel('Latitude (^{\circ}N)', 'FontSize', 24, 'Color', 'k', 'FontName', 'Times New Roman'); 
hold on;
yyaxis('right')
plot(dates, num_LCFE, 'LineWidth', 3, 'Color', orange); 
set(gca, 'ycolor', orange);
ylabel('Number of LCFEs', 'FontSize', 24, 'Color', 'k', 'FontName', 'Times New Roman'); 
%yline(0, 'Color', blue, 'LineStyle', '--')
ylim([-0.5 3.5]); 
hold off;
l1 = legend(ax1, 'Max LC Lat', 'Max LCFE Lat','Number of LCFEs' , fontsize = 20, fontname = 'Times New Roman');
l1.Location = "northeast";
ax1.XMinorTick = 'on';
ax1.XTickLabel = [];
set(ax1, "FontSize", 24)
grid on;
box on;
text(ax1, min(xlim + 0.04 ), min(ylim +0.01), '(a)', 'FontSize', 26, 'HorizontalAlignment','left', 'VerticalAlignment', 'bottom');

%% Size 

nexttile;
ax2 = gca;

plot(dates, size_WFCE, 'LineWidth', 3, 'Color', teal);

set(ax2, 'Fontsize', 12, 'LineWidth', 3)
ylabel('Radius (km)', 'FontSize', 24, 'Color', 'k', 'FontName', 'Times New Roman'); 
hold on;
plot(dates, size_CBCE, 'LineWidth', 3, 'Color', brown); 
 
hold on; 
plot(dates, size_NCE, 'LineWidth', 3, 'Color', gold);


hold off;
l2 = legend(ax2, 'WFCE', 'CBCE', 'NCE' , fontsize = 20, fontname = 'Times New Roman');
l2.Location = "northeast";
ax2.XMinorTick = 'on';
ax2.XTickLabel = [];
set(ax2, "FontSize", 24)
grid on;
box on;
text(ax2, min(xlim + 0.04 ), min(ylim +0.01), '(b)', 'FontSize', 26, 'HorizontalAlignment','left', 'VerticalAlignment', 'bottom');

%% Chloronphyll ON

nexttile;
ax3 = gca;

plot(dates, chlorON_WFCE, 'LineWidth', 3, 'Color', teal);

set(ax3, 'Fontsize', 12, 'LineWidth', 3)
ylabel('Chl-a Around (mg/m^3)', 'FontSize', 24, 'Color', 'k', 'FontName', 'Times New Roman'); 
hold on;
plot(dates, chlorON_CBCE, 'LineWidth', 3, 'Color', brown); 
 
hold on; 
plot(dates, chlorON_NCE, 'LineWidth', 3, 'Color', gold);

hold off;
l3 = legend(ax3, 'WFCE', 'CBCE', 'NCE' , fontsize = 20, fontname = 'Times New Roman');
l3.Location = "northeast";
ax3.XMinorTick = 'on';
ax3.XTickLabel = [];
set(ax3, "FontSize", 24)
grid on;
box on;
text(ax3, min(xlim + 0.04 ), min(ylim +0.01), '(c)', 'FontSize', 26, 'HorizontalAlignment','left', 'VerticalAlignment', 'bottom');

%% Chlorophyll IN

nexttile;
ax4 = gca;

plot(dates, chlorIN_WFCE, 'LineWidth', 3, 'Color', teal);

set(ax4, 'Fontsize', 12, 'LineWidth', 3)
ylabel('Chl-a Inside (mg/m^3)', 'FontSize', 24, 'Color', 'k', 'FontName', 'Times New Roman'); 
hold on;
plot(dates, chlorIN_CBCE, 'LineWidth', 3, 'Color', brown); 

hold on; 
plot(dates, chlorIN_NCE, 'LineWidth', 3, 'Color', gold);

hold off;
l4 = legend(ax4, 'WFCE', 'CBCE', 'NCE' , fontsize = 20, fontname = 'Times New Roman');
l4.Location = "northeast";
years = year(dates);
ax4.XMinorTick = 'on';
grid on;
set(ax4, "FontSize", 24 )
box on;
text(ax4, min(xlim + 0.04 ), min(ylim +0.01), '(d)', 'FontSize', 26, 'HorizontalAlignment','left', 'VerticalAlignment', 'bottom');

%% Final plot specs and save

figname = ([savepath, 'Fig3_LCFE_values_4by1Timeseries.tiff']);
set(gcf, 'InvertHardcopy', 'off')
exportgraphics(gcf, figname, 'BackGroundColor', 'none'); 

disp('Finished');

