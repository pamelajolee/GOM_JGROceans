function time_plot(dates, center_data, u_data, v_data, mld_data, max_date, fontsz)

% Plot will be a time series showing the horizontal mass transport of Chl-a
% inside the eddy over the span of dates that have been provided (lifespan of the eddy)
%
% Inputs:
% dates = datetime array (e.g. datetime(2020,1,29):datetime(2020,3,29));
% avg chlor inside eddy = [center_data.chlorIN] - One value per day (mg/m^3)
% size of eddy in m^2 = [center_data.Area] - one value per day (m^2)
% surface zonal velocity at center = u_data.matrix(1,:) - (1 x length(dates)) (m/s)
% meridional velocity at center = v_data.matrix(1,:) - (1 x length(dates)) (m/s)
% mixed layer depth = mld_data.matrix - (1 x length(dates)) (m)
load /Volumes/PamelaResearch/Luna_project/GoM_data/Colors/LCFE_colors.mat blue;
load /Volumes/PamelaResearch/Luna_project/GoM_data/Colors/LCFE_colors.mat dgreen;


% Constants
secPerDay = 86400; 
mg2tonnes = 1e-9; % mg to tonnes
red = [0.8500 0.3250 0.0980];

% Extract inputs
C   = [center_data.chlorIN];   % mg/m^3
A   = [center_data.Area];      % m^2
U   = u_data.matrix(1,:);      % m/s
V   = v_data.matrix(1,:);      % m/s
MLD = mld_data.matrix;         % m

a_mag = sqrt((U).^2 + (V).^2);

% Convert dates to numeric time
time = datenum([center_data.date]);
n   = numel(center_data);

% Only interpolate if there are NaNs in Chlor
if any(isnan(C)) 
    % Interpolate missing data (ignoring NaNs in the input)
    C_interp = interp1(time(~isnan(C)), C(~isnan(C)), time, 'linear');

    % Update the structure with interpolated values
    for i = 1:n
        C(i) = C_interp(i);
    end

    disp('Coordinates interpolated.');
else
    disp('No interpolation needed.');
end

% Transport calculations
ZonalTransport  = C .* A .* U .* secPerDay .* mg2tonnes;   % tonnes/day
MeridTransport  = C .* A .* V .* secPerDay .* mg2tonnes;   % tonnes/day
Transport = C .*A .*a_mag .*secPerDay .* mg2tonnes;

% Smooth the data
MLD = smoothdata(MLD, 'gaussian');
% ZonalTransport = smoothdata(ZonalTransport, 'gaussian');
% MeridTransport = smoothdata(MeridTransport, 'gaussian');
Transport = smoothdata(Transport, 'gaussian');

% --- Left axis: MLD ---
yyaxis('left')
hMLD = plot(dates, MLD, 'Color', red, 'LineWidth', 2, 'LineStyle', '-'); 
set(gca, 'YDir','reverse'); % invert axis for MLD
ylabel('Mixed Layer Depth (m)', 'FontSize', 14, 'FontName', 'Times New Roman');
set(gca, 'YColor', red);
hold on

% --- Right axis: Chl-a transport ---
yyaxis('right')
hTrans = plot(dates, Transport, 'Color', blue, 'LineWidth', 2, 'LineStyle', '-'); 
hold on
% hMerid = plot(dates, MeridTransport, 'Color', red, 'LineWidth', 2, 'LineStyle', '-'); 
ylabel('Chl-a Transport (tonnes/day)', 'FontSize', 14, 'FontName', 'Times New Roman');
set(gca, 'YColor', blue);
hold off

% --- Date line for when Max Chl-a occurs ---
idx = dates == max_date;
hX = xline(dates(idx), 'Color', dgreen, 'LineWidth', 5); % save handle


% --- Formatting ---
xticks(dates(1):days(5):dates(end-1)); % tick every 5 days
datetick('x','dd-mmm','keepticks','keeplimits');
xlim([dates(1) dates(end)])
grid on;

% --- Visual Improvements ---
legend([hMLD, hTrans, hX], ...
       {'Mixed Layer Depth',' Chl-a Transport','Date of Max Chl-a'}, ...
       'FontSize', fontsz-2, 'FontName', 'Times New Roman', 'Location','southwest');

set(gca, 'FontSize', fontsz, 'FontName','Times New Roman', 'LineWidth', 2);
box on;

end
