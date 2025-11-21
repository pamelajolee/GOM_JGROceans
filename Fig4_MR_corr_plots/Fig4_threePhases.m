%% MLD First
clear; close all;
addpath(genpath('/Users/pameladoran/HardDrive/MATLAB/USC/LCFE/'))

% Load data
load /Users/pameladoran/HardDrive/MATLAB/USC/LCFE/GoM_data/Colors/LCFE_colors.mat blue dgreen
load /Users/pameladoran/HardDrive/MATLAB/USC/LCFE/GoM_data/mat_files/doy_averages.mat
load /Users/pameladoran/HardDrive/MATLAB/USC/LCFE/GoM_data/mat_files/HYCOM_MLD.mat

% Extract MLD data
for i = 1:length(MLD)
    time_MLD(i) = datenum(MLD(i).date);
    data_MLD(i) = MLD(i).mld;
end
clear MLD;

%% LC Values
load /Users/pameladoran/HardDrive/MATLAB/USC/LCFE/GoM_data/mat_files/LC_values_all_200m.mat

for i = 1:length(LC_values)
    time_chlor(i) = datenum(LC_values(i).date);
    dw_chlor_avg(i) = LC_values(i).dw_chlor_avg;
    east_chlor(i) = LC_values(i).east_chlor;
end
clear LC_values;

%% Match Time Periods
id_begin = find(time_MLD == time_chlor(1));
id_end   = find(time_chlor == time_MLD(end));

% Test alignment
close all;
figure;
plot(time_MLD(id_begin:end)); hold on;
plot(time_chlor(1:id_end), 'r');

mld_t    = time_MLD(id_begin:end);
mld_data = data_MLD(id_begin:end);
chlor_t  = time_chlor(1:id_end);
chlor_data = east_chlor(1:id_end);

%% Convert to Day-of-Year
for i = 1:length(mld_t)
    days_mld(i) = mld_t(i) - datenum(['00-Jan-' datestr(mld_t(i), 'yyyy')]);
end

for i = 1:length(chlor_t)
    days_chlor(i) = chlor_t(i) - datenum(['00-Jan-' datestr(chlor_t(i), 'yyyy')]);
end

% Compute daily means
for i = 1:365
    pos_mld = find(days_mld == i);
    mld_days_of_the_year(i) = mean(mld_data(pos_mld));

    pos_chlor = find(days_chlor == i);
    chlor_days_of_the_year(i) = mean(chlor_data(pos_chlor));
end

days_in_a_year = 1:365;

%% Quick Visualization
close all;
figure;
subplot(1,2,1);
plot(days_in_a_year, mld_days_of_the_year, 'b.');
subplot(1,2,2);
plot(days_in_a_year, chlor_days_of_the_year, 'r.');

%% Nitrate
load /Users/pameladoran/HardDrive/MATLAB/USC/LCFE/GoM_data/mat_files/MR_Nitrate_2018to2024.mat

Nitrate = Nitrate_TT.Nitrate_mgL;
Nitrate_time = datenum(Nitrate_TT.Time);

id_begin_ni = find(Nitrate_time == mld_t(1));
id_end_ni   = find(Nitrate_time == mld_t(end));

Nitrate_time_cut = Nitrate_time(id_begin_ni:id_end_ni);
Nitrate_cut      = Nitrate(id_begin_ni:id_end_ni);

for i = 1:length(Nitrate_time_cut)
    days_nitrate(i) = Nitrate_time_cut(i) - datenum(['00-Jan-' datestr(Nitrate_time_cut(i), 'yyyy')]);
end

for i = 1:365
    pos_nitrate = find(days_nitrate == i);
    nit_days_of_the_year(i) = mean(Nitrate_cut(pos_nitrate));
end

%% Plot: MLD, Nitrate, Chlorophyll, Loading
close all;
figure('Units', 'normalized', 'Position', [0 0.3 1 .4]);

subplot(1,4,1);
plot(days_in_a_year, chlor_days_of_the_year, 'r.');
title('Chla'); hold on;
plot([158 158], get(gca, 'ylim'), 'k--');
plot([277 277], get(gca, 'ylim'), 'k--');
text(50, 0.11, 'Phase I', 'FontSize', 14);
text(175, 0.11, 'Phase II', 'FontSize', 14);
text(300, 0.11, 'Phase III', 'FontSize', 14);
xlim([0 365]);

subplot(1,4,2);
plot(days_in_a_year, mld_days_of_the_year, 'b.');
title('MLD');
xlim([0 365]);

subplot(1,4,3);
plot(days_in_a_year, nit_days_of_the_year, 'k.');
title('Nitrogen');
xlim([0 365]);

subplot(1,4,4);
plot(days_in_a_year, loading_mean', 'Color', dgreen);
title('N Loading');
xlim([0 365]);

%% Focus on Summer Chl-a
id_nit = 159:276;
dx = length(id_nit);
chla_summer = chlor_mean(id_nit);

close all;
figure;
plot(chla_summer);

%% Lagged Correlation: Summer Chl-a vs Nitrate
time_ts = 1;
while time_ts < length(nitrate_doy) - dx
    [r, p] = corrcoef(chla_summer, nit_days_of_the_year(time_ts:time_ts+dx-1));
    r_coeff(time_ts) = r(1,2);
    p_value(time_ts) = p(1,2);
    time_ts = time_ts + 1;
end

[~, id_chl_nit] = max(r_coeff);
lag = id_nit(1) - id_chl_nit;  % ~17 days lag

%% Correlation Plots Across Phases
close all;
figure('Units', 'normalized', 'Position', [0 0.3 1 .4]);
set(gca, 'FontSize', 20, 'FontName', 'TimesNewRoman');

% --- Phase I and III ---
for t_part = 1:2
    if t_part == 1
        t_winter = 1:158;
        subplot(1,3,1);
        title_label = 'Phase I';
        box_pos = [0.15, 0.8, 0.1, 0.1]; % normalized position near subplot 1
    else
        t_winter = 277:365;
        subplot(1,3,3);
        title_label = 'Phase III';
        box_pos = [0.71, 0.8, 0.1, 0.1]; % near subplot 3
    end

    plot(mld_days_of_the_year(t_winter), chlor_days_of_the_year(t_winter), ...
         '.', 'MarkerSize', 15, 'MarkerFaceColor', blue); hold on;
    ylabel('MLD (m)', 'FontSize', 16);
    xlabel('Chlorophyll eGoM', 'FontSize', 16);

    % Linear fit
    p = polyfit(mld_days_of_the_year(t_winter), chlor_days_of_the_year(t_winter), 1);
    x1 = linspace(min(mld_days_of_the_year(t_winter)), max(mld_days_of_the_year(t_winter)), 1000);
    y1 = polyval(p, x1);
    plot(x1, y1, 'k', 'LineWidth', 3);

    lm_output = fitlm(mld_days_of_the_year(t_winter)', chlor_days_of_the_year(t_winter)');
    R_squared = lm_output.Rsquared.Ordinary;
    p_value = lm_output.Coefficients.pValue(2);

    title(title_label, 'FontSize', 20);

    % Automatically fitting box around text
    annotation('textbox', box_pos, ...
        'String', sprintf('R^2 = %d%%  \np-value << 0.01 \nLag: 0 days', round(R_squared*100)), ...
        'FontSize', 12, ...
        'FitBoxToText', 'on', ...
        'EdgeColor', 'k', ...
        'BackgroundColor', 'w');
end

% --- Phase II ---
subplot(1,3,2);
plot(nit_days_of_the_year(id_chl_nit:id_chl_nit+dx-1), chla_summer, ...
     '.', 'MarkerSize', 15, 'Color', dgreen); hold on;
title('Phase II', 'FontSize', 20);
ylabel('Nitrogen Concentration', 'FontSize', 16); 
xlabel('Chlorophyll eGoM', 'FontSize', 16);

% Linear fit
p = polyfit(nit_days_of_the_year(id_chl_nit:id_chl_nit+dx-1), chla_summer, 1);
x1 = linspace(min(nit_days_of_the_year(id_chl_nit:id_chl_nit+dx-1)), ...
              max(nit_days_of_the_year(id_chl_nit:id_chl_nit+dx-1)), 1000);
y1 = polyval(p, x1);
plot(x1, y1, 'k', 'LineWidth', 3);

lm_output = fitlm(nit_days_of_the_year(id_chl_nit:id_chl_nit+dx-1)', chla_summer');
R_squared = lm_output.Rsquared.Ordinary;
p_value = lm_output.Coefficients.pValue(2);

% Box automatically fits text
annotation('textbox', [0.43, 0.8, 0.1, 0.1], ...
    'String', sprintf('R^2 = %d%%  \np-value << 0.01 \nLag: %d days', round(R_squared*100), lag), ...
    'FontSize', 12, ...
    'FitBoxToText', 'on', ...
    'EdgeColor', 'k', ...
    'BackgroundColor', 'w');

%% Save the Figure 
savepath = '/Users/pameladoran/HardDrive/MATLAB/USC/LCFE/Fig7_MR_corr_plots/';
figname = [savepath 'Fig7_LoadN_and_mld_vs_chlor.tiff'];
exportgraphics(gcf, figname, 'BackgroundColor', 'none', 'Resolution', 300);
disp('Finished');