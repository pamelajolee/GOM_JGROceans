%% Used to make the Homvollor plots in Figures 8-11

function [u_data, v_data, mld_data, depth, nDays] = chlor_flux_data(dates, center_data)


    % Load depth structure sample
    [~, ~, ~, depth] = gom_hycom_w_vel(2018, 1, 1);
    depth = depth(:);  % Make sure depth is a column vector
    nDepths = length(depth);
    nDays = length(dates);
    
    % Preallocate data structures
    u_data = struct();  
    u_data.matrix = NaN(nDepths, nDays);
    v_data = struct();
    v_data.matrix = NaN(nDepths, nDays);
    mld_data = struct();
    mld_data.matrix = NaN(1, nDays);


    for d = 1:nDays
        curr_date = dates(d);
        fprintf('Processing: %s Surface Velocity \n', datestr(curr_date));

        target_lat = center_data(d).center_lat;
        target_lon = center_data(d).center_lon;

        %[lon_hycom, lat_hycom, w_vel, ~] = gom_hycom_w_vel(year(curr_date), month(curr_date), day(curr_date));
        [lon_hycom, lat_hycom, u_vel, v_vel, depth] = gom_hycom_3D_UV(year(curr_date), month(curr_date), day(curr_date));

        lat_diffs = abs(lat_hycom(:,1) - target_lat);
        lat_idx = find(lat_diffs == min(lat_diffs), 1);

        lon_diff = abs(lon_hycom(1,:) - target_lon);
        lon_idx = find(lon_diff == min(lon_diff), 1);

        u_profile = squeeze(u_vel(lat_idx, lon_idx, :));
        v_profile = squeeze(v_vel(lat_idx, lon_idx, :));
        u_profile = smoothdata(u_profile, 'movmean');
        v_profile = smoothdata(v_profile, 'movmean');

        % Only want the surface
        u_data.matrix(:, d) = u_profile; % m/s
        v_data.matrix(:, d) = v_profile;

        [lon_ssh, lat_ssh, ~, ~, mld] = gom_hycom_ssh(year(curr_date), month(curr_date), day(curr_date));

        lat_diffs = abs(lat_ssh(:,1) - target_lat);
        lat_idx = find(lat_diffs == min(lat_diffs), 1);

        lon_diffs = abs(lon_ssh(1,:) - target_lon);
        lon_idx = find(lon_diffs == min(lon_diffs), 1);

        mld_point = squeeze(mld(lat_idx, lon_idx));
        mld_data.matrix(d) = mld_point;


    end


end

