% MATLAB animation showing correlation vs lag for two similar signals

clc; clear; close all;

% Time vector
t = linspace(0, 4*pi, 400);
x = sin(t);         % Reference signal
lag_true = 50;      % True lag in indices
y = circshift(x, lag_true); % Shifted signal

fig = figure('Position',[100 100 800 400]);
ax = axes('Parent', fig);
hold on;
line1 = plot(t, x, 'b-', 'LineWidth', 2, 'DisplayName', 'x (reference)');
line2 = plot(t, y, 'r-', 'LineWidth', 2, 'DisplayName', 'y (lagged)');
legend('Location','northeast');
ylim([-1.5 1.5])
xlabel('Time')
ylabel('Amplitude')
title('Correlation between x and shifted y signals')

lag_text = text(min(t), 1.3, '', 'FontSize', 14);
corr_text = text(min(t), 1.1, '', 'FontSize', 14);

for shift = 0:length(t)-1
    % Shift y by 'shift' backward (circular)
    y_shifted = circshift(y, -shift);
    
    % Update y plot
    set(line2, 'YData', y_shifted)
    
    % Compute correlation at this lag (exclude NaNs if any)
    r = corrcoef(x', y_shifted');
    corr_val = r(1,2);
    
    % Update texts
    lag_text.String = sprintf('Lag = %d samples', shift);
    corr_text.String = sprintf('Correlation = %.2f', corr_val);
    
    pause(0.05)
    
    if ~isvalid(fig)  % Exit if figure closed
        break
    end
end
