function scaled = Func_Temperature_Bernacchi(delta_H, c, T)

% Reference: Bernacchi et al. 2013, Equation 9.
% Scales physiological parameters at reference 25 centi-degree to any given leaf temperature 
% delta_H: energy of activation (ΔHa; kJ mol−1):
% c: scaling constant
% T: leaf temperature in celsius

% R, universal gas constant,  J K−1 mol−1
R = 8.314;
Tk = T + 273.15;
% scaled = exp(c - (delta_H ./ (R .* (T + 273.15))));
scaled = c .* exp(((Tk - 298) .* delta_H) ./ (R .* Tk .* 298));