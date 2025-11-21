function [center_data] = track_HYCOM_LCFE(dates, ssh_mask)
% Using for JGR Ocean Figs 8-10
% Finding the target lat and target lon for
% the center of LCFE on a single day. The lat and lon will then be used to
% get the vertical velocity depth profile at the center lat and lon


% Structure
center_data = struct('date', num2cell(dates), ...
                     'chlorIN',  num2cell(NaN(size(dates))), ...
                     'Area', num2cell(NaN(size(dates))),...
                     'center_lat', num2cell(NaN(size(dates))), ...
                     'center_lon', num2cell(NaN(size(dates))));

% Parameters
ssh_LCFE = -0.28;
ssh_LC   =  0.17;

% Reference LCFE center (empty until we find the first valid one)
ref_center = [];

% Loop through all dates
for d = 1:length(dates) 

    % Get the date
    current_date = dates(d);
    months = month(current_date);
    days = day(current_date);
    years = year(current_date);

    try
        % Retrieving data
        [lon_ssh, lat_ssh, ~, ssh_masked] = gom_hycom_ssh(years, months, days);
    catch ME1 %#ok<NASGU>
        disp(['CMEMS file not found for: ' datestr(current_date)]);
        continue;
    end

     try
        [lon_chlor, lat_chlor, chlor_total] = gom_dineof(years, months, days);
    catch ME2 %#ok<NASGU>
        disp(['DINEOF file not found for: '  datestr(current_date)]);
        continue;
     end    


    % Contour and Gridding
    % DONT use adt_masked for c_LC - cuts off closed contour of LCE

    % Uncomment below to see LCFEs for each day
    % figure(d); set(gcf, 'Position', [54 177 560 420])

    % Apply mask to hide other LCFEs
    ssh_masked(~ssh_mask) = NaN;  

    % Convert lon/lat grids to vectors for contourc
    xvec = double(lon_ssh(1,:));   % 1D
    yvec = double(lat_ssh(:,1));   % 1D 
    
    % Extract contour (using contourc so it doesn't plot and screw up final figure)
    C_LCFE = contourc(xvec, yvec, ssh_masked, [ssh_LCFE ssh_LCFE]);
    C_LC   = contourc(xvec, yvec, ssh_masked, [ssh_LC ssh_LC]);

    % Parse contourc outputs into segments
    contours_LCFE = parse_contourc(C_LCFE);
    contours_LC   = parse_contourc(C_LC);

    % Using xx and yy to keep consistent with Luna method
    xx = lon_chlor';yy = flip(lat_chlor,1)';
    chlor_map = flip(chlor_total,1)';
    chlor_map = chlor_map';

    disp(['Processing: ' datestr(current_date) ' LCFE Center']); % Know it's working

    n_LCFE = find(C_LCFE(1,:) == ssh_LCFE);
    n = find(C_LC(1,:) == ssh_LC);

    % Locate cyclonic eddies
    found_LCFE = false;
    chosen_idx = [];
    min_dist_to_ref = Inf;

    for n_LC = 1:numel(contours_LC) % Loop for each LC contour
        X_LC = contours_LC{n_LC}(1,:);
        Y_LC = contours_LC{n_LC}(2,:);

        for n_cycl = 1:numel(contours_LCFE) % Loop for each LCFE
            X_LCFE = contours_LCFE{n_cycl}(1,:);
            Y_LCFE = contours_LCFE{n_cycl}(2,:);

            %%% Shows best how it works when looking at:
            %%% dates = datetime(2018,4,19):datetime(2018,4,30);

            % Uncomment to visualize:
            % hold on; plot(X_LC, Y_LC, 'r');
            % hold on; plot(X_LCFE, Y_LCFE, 'cyan')

            % Distance calculation between LC and LCFE contours
            [X_cycl_rep, X_LC_rep] = meshgrid(X_LCFE, X_LC); 
            [Y_cycl_rep, Y_LC_rep] = meshgrid(Y_LCFE, Y_LC);

            dist = gsw_distance([X_cycl_rep(:) X_LC_rep(:)], ...
                                [Y_cycl_rep(:) Y_LC_rep(:)]); 
            min_dist = min(abs(dist));

            % Conditions for valid LCFE
            if (numel(X_LCFE) >= 5 && min_dist < 100e3)
    
                % Compute this contour's center
                cent_x = mean(X_LCFE);
                cent_y = mean(Y_LCFE);

                if isempty(ref_center)
                    % First valid LCFE → pick it as reference
                    chosen_idx = n_cycl;
                    found_LCFE = true;
                    ref_center = [cent_x cent_y];
                    break;
                else
                    % Compare to reference → pick closest contour
                    d_km = gsw_distance([cent_x ref_center(1)], ...
                                        [cent_y ref_center(2)]);
                    if d_km < min_dist_to_ref
                        min_dist_to_ref = d_km;
                        chosen_idx = n_cycl;
                        found_LCFE = true;
                    end
                end
            end
        end
        if ~isempty(ref_center) && found_LCFE, break; end
    end

    if ~found_LCFE, continue; end

    % Use chosen LCFE
    X_LCFE = contours_LCFE{chosen_idx}(1,:);
    Y_LCFE = contours_LCFE{chosen_idx}(2,:);
    cent_x = mean(X_LCFE); cent_y = mean(Y_LCFE);

    % Update reference center for tracking
    ref_center = [cent_x cent_y];

    % % Uncomment to mark center on plot
    % hold on;
    % plot(cent_x, cent_y, 'Marker','*', 'MarkerSize', 10)

    % Calculate the size of the Eddy and store
    [geom,~,~] = polygeom(X_LCFE,Y_LCFE);
    [Xm,Ym] = latlon2dist(X_LCFE,Y_LCFE);
    [Am,~,~] = polygeom(Xm,Ym); %calculates area in m^2
    A = geom(1); %#ok<NASGU>
    Area_m = Am(1); % size of eddy in m^2
    radius = sqrt(Area_m/pi);
    r_km = (radius/1000); % Size of Eddy in Km %#ok<NASGU>

    % Flatten chlorophyll grid for inpolygon
    xq = xx(:); yq = yy(:); chlor_flat = chlor_map(:);

    % Points inside polygon
    [in, ~] = inpolygon(xq, yq, X_LCFE, Y_LCFE);
    chlor_in = mean(chlor_flat(in), 'omitnan');  % Mean chlor inside

    % Store the values for the day
    center_data(d).center_lat = cent_y;
    center_data(d).center_lon = cent_x;
    center_data(d).chlorIN = chlor_in;
    center_data(d).Area = Area_m;

    % disp(struct2table(center_data(d)));
end

end

%% Functions
function segments = parse_contourc(C)
% Convert contourc output into cell array of [2 x N] segments
% Each element of segments is [x; y] for one closed contour
segments = {};
col = 1;
while col < size(C,2)
    level = C(1,col); %#ok<NASGU> 
    nPoints = C(2,col);
    x = C(1,col+1:col+nPoints);
    y = C(2,col+1:col+nPoints);
    segments{end+1} = [x; y]; 
    col = col + nPoints + 1;
end
end
