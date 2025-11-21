%% Used for figures 8-11 to make the first row of plots


function chlor_subplot(year, month, day, fontsz, tilenum, ssh_mask)

addpath(genpath('/Users/pameladoran/Documents/Toolbox-19May2024'));
load /Volumes/PamelaResearch/Luna_project/GoM_data/mat_files/chlor_mean.mat chlor_map_avg;
load /Volumes/PamelaResearch/Luna_project/GoM_data/Colors/LCFE_colors.mat blue
load /Volumes/PamelaResearch/Luna_project/GoM_data/Colors/Diverging_green_map.mat Diverging_green
% load Green_map.mat Green_color;

ax = nexttile(tilenum);
% Retrieve CMEMS ADT for GoM
% [lon_adt, lat_adt, adt_anom, adt_masked] = gom_adt(year, month, day);

% Retrieve HYCOM ssh
[lon_ssh, lat_ssh, ~, ssh_masked, ~] = gom_hycom_ssh(year, month, day);

% Retrieve DINEOF ocean color
[lon_chlor, lat_chlor, chlor_total] = gom_dineof(year, month, day); % Whole GoM - log color

% Remove the mean
chlor_total = chlor_total - chlor_map_avg;

% Plot and zoom on Gulf of Mexico
m_proj('mercator','longitude',[-91 -82.5],'latitude',[23 30]) 
hold on;

% % Assign Chl-a over 0.1 to = 0.1
% chlor_total(chlor_total > 0.1) = 0.1;

m_pcolor(lon_chlor, lat_chlor, chlor_total, 'LineStyle', 'none')
shading interp;
clim([-0.2 0.2])
colormap(Diverging_green);
hold on;

% % Overlay ADT contours
% mask_LC = (lon_adt >= -81) & (lat_adt <= 21);  
% adt_anom(mask_LC) = NaN; % Not plotting GS and CC
% m_contour(lon_adt,lat_adt,adt_anom,[0.17 0.17], '-k','linewidth',3);
% hold on
% 
% adt_masked(~mask) = NaN;  % Keep only LCFE region, NaN everything else
% m_contour(lon_adt, lat_adt, adt_masked, [-0.28 -0.28], 'Color', 'w', 'LineWidth', 3);
% hold on

% Add HYCOM contours
m_contour(lon_ssh, lat_ssh, ssh_masked, [0.17 0.17], 'Color', 'k', 'LineWidth', 3);

% Hide other cyconic eddies
ssh_masked(~ssh_mask) = NaN;
m_contour(lon_ssh, lat_ssh, ssh_masked, [-0.28 -0.28], 'Color', blue, 'LineWidth', 3);

%Making the plot look better - grid and coastlines
m_gshhs_i('patch',[0.8 0.8 0.8]);
m_grid('box','fancy','box','on','linewidth',2, 'fontsize', 18, 'xtick', 4, 'ytick', 4)


    % if ismember(tile_num, [1,4, 7])
    %     handles1=findobj(ax, 'tag', 'm_grid_xticklabel');
    %     delete(handles1());
    % elseif ismember(tile_num, [11, 12])
    %     handles2=findobj(ax, 'tag', 'm_grid_yticklabel');
    %     delete(handles2());
    % elseif ismember(tile_num, [2,3,5,6,8,9])
    %     handles3=findobj(ax, 'tag', 'm_grid_xticklabel');
    %     delete(handles3());
    %     handles4=findobj(ax, 'tag', 'm_grid_yticklabel');
    %     delete(handles4());
    % end

% % Column Labels
% annotation('textbox', [0.13 0.92 0.2 0.03], 'String', 'LCFE Appears', ...
%     'EdgeColor', 'none', 'HorizontalAlignment', 'center', 'FontSize', fontsz, ...
%     'FontName', 'times new roman', 'FontWeight', 'normal');
% annotation('textbox', [0.4 0.92 0.2 0.03], 'String', 'Max Chl-a', ...
%     'EdgeColor', 'none', 'HorizontalAlignment', 'center', 'FontSize', fontsz, ...
%     'FontName', 'times new roman', 'FontWeight', 'normal');
% annotation('textbox', [0.65 0.92 0.2 0.03], 'String', 'LCE Separation', ...
%     'EdgeColor', 'none', 'HorizontalAlignment', 'center', 'FontSize', fontsz, ...
%     'FontName', 'times new roman', 'FontWeight', 'normal');

    % Add letter to corresponding subplot
    letters = 'abcdefghijklmnopqrstuvwxyz';
    % Subplot lettering (TOP LEFT)
    text(ax, 0.01, 0.98, ['(' letters(tilenum) ')'], ...
        'Units', 'normalized', ...
        'FontSize', fontsz +10, ...
        'HorizontalAlignment', 'left', ...
        'VerticalAlignment', 'top', ...
        'BackgroundColor', 'white', ...
        'FontName', 'Times New Roman');

title(ax, sprintf('%d/%d/%d', month, day, year), 'Units', 'normalized', 'HorizontalAlignment', 'center');
set(ax,'fontname','times new roman','fontsize',fontsz);
hold off

end
