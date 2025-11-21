function density_subplot(year, month, day, fontsz, tilenum, target_lat, target_lon)
% DENSITY_SUBPLOT - Generate a density-depth subplot for a specific day and location
% Inputs:
%   year, month, day - date to analyze
%   fontsz - font size for plot elements
%   tilenum - subplot tile number in tiledlayout
%   target_lat, target_lon - center latitude and longitude of profile

    % Make sure plotting happens in the right axes
    ax = nexttile(tilenum);

    % Load data
    addpath(genpath('/Users/pameladoran/Documents/Toolbox-19May2024'));
    addpath(genpath('/Volumes/PamelaResearch/Luna_project/GoM_data/Functions/'))
    load /Users/pameladoran/Documents/Toolbox-19May2024/ScientificColourMaps8/lapaz/lapaz.mat lapaz % Density colormap

    % Retrieve HYCOM data
    [lon_hycom, lat_hycom, temp, salt, depth] = gom_hycom_TS(year, month, day);
    %[~, ~, u_vel, ~, ~] = gom_hycom_3D_UV(year, month, day);
    [~, ~, ~, ~, mld] = gom_hycom_ssh(year, month, day); %385x525

    lon = lon_hycom(1,:);
    lat_diffs = abs(lat_hycom(:,1) - target_lat);
    lat_idx = find(lat_diffs == min(lat_diffs), 1);

    % Compute density and velocity along single line of latitude
    [X, Y] = meshgrid(lon, depth);
    rho = densmdjwf(squeeze(salt(lat_idx, :, :))', squeeze(temp(lat_idx, :, :))', 0);
    %u = squeeze(u_vel(lat_idx, :, :))';
    MLD = squeeze(mld(lat_idx, :))';

    % Density contours
    rho_list = 1022:0.4:1028;
    [Cd, hd] = contourf(X, Y, rho, rho_list, '-k');
    shading flat;
    clabel(Cd, hd, 'FontSize', fontsz - 10);
    colormap(lapaz);
    hold on;

    % % Velocity contours
    % u_neg = u; u_neg(u >= 0) = NaN;
    % u_pos = u; u_pos(u < 0) = NaN;
    % u_neg_list = -2:0.1:0;
    % u_pos_list = 0.2:0.1:2;
    % 
    % [C1, h1] = contour(X, Y, u_neg, u_neg_list, '--w', 'LineWidth', 1.5);
    % clabel(C1, h1, 'FontSize', fontsz - 10);
    % hold on
    % [C2, h2] = contour(X, Y, u_pos, u_pos_list, '-w', 'LineWidth', 1.5);
    % clabel(C2, h2, 'FontSize', fontsz - 10);
    % hold on

    % Red line for LCFE center longitude
    lon_diff = abs(lon_hycom(1,:) - target_lon);
    lon_idx = find(lon_diff == min(lon_diff), 1);
    lon_val = lon(lon_idx);  % Grab the correct lon value
    
    plot([lon_val lon_val], [0 MLD(lon_idx)], 'r-', 'LineWidth', 5);


    % Styling 
    set(ax, 'YDir', 'reverse', ...
        'XAxisLocation', 'top', ...
        'FontName', 'Times New Roman', ...
        'FontSize', fontsz);

    ylim([0 150]);
    xlim([(lon_val-2) (lon_val+2)]);
    clim([1022 1028]);

    % Label formatting
    if tilenum == 4
        ylabel('Depth (m)', 'FontSize', fontsz+2);
    end
    set(ax, 'YTick', 0:50:200)

    % if ismember(tilenum, [5 6])
    %      set(ax, 'YTick', []);
    % end
    %xlabel('Longitude (ºW)', 'FontSize', fontsz);
    set(ax, 'XTick', [(lon_val -2) (lon_val-1) (lon_val) (lon_val+1) (lon_val+2)]);
    set(ax, 'XTickLabel', {'88ºW', '87ºW', '86ºW', '85ºW', '84ºW', '83ºW'});
    set(ax, 'XAxisLocation', 'bottom')

    % Add letter to corresponding subplot
    letters = 'abcdefghijklmnopqrstuvwxyz';
    % Subplot lettering (TOP LEFT)
    text(ax, 0.01, 0.98, ['(' letters(tilenum) ')'], ...
        'Units', 'normalized', ...
        'FontSize', 30, ...
        'HorizontalAlignment', 'left', ...
        'VerticalAlignment', 'top', ...
        'BackgroundColor', 'white', ...
        'FontName', 'Times New Roman');

     % Lat/lon textbox (bottom-right corner inside tile)
        txt_str = {
            sprintf('Lat: %.2f°N', target_lat), ...
            sprintf('Lon: %.2f°W', abs(target_lon))};
    
        text(ax, 0.98, 0.02, txt_str, ...
            'Units', 'normalized', ...
            'FontSize', fontsz - 4, ...
            'FontName', 'Times New Roman', ...
            'HorizontalAlignment', 'right', ...
            'VerticalAlignment', 'bottom', ...
            'BackgroundColor', 'w', ...
            'EdgeColor', 'none');

    hold off

end
