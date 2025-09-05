function [Tleaf, gvs] = trait_based_energy_balance_model(X,Ci,constant)
% X is the input parameters, including 12 parameters
% Ci is the intercellular co2 concentration, unit:ppm
Tleaf=X(:,7);
%Ci=init_paras(:,2);
Leaf_paras.d=X(:,1)*0.72; % m leaf size=leaf width*0.72 (Campbell and Norman., 2012)
Leaf_paras.absorp_PAR=X(:,2);%absorptivity of PAR
Leaf_paras.absorp_NIR=X(:,3);%absorptivity of NIR band range
Leaf_paras.emiss_leaf=X(:,4); %leaf emissivity
Phot_paras.V25=X(:,5);%Vcmax 25
Phot_paras.g1=X(:,6);%
Envi_paras.Tair=X(:,7); % C
Envi_paras.u=X(:,8); % m/s wind speed
Envi_paras.PAR=X(:,9); % W/m^2
Envi_paras.RH=X(:,10); % unitless
Envi_paras.Pa=X(:,11); %Ka atomosphere pressure
Envi_paras.p_lower=0.13;% the Albedo of under surface of leaf
Envi_paras.cf=X(:,12);% cloud fractional cover 0.1
Phot_paras.ca=419.36;% air CO2 concentration, modified by CP for DBG plot
Phot_paras.I=Envi_paras.PAR*4.57;
Phot_paras.Pa=Envi_paras.Pa*1000;% unit:Pa

Phot_paras.J25=1.67*Phot_paras.V25;%
Phot_paras.Rd25=0.011*Phot_paras.V25;%Respiration

%calculating emissivity of sky, based on Tair,RH, £®Flerchinger et al.,
%2009)
constant.lamt=abs(-0.04258*Envi_paras.Tair+44.99)*10^3; % J/mol latent heat of vaporization of water
w=4650*0.611*exp(17.502*Envi_paras.Tair./(Envi_paras.Tair+240.97)).*Envi_paras.RH*0.01./(Envi_paras.Tair+273.16);
Lclr=59.38+113.7*((Envi_paras.Tair+273.16)/273.16).^6+96.96*sqrt(w/25);
emiss_clrsky=Lclr./(5.67*(10^-8)*(Envi_paras.Tair+273.16).^4);

%calculating cloud coverage according location, time, and PAR£®Flerchinger et al.,
%2009)
St=Envi_paras.PAR/0.45;
hour=12;
minut=0;
lat=33.46482;  % changed for DBG by CP
lon=-111.94021; % changed for DBG by CP
doy=240;      % changed for DBG by CP
solar_dec=0.4102*(sin(2*pi/265*(doy-80)));
ST=hour+minut/60+(lon-120)/15;% solar time
time_dif=15*(ST-12);
sin_a=sin(lat*pi/180)*sin(solar_dec)+cos(lat*pi/180)*cos(solar_dec)*cos(pi*time_dif/180);%sun altitude angle'sin
m=35*sin_a*(1224*sin_a^2+1)^-0.5;
tao_R_pg=1.021-0.084*(m*(0.00949*Envi_paras.Pa+0.051)).^0.5;
tao_w=1-0.077*(0.01*w*m).^0.3;
tao_a=0.935^m;
Sclr=1360*sin_a.*tao_R_pg.*tao_w*tao_a;
solar_index=St./Sclr; %St measured solar radiation
if solar_index>1
    solar_index=1;
elseif solar_index<0
    solar_index=0;
end

%emiss_cldsky=(1-solar_index)+solar_index.*emiss_clrsky;
emiss_cldsky=(1-0.84*Envi_paras.cf).*emiss_clrsky+0.84*Envi_paras.cf;
Envi_paras.emiss_sky=emiss_cldsky;

Envi_paras.Tsky=Envi_paras.Tair;
Envi_paras.emiss_ground=Leaf_paras.emiss_leaf;
Envi_paras.Tground= Envi_paras.Tair;
Envi_paras.p=-0.14*Envi_paras.Tair+44.46; %mg/m^3 molar density
Envi_paras.v=(0.09079*Envi_paras.Tair+13.27)/10^6; % kinematic viscosity
%Envi_paras.DH1=(0.1285*Envi_paras.Tair+18.85)/10^6; %Thermal diffusivity
Envi_paras.DH=(21.4*101.3./Envi_paras.Pa).*((Envi_paras.Tair+273.16)/293.16).^1.75/10^6; %Thermal diffusivity
%Envi_paras.p_lower=0.13;
Re=Envi_paras.u.*Leaf_paras.d./Envi_paras.v; % Reynolds number (Riato of inertial viscous forces)

CONT  = 1; Wc = 0.5; maxit = 400; maxEBer = 1; counter = 0;
while CONT
    Gr=constant.g*Leaf_paras.d.^3.*abs(Tleaf-Envi_paras.Tair)./((Envi_paras.Tair+273.15).*Envi_paras.v.^2); %grashof number
    Pr=Envi_paras.v./Envi_paras.DH; %prandtl number
    gH_forced=0.664*Envi_paras.p.*Envi_paras.DH.*Re.^(1/2).*Pr.^(1/3)./Leaf_paras.d; %forced conductance for heat
    gH_free=0.54*Envi_paras.p.*Envi_paras.DH.*(Gr.*Pr).^(1/4)./Leaf_paras.d; % free conductance for heat
    Dv=(24*101.3./Envi_paras.Pa).*((Envi_paras.Tair+273.16)/293.16).^1.75/10^6;
    Sc=Envi_paras.v./Dv;
    if Envi_paras.u<0.3
        gHa2=gH_forced;
    elseif Envi_paras.u<1
        gHa2=gH_forced+gH_free;
    else
        gHa2=1.4*gH_forced+gH_free; % boundary layer conductance for heat
    end
    %gHa2=0.135*sqrt(Envi_paras.u/Leaf_paras.d);
    %gva=0.147*sqrt(Envi_paras.u/Leaf_paras.d); %boundary layer conductance for vapor
    %gva=1.0889*gHa2; %boundary layer conductance for vapor
    gva_forced=0.664*Envi_paras.p.*Dv.*Re.^(1/2).*Sc.^(1/3)./Leaf_paras.d;
    gva_free=0.54*Envi_paras.p.*Dv.*(Gr.*Sc).^(1/4)./Leaf_paras.d;
    if Envi_paras.u<0.3
        gva=gva_forced;
    elseif Envi_paras.u<1
        gva=gva_forced+gva_free;
        %gva=gva_free;
    else
        gva=1.4*gva_forced+gva_free; % boundary layer conductance for heat
    end
    %gvs_u=Leaf_paras.gvs*Leaf_paras.sr;
    %gvs_l=Leaf_paras.gvs*(1-Leaf_paras.sr);
    %gv=gvs_u*gva/(gvs_u+gva)+gvs_l*gva/(gvs_l+gva);
    %% photosynthesis conductance model or named FvCB&Medlyn Model
    Leaf_ph=Func_Leaf_FvCB_Photosynthesis_Model(Phot_paras.V25, Phot_paras.J25, Phot_paras.Rd25, Tleaf, 35, Envi_paras.PAR*4.57, Ci, Envi_paras.Pa*1000, 0.7, 0.7);
    vpd=0.611*exp(17.502*Tleaf./(Tleaf +240.97)).*(1 -Envi_paras.RH/100);
    gvs=1.6*(1+Phot_paras.g1./sqrt(vpd)).*Leaf_ph.An./Phot_paras.ca;
    gvs(Envi_paras.PAR==0 | gvs<=0) = 0.00001;
    Ci = Phot_paras.ca-1.6*Leaf_ph.An./gvs;
    Ci (Envi_paras.PAR==0 | gvs<=0) = 100;
    
    %%
    gv=gva.*gvs./(gva+gvs); % conductance for vapor
    Rabs=(Leaf_paras.absorp_PAR.*(1-Envi_paras.cf).*Envi_paras.PAR+Envi_paras.PAR*0.50.*(1-Envi_paras.cf)/0.50.*Leaf_paras.absorp_NIR).*(1+Envi_paras.p_lower)+...
        Leaf_paras.emiss_leaf.*(Envi_paras.emiss_sky.*5.67.*(10^-8).*(273.15+Envi_paras.Tsky).^4+Envi_paras.emiss_ground*5.67*(10^-8).*(273.15+Envi_paras.Tground).^4);
    Loe=2*Leaf_paras.emiss_leaf*5.67*(10^-8).*(273.15+Tleaf).^4;
    H=2*constant.cp*gHa2.*(Tleaf- Envi_paras.Tair);% Is neccessary to multipy 2?
    ET=constant.lamt.*gv.*(vpd./Envi_paras.Pa);
    EBers  = Rabs -Loe -H -ET;
    
    counter     = counter+1;                   %        Number of iterations
    maxEBers(counter,1)    = max(abs(EBers));
    es_fun      = @(T)6.107*10.^(7.5.*T./(237.3+T));
    s_fun       = @(es, T) es*2.3026*7.5*237.3./(237.3+T).^2;
    ei = es_fun(Tleaf);
    su = s_fun(ei, Tleaf);
    Tleaf         = Tleaf + Wc*(Rabs -Loe -H -ET)./(2*(constant.cp).*gHa2 + constant.lamt.*gv.*su./Envi_paras.Pa + 8*Leaf_paras.emiss_leaf*5.67.*(10^-8).*(Tleaf+273.15).^3);
    Tleaf(Tleaf > 50 | Tleaf < -50) = 25;
    if any(isnan(Tleaf))
        warning('Leaf temperature gives NaNs'); 
    end
   
    %if counter==10, Wc = 0.8;  end
    %if counter==20; Wc = 0.6;  end
    if counter>50, Wc = 0.2;  end
    if counter >100
        deadcycle = isequal(maxEBers(counter,1),maxEBers(counter -2,1),maxEBers(counter -4,1),...
            maxEBers(counter -6,1),maxEBers(counter -8,1));
        CONT        = (maxEBers  >   maxEBer) & counter   <   maxit+1 & ~deadcycle;%        Continue iteration?
    end
end
if counter>=maxit
    fprintf('WARNING: maximum number of iteratations exceeded\n');
    fprintf('Maximum energy balance error  = %4.2f W m-2\n' ,max(maxEBers));

end
% out   =  [Tleaf, gvs];
%figure, plot(maxEBers)
% out.Tleaf = Tleaf;
% out.An    = Leaf_ph.An;
% out.VPD_L   = vpd;
end


