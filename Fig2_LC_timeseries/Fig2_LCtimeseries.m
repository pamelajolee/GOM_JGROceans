%% Timeseries of the chlorphyll values that are found on the LC
% First use "Max_LC_Lat_and_chlor.m" to determine the mean chlorophyll
% value of the Loo Current (not looking at LCEs) and load here to analyze
% six year timeseries


clear;
clc;
close all;
addpath(genpath('/Users/pameladoran/Documents/Toolbox-19May2024'));
addpath(genpath('/Volumes/PamelaResearch/Matlab_Codes/LCFE/Functions/'))
savepath = '/Volumes/PamelaResearch/Luna_project/Fig2_LC_timeseries/'; 

%% Load the LC_values struct that contains the three needed variables
load('/Volumes/PamelaResearch/Luna_project/GoM_data/mat_files/LC_values_all.mat');

% Reasign variables for easy reading and smoothing
dates = [LC_values.date];
max_LC = [LC_values.max_LC];
max_LC = smoothdata(max_LC, 'gaussian');
LC_chlor = [LC_values.LC_chlor];
LC_chlor = smoothdata(LC_chlor, 'gaussian');
avg_chlor = [LC_values.dw_chlor_avg];
avg_chlor = smoothdata(avg_chlor, 'gaussian');
years = datetime(2018,1,1):datetime(2024,12,31);

% Define colors
load('LCFE_colors.mat');

% Make the timeseries
figure(1);
set(gcf, 'Units', 'inches', 'Position', [1 1 30 6]) % 30x6 inches

yyaxis('left')
h1 = plot(dates, LC_chlor, 'LineWidth', 3, 'Color', dgreen); 
set(gca, 'ycolor', 'k')
hold on
h3 = plot(dates, avg_chlor, "LineWidth", 3, 'Color', magenta, 'LineStyle', '-');
set(gca, 'Fontsize', 12, 'LineWidth', 3)
ylabel('LC Chlorophyll (mg/m^3)', 'FontSize', 22, 'Color', 'k', 'FontName', 'Times New Roman'); 
hold on;
yyaxis('right')
h2 = plot(dates, max_LC, 'LineWidth', 3, 'Color', purp); 
set(gca, 'ycolor', purp);
ylabel('Latitude (^{\circ}N)', 'FontSize', 22, 'Color', purp, 'FontName', 'Times New Roman'); 

hold off;
l1 = legend(gca, 'LC Chl-a', 'GoM DW Chl-a', 'LC Latitude' , fontsize = 22, fontname = 'Times New Roman');
set(l1, 'Location', 'northeast')
ax1 = gca;
years = year(dates);
ax1.XMinorTick = 'on';
ax1.FontSize = 24;
grid on;
box on;


%% Final plot specs and save

figname = ([savepath 'Fig2_LC_timeseries.tiff']);
set(gcf, 'InvertHardcopy', 'off')
exportgraphics(gcf, figname, 'BackGroundColor', 'none');

disp('Finished')
