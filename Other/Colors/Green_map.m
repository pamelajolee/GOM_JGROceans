%% White to green colormap used for Fig1 and Panels

savepath = '/Volumes/PamelaResearch/Luna_project/GoM_data/Colors';

% Number of steps in the gradient
n = 500;

% --- White → Forest Green map (your original) ---
startColor = [1, 1, 1];            % white
endColor   = [0.03 0.32 0.03];     % forest green

r = linspace(startColor(1), endColor(1), n)';
g = linspace(startColor(2), endColor(2), n)';
b = linspace(startColor(3), endColor(3), n)';

Green_color = [r, g, b];

% Save
save(fullfile(savepath, 'Green_map.mat'), 'Green_color');


%% Diverging colormap: Dark Teal to White to Forest Green

% Define colors
tealColor   = [0.0 0.3 0.3];       % dark teal
whiteColor  = [1, 1, 1];
greenColor  = [0.03 0.32 0.03];    % forest green

% Half steps
n_half = floor(n/2);

% Teal → White
r1 = linspace(tealColor(1), whiteColor(1), n_half)';
g1 = linspace(tealColor(2), whiteColor(2), n_half)';
b1 = linspace(tealColor(3), whiteColor(3), n_half)';

% White → Green
r2 = linspace(whiteColor(1), greenColor(1), n_half)';
g2 = linspace(whiteColor(2), greenColor(2), n_half)';
b2 = linspace(whiteColor(3), greenColor(3), n_half)';

% Combine both halves
Diverging_green = [r1 g1 b1; r2 g2 b2];

% Save
save(fullfile(savepath, 'Diverging_green_map.mat'), 'Diverging_green');


%% Preview Section: Show colorbars

figure;

% White → Green
subplot(2,1,1)
imagesc(linspace(0,1,n));     
colormap(gca, Green_color);
colorbar;
title('White → Forest Green');

% Teal to White to  Green
subplot(2,1,2)
imagesc(linspace(-1,1,2*n_half));  
colormap(gca, Diverging_green);
colorbar;
title('Diverging: Teal → White → Forest Green');
