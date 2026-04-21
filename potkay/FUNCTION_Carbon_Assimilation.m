function [ A_n_vect, R_d_vect, lambda_vect ] = ...
FUNCTION_Carbon_Assimilation(g_c_vect, T_l_vect, ...
                             alpha, PPFD, Phi_PSII_func, ...
                             theta_J, theta_c, ...
                             V_cmax_func, J_max_func, Gamma_star_func, ...
                             K_c_func, K_o_func, R_d_func, c_a, o_a, ...
                             C_p, emiss, sigma, L, g_b, ...
                             dEdg_w_vect, dg_wdg_c_vect, ...
                             NSL_c_func, NSL_j_func, ...
                             P_x_l_vect, dP_x_ldE_vect)

%% Inputs - Constants
% alpha - leaf absorptance [unitless]
% theta_J - smoothing parameter for A_n in hyperbolic minimum of A_j and A_c [unitless]
% theta_c - smoothing parameter for J in hyperbolic minimum of J_phi and J_max [unitless]
% C_p - molar heat capacity of air in [J/mol/K]
% emiss - emissivity of leaf [unitless]
% sigma - Stefan–Boltzman constant in [W/m^2/K^4]

%% Inputs - Environmental Conditions
% PPFD - photon flux density in [mol/m^2/s]
% c_a - atmospheric CO2 in [mol/mol]
% o_a - atmospheric O2 in [mol/mol]
% g_b - boundary layer conductance to vapor in [mol/m^2/s]

%% Inputs - Temperature-dependent local functions
% V_cmax_func - maximum carboxylation capacity under hydrated conditions in [mol/m^2/s]
% J_max_func - maximum electron transport rate under hydrated conditions in [mol/m^2/s]
% Gamma_star_func - CO2 compensation point [mol/mol]
% K_c_func - Michaelis-Menten coefficient for carboxylation [mol/mol]
% K_o_func - Michaelis-Menten coefficient for oxygenation [mol/mol]
% R_d_func - day respiration in [mol/m^2/s]
% Phi_PSII_func - photochemical efficiency of PSII [unitless]

%% Inputs - Leaf water potential-dependent local functions
% NSL_c_func - "Non-Stomatal Limitation" function for carboxylation that modifies V_cmax [unitless]
% NSL_j_func - "Non-Stomatal Limitation" function for carboxylation that modifies J_max [unitless]

%% Inputs - previously calculated variables ['vect' indicates a vector of values]
% L - latent heat of vaporization in [J/kg]
% g_c_vect - total conductance to CO2 in [mol/m^2/s]
% T_l_vect - leaf temperature in [C]
% dEdg_w_vect - derivative of transpiration with respect to stomatal conductance to vapor [unitless]
% dg_wdg_c_vect - derivative of stomatal conductance to vapor with respect to total conductance to CO2 [unitless]
% P_x_l_vect - leaf water potential in [MPa]
% dP_x_ldE_vect - derivative of leaf water potential with respect to transpiration in [MPa*m^2*s/mol]


%% Calculculations
% Gross Assimilation variables
V_cmax_vect = V_cmax_func(T_l_vect) .* NSL_c_func(P_x_l_vect); %in[mol CO2 * m^-2 * s^-1]
J_max_vect = J_max_func(T_l_vect) .* NSL_j_func(P_x_l_vect); %in [mol CO2 * m^-2 * s^-1]
Phi_PSII_vect = Phi_PSII_func(T_l_vect); %photochemical efficiency of PSII [unitless]
J_phi_vect = alpha/2 * Phi_PSII_vect * PPFD; %in [mol CO2 * m^-2 * s^-1]
J_vect = (J_max_vect + J_phi_vect)/(2*theta_J) - (((J_max_vect + J_phi_vect)/(2*theta_J)).^2 - J_max_vect.*J_phi_vect/theta_J).^0.5; %hyperbolic minimum of J_max and J_phi with curvature of 0.9
Gamma_star_vect = Gamma_star_func(T_l_vect); %in [kPa]
K_c_vect = K_c_func(T_l_vect); %in [kPa]
K_o_vect = K_o_func(T_l_vect); %in [kPa]

% Respiration
R_d_vect = R_d_func(T_l_vect); %leaf day respiration in [mol CO2 * m^-2 * s^-1]

% Local functions for A_c and A_j
A_c_func = @(g_c, A_n, c_a, V_cmax, Gamma_star, R_d, K_c, K_o, o_a ) ...
           V_cmax .* (c_a - A_n./g_c - Gamma_star)./(c_a - A_n./g_c + K_c.*(1+o_a./K_o)) - R_d; %in [mol CO2 * m^-2 * s^-1]
A_j_func = @(g_c, A_n, c_a, J, Gamma_star, R_d ) ...
           J/4 .* (c_a - A_n./g_c - Gamma_star)./(c_a - A_n./g_c + 2*Gamma_star) - R_d; %in [mol CO2 * m^-2 * s^-1]

n = length(g_c_vect);
n_stop = find(~isnan(P_x_l_vect), 1, 'last');
A_n_vect = nan(1,n);
for i = 1:n_stop
    
    g_c_i = g_c_vect(i);
    V_cmax_i = V_cmax_vect(i);
    J_i = J_vect(i); 
    Gamma_star_i = Gamma_star_vect(i);
    R_d_i = R_d_vect(i);
    K_c_i = K_c_vect(i);
    K_o_i = K_o_vect(i); 
    
    if g_c_i == 0
        
        %if zero conductance 
        if J_i < 1e-16 
            %if no light (i.e., A_n = 0)
            A_n_vect(i) = -R_d_i;
        else
            %if there is light (i.e., A_n > 0)
            A_n_vect(i) = 0;
        end
        
    elseif g_c_i < 0
        
        %if negative conductance -- unrealistic
        A_n_vect(i) = nan;
        
    elseif J_i < 1e-16
        
        %if no light (i.e., A_n = 0)
        A_n_vect(i) = -R_d_i; 
        
    else
        
        %otherwise solve
        A_n_max = min(max(V_cmax_i, J_i/4), g_c_i*c_a);

        A_n_LB = -R_d_i;
        A_n_UB = A_n_max;
        A_n_M = (A_n_LB + A_n_UB)/2;
        A_n_i = [A_n_LB, A_n_M, A_n_UB];

        j = 0;
        while 1

            j = j + 1;
            if j > 1e2
                error('ERROR')
            end

            A_c_i = A_c_func(g_c_i, A_n_i, c_a, V_cmax_i, Gamma_star_i, R_d_i, K_c_i, K_o_i, o_a );
            A_j_i = A_j_func(g_c_i, A_n_i, c_a, J_i, Gamma_star_i, R_d_i );
            A_n_hypmin = (A_c_i + A_j_i)/(2*theta_c) - (((A_c_i + A_j_i)/(2*theta_c)).^2 - A_c_i.*A_j_i/theta_c).^0.5; 
            F = (A_n_i - A_n_hypmin) ./ A_n_max;

            if any(abs(F) < 1e-4)
                break
            end

            %%% Upper and Lower Bounds
            F_UB = min(F(F > 0));
            F_UB = F_UB(1); 
            F_LB = max(F(F < 0));
            F_LB(isempty(F_LB)) = nan; 
            F_LB = F_LB(1);

            A_n_LB = A_n_i(F == F_LB);
            A_n_LB = min(A_n_LB);
            A_n_LB(isnan(F_LB)) = -R_d_i;
            A_n_UB = A_n_i(F == F_UB);
            A_n_UB = max(A_n_UB);
            if A_n_LB == A_n_UB
                if (A_n_UB == -R_d_i) && (A_n_LB == -R_d_i)
                    break
                else
                    error('ERROR: Photosynthesis module cannot converge on A_n!!!')
                end
            end
            A_n_M = (A_n_LB + A_n_UB)/2;
            A_n_i = [A_n_LB, A_n_M, A_n_UB];

        end

        A_n_i = A_n_i(abs(F) == min(abs(F)));
        if isnan(A_n_i)
            error('ERROR: NaN in ''A_n''!!!')
        end
        A_n_vect(i) = A_n_i;
        
    end
    
end

% solve for interal CO2 and check for positive internal CO2
c_i_vect = c_a - A_n_vect ./ g_c_vect;
if any(c_i_vect(2:end) < 0)
   error('ERROR!!!') 
end 
% assuming limited by carboylation at low c_i
c_i_min_vect = (R_d_vect.*K_c_vect.*(1+o_a./K_o_vect) + V_cmax_vect.*Gamma_star_vect)./(V_cmax_vect - R_d_vect);
A_c_gross_0 = V_cmax_vect .* (c_i_min_vect - Gamma_star_vect)./(c_i_min_vect + K_c_vect.*(1+o_a./K_o_vect)); 
if (J_vect(g_c_vect == 0)/4) < A_c_gross_0(g_c_vect == 0)
    c_i_min_vect(g_c_vect == 0) = inf; 
end
c_i_vect(g_c_vect == 0) = c_i_min_vect(g_c_vect == 0);

A_c_vect = A_c_func(g_c_vect, A_n_vect, c_a, V_cmax_vect, Gamma_star_vect, R_d_vect, K_c_vect, K_o_vect, o_a );
A_c_vect(g_c_vect == 0) = 0;
A_j_vect = A_j_func(g_c_vect, A_n_vect, c_a, J_vect, Gamma_star_vect, R_d_vect );
A_j_vect(g_c_vect == 0) = 0;

dA_ndA_c_vect = (1 - (A_c_vect + (1-2*theta_c)*A_j_vect)./((A_c_vect+A_j_vect).^2 - 4*theta_c*A_c_vect.*A_j_vect).^0.5) / (2*theta_c);
dA_ndA_j_vect = (1 - (A_j_vect + (1-2*theta_c)*A_c_vect)./((A_c_vect+A_j_vect).^2 - 4*theta_c*A_c_vect.*A_j_vect).^0.5) / (2*theta_c);
% A_n = A_c and A_j = 0 where A_n = 0, assuming limited by carboylation at low c_i,   
dA_ndA_c_vect(g_c_vect == 0) = 0;
dA_ndA_j_vect(g_c_vect == 0) = 1;

% Slope of biochemical supply curve with respect to c_i for each mode of photosynthesis
dA_cdc_i_vect = V_cmax_vect .* (Gamma_star_vect + K_c_vect.*(1+o_a./K_o_vect)) ./ (c_i_vect + K_c_vect.*(1+o_a./K_o_vect)).^2;
dA_jdc_i_vect = 0.75 * J_vect .* Gamma_star_vect ./ (c_i_vect + 2*Gamma_star_vect).^2;

% Canopy-level slope of biochemical supply curve with respect to c_i
k_vect = dA_ndA_c_vect .* dA_cdc_i_vect + dA_ndA_j_vect .* dA_jdc_i_vect; 

% Canopy level slope of biochemical supply curve with respect to T_l
dJdJ_max_vect = (1 - (J_max_vect + (1-2*theta_J)*J_phi_vect)./((J_max_vect+J_phi_vect).^2 - 4*theta_J*J_max_vect.*J_phi_vect).^0.5) / (2*theta_J);
dJdJ_phi_vect = (1 - (J_phi_vect + (1-2*theta_J)*J_max_vect)./((J_max_vect+J_phi_vect).^2 - 4*theta_J*J_max_vect.*J_phi_vect).^0.5) / (2*theta_J);
dT_l = 0.01;
dV_cmaxdT_l_vect = (V_cmax_func(T_l_vect + dT_l) .* NSL_c_func(P_x_l_vect) - V_cmax_vect) / dT_l;
dJ_maxdT_l_vect = (J_max_func(T_l_vect + dT_l) .* NSL_j_func(P_x_l_vect) - J_max_vect) / dT_l;
dJ_phidT_l_vect = alpha/2 * PPFD * (Phi_PSII_func(T_l_vect + dT_l) - Phi_PSII_vect) / dT_l;
dR_ddT_l_vect = (R_d_func(T_l_vect + dT_l) - R_d_vect) / dT_l;
dA_cdV_cmax_vect = (A_c_vect + R_d_vect)./V_cmax_vect;
dA_jdJ_vect = 0.25*(c_i_vect - Gamma_star_vect)./(c_i_vect + 2*Gamma_star_vect);
dA_jdJ_vect(c_i_vect == inf) = 0.25; 
xi_vect = dA_ndA_c_vect .* (dA_cdV_cmax_vect.*dV_cmaxdT_l_vect - dR_ddT_l_vect) + ...
          dA_ndA_j_vect .* (dA_jdJ_vect.*dJdJ_max_vect.*dJ_maxdT_l_vect - dR_ddT_l_vect + ...
                            dJdJ_phi_vect.*dJdJ_phi_vect.*dJ_phidT_l_vect);

% Canopy level slope of biochemical supply curve with respect to P_x_l (i.e., nonstomatal limitations; NSL)
dP_x_l = 0.01;
dlnNSL_cdP_x_l_vect = (NSL_c_func(P_x_l_vect + dP_x_l) - NSL_c_func(P_x_l_vect)) / dP_x_l;
dlnNSL_jdP_x_l_vect = (NSL_j_func(P_x_l_vect + dP_x_l) - NSL_j_func(P_x_l_vect)) / dP_x_l;
dA_ndP_x_l_vect = dA_ndA_c_vect .* (A_c_vect + R_d_vect) .* dlnNSL_cdP_x_l_vect + ...
                  dA_ndA_j_vect .* (A_j_vect + R_d_vect) .* dJdJ_max_vect .* J_max_vect ./ J_vect .* dlnNSL_jdP_x_l_vect;
dA_ndP_x_l_vect(A_n_vect == -R_d_vect) = 0; 

% correction where multiplying 0 by infinity
dA_ndP_x_l_time_dP_x_ldE_vect = dA_ndP_x_l_vect .* dP_x_ldE_vect;
dA_ndP_x_l_time_dP_x_ldE_vect(dA_ndP_x_l_vect == 0) = 0;

% marginal water-use efficiency, lambda = dA_n/dE
T_l_vect = T_l_vect + 273.15; %temperature back to [K]
lambda_vect = k_vect./(k_vect + g_c_vect).*(c_a - c_i_vect)./dg_wdg_c_vect./dEdg_w_vect - ...
              g_c_vect./(k_vect + g_c_vect).*xi_vect*L./(4*emiss*sigma*T_l_vect.^3 + C_p*g_b) + ...
              g_c_vect./(k_vect + g_c_vect) .* dA_ndP_x_l_time_dP_x_ldE_vect;

% correction at g_c = 0:
lambda_vect(g_c_vect == 0) = (c_a - c_i_vect(g_c_vect == 0))./dg_wdg_c_vect(g_c_vect == 0)./dEdg_w_vect(g_c_vect == 0);

% nighttime correction:
lambda_vect(J_vect < 1e-16) = dR_ddT_l_vect(J_vect < 1e-16)*L./(4*emiss*sigma*T_l_vect(J_vect < 1e-16).^3 + C_p*g_b);


% check for nan's
if any(isnan(lambda_vect(g_c_vect(1:n_stop) > 0)))
    error('ERROR: NaN in ''lambda_vect''!!!')
end

end

