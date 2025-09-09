% Clear items and terminal
clear
clc

% Read in weather data
weather_data = 'dataset_with_rh_and_par.csv';
weather_data = readtable(weather_data);

% index_day = weather_data.Day == 241;
% weather_data = weather_data(index_day, :);

% Read in ground data
% pops = ["ccr" "jla" "tsz" "nrv"];
pops = ["ccr"];

for i = 1:length(pops)
    population = pops(i);
    fprintf("Running for population %s.", population)
    ground_file = sprintf('%s_hourly_data.csv', population);
    ground = readtable(ground_file);

    run_population_model(weather_data, ground, population);
end









% ground = 'ccr_hourly_data.csv';
% ground = readtable(ground);

% % ground = ground(index_day, :);

% Tair_C = weather_data.Tair_C;
% u_c = weather_data.Wind_ms_1;
% RH_c = weather_data.RH_perc;
% PAR_c = weather_data.PAR_uM_m2_s;

% % All weather inputs
% meteo = [Tair_C u_c PAR_c RH_c];

% PAR_limit = meteo(:, 3);
% PAR_limit(PAR_limit < 30) = 0; % PAR < 30, no photosynthesis
% meteo(:, 3) = PAR_limit;

% n = length(meteo);  % get total number of weather observations

% % Constant wind speed
% % meteo(:, 2) = 1.16 * ones(n, 1);

% % Calculate average wind speed for each day and assign to all hours of that day
% % day_numbers = weather_data.Day; % assuming 'Day' is the julian day column
% % unique_days = unique(day_numbers);
% % avg_wind_per_day = zeros(size(day_numbers));

% % for d = 1:length(unique_days)
% %     idx = day_numbers == unique_days(d);
% %     avg_wind = median(u_c(idx));
% %     avg_wind_per_day(idx) = avg_wind;
% % end

% % meteo(:, 2) = avg_wind_per_day;

% constant.cp=29.3; % J/mol/? specific heat capacity of air
% constant.g=9.8; % m/s^2 gravitational constant
% constant.PSII = 0.7;  % input PSII for maximum quantum yield
% constant.Phi = 0.3;  % input Phi for curvature factor for light response function, originally 0.7

% g1 = 4.64;  % Taken from 'Optimal stomatal behaviour around the world' for Deciduous angiosperm
% Ci = 293.552;  % intercellular CO2 concentration, set to 0.7 * Ca
% leaf_width = 0.0344;
% absorb_par = 0.8;
% absorb_nir = 0.2;
% emissivity = 0.97;
% vcmax = 93.88;

% % Optimize g1 to minimize mean squared error between model leaftemp and observed (if available)
% % If no observed leaftemp, optimize for another criterion as needed

% % Example: Assume observed leaftemp is available as weather_data.leaftemp_obs
% if ismember('leaftemp', ground.Properties.VariableNames)
%     leaftemp_obs = ground.leaftemp;
%     fun = @(g1_val) mean((trait_based_energy_balance_model( ...
%         [repmat([leaf_width, absorb_par, absorb_nir, emissivity, vcmax, g1_val], n, 1), ...
%         meteo(:, 1), meteo(:, 2), meteo(:, 3)/4.57, meteo(:, 4), 101.3*ones(n,1), 0.1*ones(n,1)], ...
%         Ci, constant) - leaftemp_obs).^2);
%     g1_opt = fminbnd(fun, 1, 10); % bounds based on literature
%     g1 = g1_opt;
% else
%     warning('No observed leaftemp found. Using default g1 value.');
% end

% fprintf("Optimized g1 is: %f\n", g1)

% % How should we model plant responses to drought? An analysis of stomatal  and non-stomatal responses to water stress 2013
% % g1 = a * exp(b * PD), where PD is predawn pressure
% % median Sclerophyll angiosperm tree b = 0.15 g1* = 3.15 (g1 under moist conditions)
% % Anonymous function for g1 as a function of predawn pressure (PD)
% % Example: median Sclerophyll angiosperm tree b = 0.15, g1* = 3.15
% % We don't have Anet measurements so we cannot estimate g1 to fit a and b
% % So let's just use best guess from the paper.
% % a = 3.15;
% a = 6;
% % a = 1;
% % b = 0.15;
% b = -0.11;
% % b = 0.5;
% g1_func = @(PD) a * exp(b * PD);

% % % Interpolate PD values across time to fill missing values
% % if ismember('P_PD', ground.Properties.VariableNames)
% %     PD_obs = ground.P_PD;
% %     % Interpolate missing PD values linearly
% %     PD_interp = fillmissing(PD_obs, 'linear', 'EndValues', 'nearest');
% %     % If still NaN at ends, fill with nearest non-NaN value
% %     if any(isnan(PD_interp))
% %         PD_interp = fillmissing(PD_interp, 'nearest');
% %     end
% %     ground.P_PD = PD_interp;
% % else
% %     warning('No P_PD found in ground data.');
% % end

% % % Optimize a and b in g1_func to minimize mean squared error between model leaftemp and observed leaftemp
% % if ismember('leaftemp', ground.Properties.VariableNames) && ismember('P_PD', ground.Properties.VariableNames)
% %     leaftemp_obs = ground.leaftemp;
% %     PD_obs = ground.P_PD;
% %     % Only use rows where both leaftemp and PD are not NaN
% %     valid_idx = ~isnan(leaftemp_obs) & ~isnan(PD_obs);
% %     leaftemp_obs = leaftemp_obs(valid_idx);
% %     PD_obs = PD_obs(valid_idx);
% %     meteo_valid = meteo(valid_idx, :);
% %     n_valid = sum(valid_idx);

% %     % Optimization function for a and b
% %     fun = @(ab) mean(arrayfun(@(i) ...
% %                 (trait_based_energy_balance_model( ...
% %                 [leaf_width, absorb_par, absorb_nir, emissivity, vcmax, ab(1)*exp(ab(2)*PD_obs(i)), ...
% %                  meteo_valid(i, 1), meteo_valid(i, 2), meteo_valid(i, 3)/4.57, meteo_valid(i, 4), 101.3, 0.1], ...
% %                 Ci, constant) - leaftemp_obs(i)).^2, 1:n_valid));

% %     ab0 = [a, b];
% %     lb = [0, -2]; % lower bounds for a and b
% %     ub = [10, 2]; % upper bounds for a and b
% %     opts = optimset('Display','off');
% %     ab_opt = fminsearchbnd(fun, ab0, lb, ub, opts);

% %     a = ab_opt(1);
% %     b = ab_opt(2);
% %     g1_func = @(PD) a * exp(b * PD);
% %     fprintf("Optimized a: %f, b: %f\n", a, b)
% % else
% %     warning('leaftemp or P_PD not found in ground data. Skipping a/b optimization.');
% % end

% % Optimized a: 1.106902, b: 1.996412

% % Plot g1_func from P-PD = -3 to 0
% PD_range = linspace(-3, 0, 100);
% g1_values = g1_func(PD_range);

% figure;
% plot(PD_range, g1_values, 'LineWidth', 2);
% xlabel('Predawn Pressure (MPa)');
% ylabel('g1');
% title('g1 as a Function of Predawn Pressure');
% grid on;

% % CCR parameters
% params = [
%     leaf_width,  ... leaf width (m)
%     absorb_par,     ... absorb_PAR
%     absorb_nir,     ... absorb_NIR
%     emissivity,    ... emissivity
%     vcmax,   ... Vcmax25
%     g1
% ];

% params = repmat(params, n, 1);

% % Predict g1 for each timestep using ground.PD if available, else use last known g1
% g1_pred = zeros(n, 1);
% last_g1 = g1; % start with default g1

% if ismember('P_PD', ground.Properties.VariableNames)
%     for i = 1:n
%         if i <= height(ground) && ~isnan(ground.P_PD(i))
%             last_g1 = g1_func(ground.P_PD(i));
%         end
%         g1_pred(i) = last_g1;
%     end
% else
%     g1_pred(:) = g1; % fallback: use default g1 for all
% end

% params(:, 6) = g1_pred;

% weather = [meteo(:, 1) meteo(:, 2) meteo(:, 3)/4.57 meteo(:, 4) 101.3*ones(n,1) 0.1*ones(n,1)];
% X = [params weather];

% leaftemp = zeros(n, 1);
% gs = zeros(n, 1);

% % Iterate through timesteps since batched evaluation doesn't work
% for i=1:n
%     [i_leaftemp, i_gs] = trait_based_energy_balance_model(X(i, :), Ci, constant);
%     leaftemp(i) = i_leaftemp;
%     gs(i) = i_gs;
% end

% output = readtable("output-template.csv");

% % output = output(index_day, :);

% output.leaftemp = leaftemp;
% output.GW = gs;
% output.leaf_air_temp_diff = leaftemp - Tair_C;

% writetable(output, "trait-based-leaf-energy-balance-model/leaftemp-output.csv");

% %% Get averages and plot leaf-air-temp-diff
% % Combine year, julian-day, and standard-time into datetime
% year = output.year;
% jday = output.julian_day;
% std_time = output.standard_time; % assumed as 'HH:MM' or 'HH:MM:SS'

% % Convert julian day to date
% date0 = datetime(year,1,1) + days(jday-1);

% % If standard_time is numeric, convert to string
% if isnumeric(std_time)
%     std_time = string(std_time);
% end

% % Combine date and time
% dt = datetime(string(date0,'yyyy-MM-dd') + " " + std_time, 'InputFormat', 'yyyy-MM-dd HH');

% % Extract hour and day
% hours = hour(dt);
% days = dateshift(dt, 'start', 'day');

% % Logical index for hours between 14 and 18 (inclusive of 14, inclusive of 18)
% idx = hours >= 14 & hours <= 18;

% % Group by day and calculate mean for each day in the specified hours
% [G, dayList] = findgroups(days(idx));
% avg_leaf_to_air_diff = splitapply(@mean, leaftemp(idx) - Tair_C(idx), G);

% % Calculate and plot observed leaf-air temperature difference from ground data (if available)
% if ismember('leaftemp', ground.Properties.VariableNames)
%     leaftemp_obs = ground.leaftemp;

%     avg_leaf_to_air_diff_obs = splitapply(@mean, leaftemp_obs(idx) - ground.Tair_C(idx), G);

%     % Plot both modeled and observed
%     figure;
%     plot(dayList, avg_leaf_to_air_diff, 'b-', 'LineWidth', 2); hold on;
%     plot(dayList, avg_leaf_to_air_diff_obs, 'ro-', 'LineWidth', 1.5);
%     xlabel('Date');
%     tick_idx = 1:7:length(dayList);
%     set(gca, 'XTick', dayList(tick_idx));
%     datetick('x','yyyy-mm-dd','keepticks');
%     target_date = datetime(2023, 8, 26);
%     % Set x-ticks to start from July 24th
%     tick_start = datetime(2023, 7, 24);
%     tick_idx = find(dayList >= tick_start);
%     tick_idx = tick_idx(1):7:length(dayList);
%     set(gca, 'XTick', dayList(tick_idx));
%     datetick('x','yyyy-mm-dd','keepticks');
%     [~, idx_vline] = min(abs(dayList - target_date));
%     xline(idx_vline, '--r', 'Drought', 'LabelOrientation', 'horizontal', 'LabelVerticalAlignment', 'bottom');
%     xtickangle(45);
%     ylabel('Leaf-Air Temperature Difference (°C)');
%     legend('Modeled', 'Observed');
%     title('Leaf to Air Temperature Difference: Modeled vs Observed');
%     grid on;
% else
%     warning('No observed leaftemp found in ground data. Skipping observed plot.');

%     figure;
%     plot(avg_leaf_to_air_diff);
%     xlabel('Date');
%     tick_idx = 1:7:length(dayList);
%     hold off;
%     set(gca, 'XTick', tick_idx, 'XTickLabel', datestr(dayList(tick_idx), 'yyyy-mm-dd'));
%     % Add vertical line for August 26, 2023
%     target_date = datetime(2023, 8, 26);
%     [~, idx_vline] = min(abs(dayList - target_date));
%     xline(idx_vline, '--r', 'Drought', 'LabelOrientation', 'horizontal', 'LabelVerticalAlignment', 'bottom');
%     xtickangle(45);
%     ylabel('Leaf-Air Temperature Difference (°C)');
%     title('Leaf to Air Temperature Difference Over Time');
%     grid on;
%     %%
% end