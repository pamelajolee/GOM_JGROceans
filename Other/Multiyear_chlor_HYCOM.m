%% Showing the matching contours of the Loop Current in ADT and the 0.07 mg/m^3 contourt in Chl-a
% Using the same process as making the first figure, but showing all of
% 2018 to 2024 to make animations - Will be used in presenations

clear;
clc;
close all;
addpath(genpath('/Users/pameladoran/Documents/Toolbox-19May2024'));
addpath(genpath('/Volumes/PamelaResearch/Luna_project/GoM_data/Functions/'));
addpath(genpath('/Volumes/PamelaResearch/Luna_project/Fig1_Region_map/'));
savepath = '/Volumes/PamelaResearch/Luna_project/'; 
load ('Green_map.mat');
load('LCFE_colors.mat');


% Loop through days
for years = 2018:2024
    % Make new folder for each year
    mkdir([savepath 'DINEOF3_HYCOM_colormap_' num2str(years) '/' ]);
    savepath_a = ([savepath 'DINEOF3_HYCOM_colormap_' num2str(years) '/']);
    
    for d = datenum(years, 1, 1): datenum(years, 12, 31)
        % Get the date
        date = datevec(d);
        month = num2str(date(2), '%02d');
        day = num2str(date(3), '%02d');
        year = num2str(date(1), '%04d');

        try
            % Retrieving data
            [lon_adt, lat_adt, ssh, ssh_masked] = gom_hycom_ssh(str2double(year), str2double(month), str2double(day));
        catch ME1
            disp(['CMEMS file not found for: '  month ' ' day ' ' year]);
            continue;
        end  
        
        try
            [lon_chlor, lat_chlor, chlor_total] = gom_dineof(str2double(year), str2double(month), str2double(day));
        catch ME2
            disp(['DINEOF file not found for: '  month ' ' day ' ' year]);
            continue;
        end

        disp(['Processing:'  ' ' month '/' day '/' year]);


        %% Make the Plot

        figure(1)
        clf
        % Plot and zoom on Gulf of Mexico
        m_proj('mercator','longitude',[-93 -81],'latitude',[21 31]) 
        load('coast');
        hold on;
        
        % Assign Chl-a over 0.2 to = 0.2
        chlor_total(chlor_total > 0.2) = 0.2;
        
         % Plot DINEOF Ocean color data
        m_contourf(lon_chlor, lat_chlor, chlor_total, 'LineStyle', 'none')
        shading interp;
        clim([0.05 0.2])
        colormap(Green_color);
        hold on;

        % Mask and contour lines
        % chlor_total(lon_chlor <= -88) = NaN;
        [C,h] = m_contour(lon_chlor, lat_chlor, chlor_total,[0.07 0.07], 'Color', purp, 'LineWidth', 3);
        [C,h] = m_contour(lon_chlor, lat_chlor, chlor_total, [0.05 0.05], 'Color', magenta, 'LineWidth', 3);
        
        % Seasonal Mean still needs to be removed from HYCOM
        [C4,h4] = m_contour(lon_adt, lat_adt, ssh_masked, [-0.28 -0.28], 'Color', blue, 'LineWidth', 3);
        [c5,h5] = m_contour(lon_adt, lat_adt, ssh_masked, [0.17 0.17], 'Color', 'black', 'LineWidth', 3);
        % [C2,h2] = m_contour(lon_adt, lat_adt, ssh,[-0.28 -0.28], 'Color', 'white', 'LineWidth', 3);
        % [C3,h3] = m_contour(lon_adt, lat_adt, ssh, [0.17 0.17], 'black', 'LineWidth', 3);
        % 

        %Making the plot look better
        m_gshhs_i('patch',[0.8 0.8 0.8]);
        m_grid('box','fancy','box','on','linewidth',3, 'FontSize', 16)

        title([month '/' day '/' year] , 'Units', 'normalized', 'Position', [0.8,0.9, 0]);
        set(gca,'fontname','times new roman','fontsize',18);
        %ylabel(colorbar, 'Chlorophyll-a (mg/m^3)', 'FontSize', 18);
        
        % % Colorbar with labels and font
        % cb = colorbar(gca, 'Position', [0.86 0.105 0.02 0.82]);
        % cb.Label.String = 'Chlorophyll-a (mg/m^3)';
        % cb.Label.FontSize = 16;
        % cb.FontName = 'Times New Roman';
        % cb.Ticks = [0.05 0.07 0.09 0.11 0.13 0.15];
        % cb.TickLabels = {'0.05', '0.07', '0.09', '0.11', '0.13', '0.15'};

        % Chl-a Colorbar
        cb1 = colorbar(gca, "eastoutside");
        set(cb1, 'Position', [0.86 0.105 0.02 0.82]);
        cb1.Label.String = 'Log (Chlorphyll-a (mg/m^3))';
        cb1.Label.FontSize = 16;
        set(gca,'colorscale','log');

        %Save the Figure
        figname=([savepath_a 'DINEOF3_LCFE_HYCOM_' month '-' day '-' year]);
        set(gcf, 'InvertHardcopy', 'off')
        saveas(gcf,figname, 'tiff')

        % break; % Exit after one figure

    end

end
disp('Finished')
