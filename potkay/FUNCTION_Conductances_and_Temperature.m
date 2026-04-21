function [ T_l_vect, g_w_vect, g_c_vect, g_tot_vect, VPD_vect, dEdg_w_vect, dg_wdg_c_vect, L, RH_l_vect ] = ...
FUNCTION_Conductances_and_Temperature( E_vect, P_x_l_vect, dP_x_ldE_vect, P_atm, ...
                                       R_abs, T_a, RH_a, g_b, r_func, ...
                                       m, C_p, emiss, sigma, V_w, R )

% convert to Kelvin [K]
T_a = T_a + 273.15; 

%latent heat of vaporization in [J/kg]
L = 1.91846e6 * (T_a / (T_a - 33.91))^2; %in [J/kg] -- from Henderson-Sellers (1984; Quart. J. R. Met. SOC)
% convert to [J/mol]
L = m * L; %in [J/mol]

% apoplast water potential [MPa]
r_vect = r_func(P_x_l_vect);
psi_A_l_vect = P_x_l_vect - r_vect.*E_vect;

dP_x_l = 0.01;
drdP_x_l_vect = (r_func(P_x_l_vect + dP_x_l) - r_func(P_x_l_vect)) / dP_x_l;
dpsi_A_ldE_vect = (1 - drdP_x_l_vect.*E_vect).*dP_x_ldE_vect - r_vect;

% Solve for leaf temperature in [K]
n = length(E_vect);
T_l_vect = nan(1,n); 
for i = 1:n
    
    T_l_i = T_a;
    E_i = E_vect(i);
    
    j = 0;
    %Netwon's method -- F == 0
    while 1
        
        j = j + 1;
        if j > 100
           error('!!!') 
        end
        F = emiss*sigma*T_l_i^4 + L*E_i + C_p*g_b*(T_l_i - T_a) - R_abs - sigma*T_a^4;
        dFdT = 4*emiss*sigma*T_l_i^3 + C_p*g_b;
        
        T_l_i = T_l_i - 0.3 * F/dFdT; 

        
        if abs(F) < abs((L*E_i - C_p*g_b*T_a - R_abs - sigma*T_a^4) / 1e4)
            break
        end
        
        if abs(L*E_i - C_p*g_b*T_a - R_abs - sigma*T_a^4) < 1e-6
            if abs(F) < abs(C_p*g_b*T_a / 1e6)
                break
            end
        end
        
    end
    
    T_l_vect(i) = T_l_i; 
    
end

% relative humidity of leaf
RH_l_vect = exp(V_w*psi_A_l_vect/1e-6/R./T_l_vect);

% convert temperatures back to [C]
T_a = T_a - 273.15;
T_l_vect = T_l_vect - 273.15;

% vapor pressures of air and leaf
e_l_sat_vect = 0.61078 .* exp(17.27 * T_l_vect ./ (T_l_vect + 237.3)); %in [kPa] -- Teten's equation -- temperature needs to be in [C]
e_l_vect = RH_l_vect .* e_l_sat_vect; %in [kPa]
e_a = RH_a * 0.61078 * exp(17.27 * T_a ./ (T_a + 237.3)); %in [kPa] -- Teten's equation -- temperature needs to be in [C]
VPD_vect = e_l_vect - e_a; %vapor pressure deficit in [kPa] 

% stomatal conductances
g_tot_vect = E_vect./(VPD_vect/P_atm); %total conductance to vapor in [mol/m^2/s]
g_w_vect = 1./(1./g_tot_vect - 1/g_b); %stomatal conductance to vapor in [mol/m^2/s] -- note that g_tot <= g_b
g_w_vect(E_vect == 0) = 0;
g_c_vect = 1./(1.6./g_w_vect + 1.37/g_b); %total conductance to CO2 in [mol/m^2/s]
g_c_vect(E_vect == 0) = 0;

%slope of the response of the saturation vapor pressure to temperature, s = de_l_sat/dT
s_vect = 17.27 * 237.3 * e_l_sat_vect ./ (T_l_vect + 237.3).^2; %temperature needs to be in [C] -- derivatie of Teten's equation

% partial derivatives
T_l_vect = T_l_vect + 273.15; %convert temperature back to [K]
dEdg_w_vect = E_vect./g_w_vect.^2 ./ ...
              (1./g_w_vect + 1/g_b + ...
              RH_l_vect/P_atm.*(s_vect - log(RH_l_vect).*e_l_sat_vect./T_l_vect)*L./(4*emiss*sigma*T_l_vect.^3 + C_p*g_b) - ... 
              RH_l_vect/P_atm.*log(RH_l_vect).*e_l_sat_vect./psi_A_l_vect.*dpsi_A_ldE_vect); %temperature needs to be in [K]
dEdg_w_vect(E_vect == 0) = VPD_vect(E_vect == 0)/P_atm; 

dg_wdg_c_vect = (1.6 + 1.37*g_w_vect./g_b).^2/1.6; 
dg_wdg_c_vect(g_w_vect < 0) = (-1.6 + 1.37*g_w_vect(g_w_vect < 0)./g_b).^2/-1.6;

%report final leaf temperature in [C]
T_l_vect = T_l_vect - 273.15;

end

