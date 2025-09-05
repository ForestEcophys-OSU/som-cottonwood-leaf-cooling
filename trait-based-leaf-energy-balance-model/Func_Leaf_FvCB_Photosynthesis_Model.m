function FvCB=Func_Leaf_FvCB_Photosynthesis_Model(V25, J25, Rd25, T, Topt, I, Ci, Pres, PSII_in, Phi_in)
% Goals: using leaf level FvCB Photosynthesis model (Farquhar et al. 1980) to simulate a single leaf photosynthesis rate

%% Input
% V25: Vcmax standardized at 25 centi-degree
% J25: Jmax standardized at 25 centi-degree
% I: incoming light
% T: leaf temperature in centi-degree
% Topt: optimal temperature for Jmax in centi-degree
% Ci: internal CO2, umol/mol or ppm
% Pres: air pressure, in pa
% PSII_in: input PSII for maximum quantum yield
% Phi_in: input Phi for curvature factor for light response function

%% Output
% Output=[An Rd 0.5*Vo Vc Wc Wj Wp Vmax Jmax Vomax Tau_star Kc Ko PSII Phi];
% 1, An: net assimilation rate
% 2, Rd: dark respiration rate
% 3, 0.5*Vo
% 4, Vc: primary assimilation rate
% 5, Wc: primary assimilation rate by Rubsico
% 6, Wj: primary assimilation rate by RuBP regeneration
% 7, Wp: TPU limited; since we don't have TPU data at this moment, we used 0.5 Vmax instead
% 8, Vmax: temperature scaled Vmax
% 9, Jmax: temperature scaled Jmax
% 10, Vomax: temperature scaled Vomax
% 11, Tau_star: temperature scaled Tau_star
% 12, Kc: temperatuer scaled Kc
% 13, Ko: temperature scaled Ko
% 14: PSII: temperature constant PSII
% 15: Phi: temperature constant Phi

% or
% 
% FvCB.An: net assimilation rate (umol/m2/s)
% FvCB.Rd: dark respiration rate (umol/m2/s)
% FvCB.Wc: photosynthesis path via Rubisco (umol/m2/s)
% FvCB.Wj: photosynthesis path via RUBP regeneration (umol/m2/s)
% FvCB.Vcmax: Vcmax (umol/m2/s), after temperature adjustment 
% FvCB.Jmax: Jmax(umol/m2/s), after temperature adjustment
% FvCB.Tau_star: Tau_star, after temperature adjustment
% FvCB.Kc: Kc, after temperature adjustment
% FvCB.Ko: Ko, after temperature adjustment



% derived temperature adjusted physiological parameters
% [Jmax Vmax Tau_star Kc Ko PSII Phi Rd Vomax]=Leaf_temperature_scaling_func(V25, J25, T, Topt, Pres);
LPT=Func_Leaf_Physiology_Temperature_Response(V25, J25, Rd25, T, Topt, Pres);

Jmax=LPT.Jmax;
Vmax=LPT.Vmax; 
Tau_star=LPT.Tau_star;  
Kc=LPT.Kc;  
Ko=LPT.Ko;  
PSII=LPT.PSII;  
Phi=LPT.Phi;  
Rd=LPT.Rd;   
Vomax=LPT.Vomax; 

PSII=PSII_in;
Phi=Phi_in;

C=Ci.*Pres./(101325);
O=210.*Pres./(101325); % mmol/mol
% model photosynthesis % reference from Bernacchi et al. 2013
Wc=Vmax.*C./(C+Kc.*(1+O./Ko));
Wp=0.5*Vmax; % using default or non-direct observed TPU

f=0.15; % spectral correction factor;
I_used=I.*(1-f).*0.5.*PSII; % the absorbed light used for photosynthesis process

J=I_used+Jmax-sqrt((I_used+Jmax).^2-4*Phi.*I_used.*Jmax);
J=J./(2.*Phi);

%Wj=J.*C./(4.5*C+10.5*Tau_star);
Wj=J.*C./(4*C+8*Tau_star);

Wc=Wc.*(1-Tau_star./C);
Wj=Wj.*(1-Tau_star./C);

Vc=min([Wc Wj Wp],[],2);
% Vc=(1-Tau_star./C).*Vc;

Vo=Vomax.*O./(O+Ko.*(1+C./Kc));
An=Vc-0.5*Vo-Rd;
%An=Vc-Rd;

% Output=[An Rd 0.5*Vo Vc Wc Wj Wp Vmax Jmax Vomax Tau_star Kc Ko PSII Phi];
FvCB.An=An; % net assimilation rate (umol/m2/s)
FvCB.Rd=Rd; % dark respiration rate (umol/m2/s)
FvCB.Vo=Vo; % Vo (umol/m2/s); might not be right 
FvCB.Ap=Vc; % photosynthesis rate (umol/m2/s), An+Rd
FvCB.Wc=Wc; % photosynthesis path via Rubisco (umol/m2/s)
FvCB.Wj=Wj; % photosynthesis path via RUBP regeneration (umol/m2/s)
FvCB.Vcmax=Vmax; % Vcmax (umol/m2/s), after temperature adjustment 
FvCB.Jmax=Jmax; % Jmax(umol/m2/s), after temperature adjustment
FvCB.Vomax=Vomax; % Vomax (umol/m2/s), after temperature adjustment
FvCB.Tau_star=Tau_star; % Tau_star, after temperature adjustment
FvCB.Kc=Kc; % Kc, after temperature adjustment
FvCB.Ko=Ko; % Ko, after temperature adjustment
FvCB.PSII=PSII; % PSII, after temperature adjsutment
FvCB.Phi=Phi; % Phi, after temperature adjustment
FvCB.Rd25=Rd25; % Respiration


