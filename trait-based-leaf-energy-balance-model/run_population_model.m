function run_population_model(weather_data, ground, population)
    
Tair_C = weather_data.Tair_C;
u_c = weather_data.Wind_ms_1;
RH_c = weather_data.RH_perc;
PAR_c = weather_data.PAR_uM_m2_s;

meteo = [Tair_C u_c PAR_c RH_c];
PAR_limit = meteo(:, 3);
PAR_limit(PAR_limit < 30) = 0;
meteo(:, 3) = PAR_limit;
n = length(meteo);

% % Constant wind speed
% meteo(:, 2) = 1.16 * ones(n, 1);

constant.cp = 29.3;
constant.g = 9.8;
constant.PSII = 0.7;
constant.Phi = 0.3;

g1 = 4.64; % Taken from 'Optimal stomatal behaviour around the world' for Deciduous angiosperm
Ci = 293.552; % intercellular CO2 concentration, set to 0.7 * Ca
leaf_width = 0.0344;
absorb_par = 0.8;
absorb_nir = 0.2;
emissivity = 0.97;
vcmax = 93.88;

if ismember('leaftemp', ground.Properties.VariableNames)
    leaftemp_obs = ground.leaftemp;
    fun = @(g1_val) mean((trait_based_energy_balance_model( ...
        [repmat([leaf_width, absorb_par, absorb_nir, emissivity, vcmax, g1_val], n, 1), ...
        meteo(:, 1), meteo(:, 2), meteo(:, 3)/4.57, meteo(:, 4), 101.3*ones(n,1), 0.1*ones(n,1)], ...
        Ci, constant) - leaftemp_obs).^2);
    g1_opt = fminbnd(fun, 1, 10);
    g1 = g1_opt;
else
    warning('No observed leaftemp found. Using default g1 value.');
end

% How should we model plant responses to drought? An analysis of stomatal  and non-stomatal responses to water stress 2013
% Parameters taken from Quercus ilex tree
a = 6;
b = -0.11;
% a = 3.15;
% b = 0.15;
g1_func = @(PD) a * exp(b * -PD);

PD_range = linspace(3, 0, 100);
g1_values = g1_func(PD_range);

figure;
plot(PD_range, g1_values, 'LineWidth', 2);
xlabel('Predawn Pressure (-MPa)');
ylabel('g1');
title(['g1 as a Function of Predawn Pressure: ' char(population)]);
grid on;

params = [
    leaf_width, absorb_par, absorb_nir, emissivity, vcmax, g1
];
params = repmat(params, n, 1);

g1_pred = zeros(n, 1);
last_g1 = g1;
if ismember('P_PD', ground.Properties.VariableNames)
    for i = 1:n
        if i <= height(ground) && ~isnan(ground.P_PD(i))
            last_g1 = g1_func(ground.P_PD(i));
        end
        g1_pred(i) = last_g1;
    end
else
    g1_pred(:) = g1;
end
params(:, 6) = g1_pred;

weather = [meteo(:, 1) meteo(:, 2) meteo(:, 3)/4.57 meteo(:, 4) 101.3*ones(n,1) 0.1*ones(n,1)];
X = [params weather];

leaftemp = zeros(n, 1);
gs = zeros(n, 1);
for i=1:n
    [i_leaftemp, i_gs] = trait_based_energy_balance_model(X(i, :), Ci, constant);
    leaftemp(i) = i_leaftemp;
    gs(i) = i_gs;
end

output = readtable("output-template.csv");

% Make a copy of X and convert to table with column names
X_table = [output.year output.julian_day output.standard_time X];
X_table = array2table(X_table, 'VariableNames', ...
    {'year', 'julian-day', 'standard-time', 'leaf_width', 'absorb_par', 'absorb_nir', 'emissivity', 'vcmax', 'g1', ...
     'Tair_C', 'Wind_ms_1', 'PAR_mol_m2_s', 'RH_perc', 'Pressure_kPa', 'SoilMoist'});
writetable(X_table, ['trait-based-leaf-energy-balance-model/input_table_' char(population) '.csv']);

output.leaftemp = leaftemp;
output.GW = gs;
output.leaf_air_temp_diff = leaftemp - Tair_C;

outfilename = sprintf("trait-based-leaf-energy-balance-model/leaftemp-output-%s.csv", char(population));
writetable(output, outfilename);

year = output.year;
jday = output.julian_day;
std_time = output.standard_time;

date0 = datetime(year,1,1) + days(jday-1);
if isnumeric(std_time)
    std_time = string(std_time);
end
dt = datetime(string(date0,'yyyy-MM-dd') + " " + std_time, 'InputFormat', 'yyyy-MM-dd HH');
hours = hour(dt);
idx_days = dateshift(dt, 'start', 'day');
idx = hours >= 14 & hours <= 18;
[G, dayList] = findgroups(idx_days(idx));
avg_leaf_to_air_diff = splitapply(@mean, leaftemp(idx) - Tair_C(idx), G);

if ismember('leaftemp', ground.Properties.VariableNames)
    leaftemp_obs = ground.leaftemp;
    avg_leaf_to_air_diff_obs = splitapply(@mean, leaftemp_obs(idx) - ground.Tair_C(idx), G);
    figure;
    plot(dayList, avg_leaf_to_air_diff, 'b-', 'LineWidth', 2); hold on;
    plot(dayList, avg_leaf_to_air_diff_obs, 'ro-', 'LineWidth', 1.5);
    xlabel('Date');
    tick_idx = 1:7:length(dayList);
    set(gca, 'XTick', dayList(tick_idx));
    datetick('x','yyyy-mm-dd','keepticks');
    target_date = datetime(2023, 8, 26);
    tick_start = datetime(2023, 7, 24);
    tick_idx = find(dayList >= tick_start);
    tick_idx = tick_idx(1):7:length(dayList);
    set(gca, 'XTick', dayList(tick_idx));
    datetick('x','yyyy-mm-dd','keepticks');
    [~, idx_vline] = min(abs(dayList - target_date));
    xline(idx_vline, '--r', 'Drought', 'LabelOrientation', 'horizontal', 'LabelVerticalAlignment', 'bottom');
    xtickangle(45);
    ylabel('Leaf-Air Temperature Difference (°C)');
    legend('Modeled', 'Observed');
    title(['Leaf to Air Temperature Difference: Modeled vs Observed (' char(population) ')']);
    grid on;
else
    warning('No observed leaftemp found in ground data. Skipping observed plot.');
    figure;
    plot(avg_leaf_to_air_diff);
    xlabel('Date');
    tick_idx = 1:7:length(dayList);
    hold off;
    set(gca, 'XTick', tick_idx, 'XTickLabel', datestr(dayList(tick_idx), 'yyyy-mm-dd'));
    target_date = datetime(2023, 8, 26);
    [~, idx_vline] = min(abs(dayList - target_date));
    xline(idx_vline, '--r', 'Drought', 'LabelOrientation', 'horizontal', 'LabelVerticalAlignment', 'bottom');
    xtickangle(45);
    ylabel('Leaf-Air Temperature Difference (°C)');
    title(['Leaf to Air Temperature Difference Over Time (' char(population) ')']);
    grid on;
end