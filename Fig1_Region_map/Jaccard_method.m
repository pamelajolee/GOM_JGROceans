%% Script to compare LC defined by SSH vs. Chlorophyll thresholds (Mask Agreement, with interpolation)
% SSH field interpolated to chlorophyll grid before mask comparison
% Agreement = % of pixels classified the same (LC vs non-LC)
% 8/28/2025

clear;
close all;
addpath(genpath('/Users/pameladoran/Documents/Toolbox-19May2024'));
addpath(genpath('/Volumes/PamelaResearch/Luna_project/GoM_data/Functions/'))
addpath(genpath('/Volumes/PamelaResearch/Luna_project/Fig2_LC_timeseries/'))
data_save = '/Volumes/PamelaResearch/Luna_project/GoM_data/';

dates = datetime(2018,1,1):datetime(2024,12,31);
ssh_LC = 0.17;
chl_thresholds = 0.05:0.01:0.10;

% Matrix will have percent agreenment for each threshold for each day
Jaccard = nan(length(dates), length(chl_thresholds));

for d = 1:length(dates)

    current_date = dates(d);
    yyyy = year(current_date); mm = month(current_date); dd = day(current_date);

    try
        [lon_adt, lat_adt, adt_anom, ~] = gom_adt(yyyy, mm, dd);
        [lon_chlor, lat_chlor, chlor_masked] = gom_dineof(yyyy, mm, dd);
    catch
        disp(['Data not found for: ' datestr(current_date)]);
        continue;
    end

    % Using xx and yy to keep consitent with Luna method
    xx = lon_chlor;yy = flip(lat_chlor,1);
    chlor_map = flip(chlor_masked,1);

    % Remove Chl-a higher than 0.2
    chl_mask = (chlor_map >= 0.2);
    chlor_map(chl_mask) = NaN;

    % Interpolate SSH anomaly to chlorophyll grid - both 181x241 double and
    % pcolor shows they are in the same orientation
    ssh_interp = interp2(lon_adt, lat_adt, adt_anom, xx, yy, 'nearest');

    % Loop over Chl-a thresholds
    for t = 1:length(chl_thresholds)
        th = chl_thresholds(t);

        disp(['Tesing: ' num2str(th)])

        % Remove Caribbean and GS from Chlor
        ch_mask = (xx <= -82) & (yy >=20);
        chlor_map(~ch_mask) = NaN;

        % Create contours and segments for each variable
        C_ssh   = contourc(double(xx(1,:)), double(yy(:,1)),ssh_interp,[ssh_LC ssh_LC]);
        C_chlor = contourc(double(xx(1,:)),double(yy(:,1)),chlor_map,[th th]);
        ssh_segments  = parse_contourc(C_ssh);
        chl_segments  = parse_contourc(C_chlor);
        
        warning('off', 'all');
        % Compare each segment
        for i = 1:numel(ssh_segments)
            X_SSH = ssh_segments{i}(1,:);
            Y_SSH = ssh_segments{i}(2,:);
            X_SSH = [X_SSH X_SSH(1)];
            Y_SSH = [Y_SSH Y_SSH(1)];
            [X_SSH,Y_SSH] = uniquePoints(X_SSH,Y_SSH);

            for j = 1:numel(chl_segments)
                X_CHL = chl_segments{j}(1,:);
                Y_CHL = chl_segments{j}(2,:);
                X_CHL = [X_CHL X_CHL(1)];
                Y_CHL = [Y_CHL Y_CHL(1)];
                [X_CHL,Y_CHL] = uniquePoints(X_CHL,Y_CHL);

                polySSH = polyshape(X_SSH,Y_SSH);
                polyCHL = polyshape(X_CHL,Y_CHL);

                if polySSH.NumRegions>0 && polyCHL.NumRegions>0
                    pgInter = intersect(polySSH,polyCHL);
                    pgUnion = union(polySSH,polyCHL);

                    if area(pgUnion) > 0
                        Jaccard(d,t) = area(pgInter) / area(pgUnion);
                    end
                end
            end
        end

    end
   
    disp(['Processed: ' datestr(current_date)]);

    
end

% Average agreement across all days
meanAgreement = nanmean(Jaccard,1);
[bestAgree, bestIdx] = max(meanAgreement);
bestThreshold = chl_thresholds(bestIdx);

% Fraction of days where agreement >= 0.8
above80 = sum(Jaccard >= 0.8, 1, 'omitnan') ./ sum(~isnan(Jaccard),1);
[~, bestIdx80] = max(above80);
bestThreshold80 = chl_thresholds(bestIdx80);

% --- Monthly Jaccard index ---
[monthGroups,~,groupIdx] = unique([year(dates)' month(dates)'],'rows');
nMonths = size(monthGroups,1);

monthlyAgreement = nan(nMonths, length(chl_thresholds));
for m = 1:nMonths
    theseDays = (groupIdx == m);
    monthlyAgreement(m,:) = nanmean(Jaccard(theseDays,:),1);
end

% Month labels
monthlyLabels = datetime(monthGroups(:,1), monthGroups(:,2), 1);

% Best threshold per month
[~, bestIdxMonth] = max(monthlyAgreement,[],2);
bestThresholdByMonth = chl_thresholds(bestIdxMonth);

disp(['Best Chl-a threshold (mean agreement) = ' num2str(bestThreshold) ' mg/m^3']);
disp(['Mean agreement = ' num2str(bestAgree*100) '%']);
disp(['Best Chl-a threshold (>=80% of days) = ' num2str(bestThreshold80) ' mg/m^3']);
disp(['Fraction of days >=0.8 = ' num2str(above80(bestIdx80)*100) '%']);
disp('--- Monthly summary ---');
thres_table = table(monthlyLabels, bestThresholdByMonth', 'VariableNames', {'Month', 'Best Threshold'});

save(fullfile(data_save,'LC_chlor_Jaccard'), "thres_table");

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

function [xout,yout] = uniquePoints(xin,yin)
    [~,ia] = unique([xin(:) yin(:)], 'rows','stable');
    xout = xin(ia);
    yout = yin(ia);
end
