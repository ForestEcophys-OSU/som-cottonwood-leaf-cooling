function Jmax=Func_Temperature_June(J25, Topt, T)
% Reference: Bernacchi et al. 2013 and June et al. 2004

% J25: Jmax standardized at 25 centi-degree
% Topt: optimal temperature for Jmax in centi-degree
% T: leaf temperature in centi-degree

% Omega--parameters controlling the temperature sensitivity of Jmax
Omega=11.6+0.18*Topt; % empirical relationship from June et al. 2004; Fig. 4
scale=((T-Topt)./Omega).^2;
Jmax=J25.*exp(-scale);