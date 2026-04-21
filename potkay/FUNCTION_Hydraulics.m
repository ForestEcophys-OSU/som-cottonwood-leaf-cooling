function [ P_x_l_vect, P_x_r_vect, P_0_vect, dP_x_ldE_vect] = ...
FUNCTION_Hydraulics(E_vect, m, rho, g, h_soil, T_a, ...
                    LA, r_0, r_b, ERL, k_r_25, ...
                    rel_k_soil_func, rel_k_r_func, rel_k_x_func, ...
                    tau_soil, h_soil_star, K_soil_max_25, ...
                    tau_x, P_x_star, k_x_max_25)

%% Outputs
% FUNCTION_Hydraulics calculates the following variables, assuming immediate refilling:
% P_x_l - Leaf xylem water potential in [MPa]
% P_x_r - Root xylem water potential in [MPa]
% P_0 - Water potential at soil-root surface in [MPa]
% dP_x_ldE - derivative of leaf xylem water potential with respect to transpiration [MPa*m^2*s/mol]

%% Inputs
% m - molar mass of water in [kg/mol]
% rho - density of water in [kg/m^3]
% h_soil - soil hydraulic head in [m]
% LA - leaf area in [m2]
% r_0 - root radius in [m]
% r_b - rhizosphere radius in [m]
% ERL - effective root length in [m]
% k_r_25 - root (volumetric) conductance at 25C in [m^3/s/MPa]
% rel_k_soil_func - temperature dependence for saturated soil conductivity
% rel_k_r_func - temperature dependence for maximum root conductance
% rel_k_x_func - temperature dependence for maximum xylem conductance
% tau_soil - Brooks and Corey exponent for soil conductivity curve
% h_soil_star - hydraulic head at which soil conductivity begins to decrease in [m]
% K_soil_max_25 - soil saturated conductivity at 25C in [m/s]
% tau_x - Brooks and Corey exponent for xylem conductance (vulnerability) curve
% P_x_star - water potential at which xylem conductance begins to decrease in [MPa]
% k_x_max_25 - xylem (volumetric) conductance at 25C in [m^3/s/MPa]

%% Calculations
E_volum_vect = m/rho*LA*E_vect; %volumetric flux in [m^3/s]

K_soil_max = K_soil_max_25*rel_k_soil_func(T_a); %soil saturated conductivity in [m/s]
k_r = k_r_25*rel_k_r_func(T_a); %root volumetric conductance in [m^3/s/MPa]
k_x_max = k_x_max_25*rel_k_x_func(T_a); %xylem maximum volumetric conductance in [m^3/s/MPa]

h_0_vect = -(abs(h_soil)^(1-tau_soil) + E_volum_vect*(1-tau_soil)/2/pi/ERL/K_soil_max/abs(h_soil_star)^tau_soil*(r_b^2*log(r_b/r_0)/(r_b^2 - r_0^2) - 0.5)).^(1/(1-tau_soil)); %in [m]
h_0_vect(abs(imag(h_0_vect)) > 0) = nan; %ignore imaginary/complex numbers
P_0_vect = 1e-6*rho*g*h_0_vect; %in [MPa]
P_x_r_vect = P_0_vect - E_volum_vect/k_r;
P_x_l_vect = -(abs(P_x_r_vect).^(1-tau_x) + E_volum_vect*(1-tau_x)/k_x_max/abs(P_x_star)^tau_x).^(1/(1-tau_x)); %in [MPa]
P_x_l_vect(abs(imag(P_x_l_vect)) > 0) = nan; %ignore imaginary/complex numbers


dh_0dE_volum_vect = -(r_b^2*log(r_b/r_0)/(r_b^2 - r_0^2) - 0.5)/2/pi/ERL/K_soil_max*(h_0_vect/h_soil_star).^tau_soil; 
dP_0dE_volum_vect = 1e-6*rho*g*dh_0dE_volum_vect;
dP_x_rdE_volum_vect = dP_0dE_volum_vect - 1/k_r;
dP_x_ldE_volum_vect = -1/k_x_max*(P_x_l_vect./P_x_star).^tau_x + (P_x_l_vect./P_x_r_vect).^tau_x .* dP_x_rdE_volum_vect;
dP_x_ldE_vect = m/rho*LA*dP_x_ldE_volum_vect;

end

