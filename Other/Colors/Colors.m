% Plots sample colors

close all;
savepath = '/Volumes/PamelaResearch/Luna_project/GoM_data/Colors';

% Define colors
dgreen = [0.039, 0.325, 0.035];%[0.024, 0.459, 0.31]; % LC Chlor & Nitrate
purp = [0.506, 0.353, 0.631]; % Max LC Lat & River Discharge
blue = [0.078, 0.42, 0.737]; % Max LCFE lat & MLD
orange = [0.863, 0.58, 0.122]; % Number of LCFE
teal = [0, 0.616, 0.576]; % WFCE
brown = [0.545, 0.271, 0.075]; % CBCE
gold = [1, 0.82, 0.184]; % NCE
magenta = [0.788, 0.024, 0.533]; % GoM Chl-a


% Color names and values
color_names = {'purp', 'blue', 'dgreen', 'orange', 'teal', 'gold', 'brown', 'magenta'};
color_values = [purp; blue; dgreen; orange; teal; gold; brown; magenta];

% Plot to see just colors
figure;
hold on;
for i = 1:length(color_names)
    rectangle('Position', [i-1, 0, 1, 1], 'FaceColor', color_values(i,:), 'EdgeColor', 'none');
    text(i-0.5, 1.1, color_names{i}, 'HorizontalAlignment', 'center', 'FontSize', 12);
end
axis off;
axis equal;
xlim([0 length(color_names)]);
ylim([0 1.5]);

save(fullfile(savepath, 'LCFE_colors.mat'), 'purp', 'blue', 'dgreen', 'orange', 'teal', 'gold', 'brown', "magenta");
