clear; clc; close all;
addpath(genpath('/Users/pameladoran/Documents/Toolbox-19May2024'));
addpath(genpath('/Volumes/PamelaResearch/Matlab_Codes/LCFE/Functions/'))
addpath(genpath('/Volumes/PamelaResearch/Luna_Project/Fig4_Composite_phase/'))
savepath = '/Volumes/PamelaResearch/Luna_Project/Fig4_Composite_phase/';

% Load the data
load('/Volumes/PamelaResearch/Luna_project/GoM_data/mat_files/Composite_values_all.mat');

% Define region names and colors
regions = {'WFCE', 'CBCE', 'NCE'}; % teal, brown, gold
load('LCFE_colors.mat')

% Define phases and their corresponding values
phases = {'Retracted', 'Growing', 'Extended'};
all_counts = [
    Composite_values.wfce_retract, Composite_values.cbce_retract, Composite_values.nce_retract;
    Composite_values.wfce_extend,  Composite_values.cbce_extend,  Composite_values.nce_extend;
    Composite_values.wfce_unstable,Composite_values.cbce_unstable,Composite_values.nce_unstable
];

bar_colors = [teal; brown; gold]; % one row per region

% Create horizontal grouped bar plot
figure;
set(gcf, 'Position', [3 432 1580 626])
hold on;

% Grouped horizontal bar plot (changed here)
y_positions = 1:3;
b = barh(y_positions, all_counts, 'grouped', 'BarWidth', 0.7);

% Apply colors
for i = 1:3
    b(i).FaceColor = bar_colors(i,:);
end

% Add counts as labels (adjust x and y positions because bars are grouped)
groupWidth = min(0.8, 3/(3 + 1.5)); % total groups / (groups + 1.5) spacing approx.

for row = 1:3
    for col = 1:3
        val = all_counts(row, col);
        if val > 0
            % Calculate x (value) and y position for text
            % y offset depends on bar group width and column
            x = val + 0.05*max(all_counts(:)); % slightly right of bar end
            % Compute y based on group position
            y = y_positions(row) - groupWidth/2 + (2*col-1) * groupWidth / (2*3);
            
            text(x, y, num2str(val), ...
                'HorizontalAlignment', 'left', ...
                'VerticalAlignment', 'middle', ...
                'FontSize', 16);
        end
    end
end

% Styling
set(gca, 'YTick', y_positions, 'YTickLabel', phases, 'FontSize', 20, 'FontName', 'TimesNewRoman');
xlabel('Number of LCFEs', 'FontSize', 18, 'FontName', 'TimesNewRoman');
ylim([0.5, 3.5]);
xlim([0, max(all_counts(:)) * 1.2]);
l = legend(regions, 'Position',[0.75 0.2 0.12 0.2], 'FontSize', 18, 'FontName', 'TimesNewRoman');
%set(l, 'Position', [])
box on;

% Calculate total LCFEs per phase
phase_totals = sum(all_counts, 2);

% Create a string with totals for each phase
total_str = sprintf('Phase Totals:\n%s: %d\n%s: %d\n%s: %d', ...
    phases{3}, phase_totals(3), ...
    phases{2}, phase_totals(2), ...
    phases{1}, phase_totals(1));

% Add textbox annotation to the figure
annotation('textbox', [0.75 0.4 0.2 0.2], 'String', total_str, ...
    'FitBoxToText', 'on', 'BackgroundColor', 'white', ...
    'FontSize', 18, 'FontName', 'TimesNewRoman','EdgeColor', 'black');

% Save
figname = fullfile(savepath, 'Fig4_Phase_Composite_horizontal.tiff');
set(gcf, 'InvertHardcopy', 'off');
exportgraphics(gcf, figname, 'BackgroundColor', 'none', 'Resolution', 300);

disp('Finished');
