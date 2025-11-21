function homv_plot(dates, vert_data, mld_data, depth, nDays)
% HOMV_PLOT - Plot vertical velocity and MLD with AGU styling
%
% Inputs:
%   dates      - datetime array for each day
%   vert_data  - struct with .matrix field of vertical velocities [depth x days]
%   mld_data   - struct with .matrix field of MLD values [1 x days]
%   depth      - vector of depth values
%   nDays      - number of days to plot (should match length(dates))

    % Load scientific colormap
    load /Users/pameladoran/Documents/Toolbox-19May2024/ScientificColourMaps8/roma/roma.mat roma

    fontsz = 20;

    % Plot main contour
    contourf(1:nDays, depth, vert_data.matrix, 20, 'LineColor', 'none');
    hold on;

    % Plot mixed layer depth
    plot(1:nDays, mld_data.matrix, 'LineWidth', 3, 'Color', 'b');

    % Axes formatting
    set(gca, 'YDir', 'reverse', ...
            'XAxisLocation', 'bottom', ...
            'FontName', 'Times New Roman', ...
            'FontSize', fontsz);
    ylabel('Depth (m)', 'FontSize', fontsz-3);
    ylim([0 150])
    yticks = 0:50:150;
    set(gca, 'YTick', yticks)

    % Format x-axis ticks for 1st of each month
    xticks = find(day(dates) == 1);
    xtick_labels = datestr(dates(xticks), 'mmm dd');
    set(gca, 'XTick', xticks, 'XTickLabel', xtick_labels);

    % Create dateline for when Maximum Chl-a Occurs
    pan_dates = [
        datetime(2020,3,9)
    ];

    % Map pan_dates to indices in dates array
    for i = 1:length(pan_dates)
        idx = find(dates == pan_dates(i), 1);
        if ~isempty(idx)
            xline(idx, 'k-', 'LineWidth', 5);
        else
            warning('Date %s not found. Change date in homv_plot function', datestr(pan_dates(i)));
        end
    end


    % Final styling
    colormap(roma);
    clim([-1 1]);
    set(gca, 'FontName', 'Times New Roman', 'FontSize', fontsz);
    box on;

end
