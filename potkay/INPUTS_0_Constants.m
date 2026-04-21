% Physical Constants
sigma = 5.67e-8; %Stefan�Boltzman constant in [W/m^2/K^4]
R = 8.314; %universal gas consant in [J/mol/K]
g = 9.81; %acceleration due to gracity in [m/s^2]

% Properties of water and air
rho = 998; %density of water in [kg/m^3]
m = 18e-3; %molar mass of water in [kg/mol]
V_w = 18e-6; %partial molar volume of water [m3 mol-1]
C_p = 29.2; %molar heat capacity of air in [J/mol/K]
emiss = 0.97; %emissivity of leaf [unitless]
P_atm = 101.325; %atmospheric pressure in [kPa]
g_b = 2.4; %boundary layer conductance to vapor in [mol/m^2/s]

%% Atmospheric conditions
% default
c_a = 410e-6; %atmospheric CO2 in [mol/mol]
o_a = 21/101.325; %atmospheric O2 in [mol/mol]
T_a = 25; %air temperature in [C]
RH_a = 0.4; %relative humidity [unitless]
R_abs = 600; %absorbed shortwave raditation in [W/m^2]
PPFD = 1200e-6; %photon flux density in [mol/m^2/s]

%% Soil Hydraulic Properties
% default
h_soil = -0; %soil hydraulic head in [m]

%% Leaf apoplastic resistance
r_min = 2.5e3; %minimum hydraulic resistance between leaf symplast and apoplast [MPa m2 s mol-1]
r_func = @(P_x_l) r_min*exp(-0.5*P_x_l); %hydraulic resistance between leaf symplast and apoplast [MPa m2 s mol-1]

%% Leaf area
LA = 2e-2; %leaf area in [m2]

%% Temperature-dependence of hydaulic conductances
rel_k_soil_func = @(T_a) 1.25 .^ ((T_a-25)/10); %temperature-dependence of soil conductance[unitless]
rel_k_r_func = @(T_a) 1.60 .^ ((T_a-25)/10); %temperature-dependence of root conductance [unitless]
rel_k_x_func = @(T_a) 1.25 .^ ((T_a-25)/10); %temperature-dependence of xylem conductance[unitless]

%% Soil hydraulic Brooks and Corey parameters
tau_soil = 2.6; %[unitless]
h_soil_star = -25e-2; %in [m]
K_soil_max_25 = 1e-6; %soil saturated conductivity at 25C in [m/s]

%% Root parameters
r_0 = 5e-4; %root radius in [m]
r_b = 1e-2; %rhizosphere radius in [m]
ERL = 10; %effective root length in [m]
k_r_25 = 1e-9; %root (volumetric) conductance at 25C in [m^3/s/MPa]

%% Xylem hydraulic Brooks and Corey parameters
tau_x = 5; %[unitless]
P_x_star = -1.65; %in [MPa]
k_x_max_25 = 1e-9; %xylem (volumetric) conductance at 25C in [m^3/s/MPa]

%% Farquhar photosynthesis parameters
alpha = 0.86; %leaf absorptance [unitless]
V_cmax_25 = 60e-6; %maximum carboxylation capacity at 25C under hydrated conditions in [mol/m^2/s]
J_max_25 = 110e-6; %maximum electron transport rate at 25C under hydrated conditions in [mol/m^2/s]

% Smoothing parameters
theta_c = 0.98; %smoothing parameter for A_n in hyperbolic minimum of A_j and A_c [unitless]
theta_J = 0.90; %smoothing parameter for J in hyperbolic minimum of J_phi and J_max [unitless]

% Temperature Dependence of fluorescence measurements and/or photochemical efficiency of PSII
F_max_fun = @(T_l) 1 + 0*T_l; %temperature dependence of maximum fluorescence
F_ss_fun = @(T_l) 0.75 + 0*T_l; %temperature dependence of steady-state fluorescence
Phi_PSII_func = @(T_l) 1 - F_ss_fun(T_l)./F_max_fun(T_l); %photochemical efficiency of PSII [unitless]

% Temperature Dependence of Farquhar parameters
V_cmax_func = @(T_l) V_cmax_25 * exp(8e4 * (T_l + 273.15 - 290) / 290 / R ./ (T_l + 273.15)); %in [mol CO2 * m^-2 * s^-1]
J_max_func = @(T_l) J_max_25 * exp(8e4 * (T_l + 273.15 - 290) / 290 / R ./ (T_l + 273.15)); %in [mol CO2 * m^-2 * s^-1]
Gamma_star_func = @(T_l) 36e-6 * ones(size(T_l)); %in [mol/mol]
K_c_func = @(T_l) 275e-6 * ones(size(T_l)); %in [mol/mol]
K_o_func = @(T_l) 420000e-6 * ones(size(T_l)); %in [mol/mol]

% Nonstomatal limitations (NSL)
a_c = 2.92; %in [MPa^-1]
P_x_l_c_50 = -2.45; %in [MPa]
a_j = a_c; %in [MPa^-1]
P_x_l_j_50 = P_x_l_c_50; %in [MPa]
NSL_c_func = @(P_x_l) 1 ./ (1 + exp(a_c*(P_x_l_c_50 - P_x_l)));
NSL_j_func = @(P_x_l) 1 ./ (1 + exp(a_j*(P_x_l_j_50 - P_x_l)));

% Respiration
Q10_r = 2;
R_d_25 = 0.01 * V_cmax_func(25); %leaf day respiration at 25C from de Pury and Farquhar (1997) in [mol/m^2/s]
R_d_func = @(T_l) R_d_25 * Q10_r.^((T_l - 25)/10); %in [mol/m^2/s]






