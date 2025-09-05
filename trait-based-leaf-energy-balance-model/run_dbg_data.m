% Clear items and terminal
clear
clc

% Read in weather data
weather_data = 'dataset_with_rh_and_par.csv';
weather_data = readtable(weather_data);

Tair_C = weather_data.Tair_C;
u_c = weather_data.Wind_ms_1 .* 3.6;  % m/s to km/h
RH_c = weather_data.RH_perc;
PAR_c = weather_data.PAR_uM_m2_s;

% All weather inputs
meteo = [Tair_C u_c PAR_c RH_c];

PAR_limit = meteo(:, 3);
PAR_limit(PAR_limit < 30) = 0; % PAR < 30, no photosynthesis
meteo(:, 3) = PAR_limit;

constant.cp=29.3; % J/mol/? specific heat capacity of air
constant.g=9.8; % m/s^2 gravitational constant

n = length(meteo);  % get total number of weather observations

params = [
    0.0344,  % leaf width (m)
    0.8,     % absorb_PAR
    0.2,     % absorb_NIR
    0.97,    % emissivity
    93.88,   % Vcmax25
    4.64     % Taken from 'Optimal stomatal behaviour around the world' for Deciduous angiosperm
];

params = repmat(params', n, 1);

weather = [meteo(:, 1) 1.16*ones(n) meteo(:, 3)/4.57 meteo(:, 4) 101.3*ones(n) 0.1*ones(n)];
X = [params weather];
Ci = 400;  % intercellular CO2 concentration, need to estimate

[leaftemp, gs] = trait_based_energy_balance_model(X, Ci, constant);

output = readtable("output-template.csv");

output.leaftemp = leaftemp;
output.GW = gs;
output.leaf_air_temp_diff = leaftemp - Tair_C;

writetable(output, "trait-based-leaf-energy-balance-model/leaftemp-output.csv");

%% Get averages and plot leaf-air-temp-diff
% Combine year, julian-day, and standard-time into datetime
year = output.year;
jday = output.julian_day;
std_time = output.standard_time; % assumed as 'HH:MM' or 'HH:MM:SS'

% Convert julian day to date
date0 = datetime(year,1,1) + days(jday-1);

% If standard_time is numeric, convert to string
if isnumeric(std_time)
    std_time = string(std_time);
end

% Combine date and time
dt = datetime(string(date0,'yyyy-MM-dd') + " " + std_time, 'InputFormat', 'yyyy-MM-dd HH');

% Extract hour and day
hours = hour(dt);
days = dateshift(dt, 'start', 'day');

% Logical index for hours between 14 and 18 (inclusive of 14, exclusive of 18)
idx = hours >= 14 & hours < 18;

% Group by day and calculate mean for each day in the specified hours
[G, dayList] = findgroups(days(idx));
avg_leaf_to_air_diff = splitapply(@mean, leaftemp(idx) - Tair_C(idx), G);

figure;
plot(avg_leaf_to_air_diff);
xlabel('Time Step');
ylabel('Leaf-Air Temperature Difference (°C)');
title('Leaf to Air Temperature Difference Over Time');
grid on;
%%