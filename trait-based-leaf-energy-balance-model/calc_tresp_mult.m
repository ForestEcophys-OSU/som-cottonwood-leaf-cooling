% calculate the temperature response multiplier for Vcmax and Jmax (Kattge and Knorr, 2007)

function kbegkend=calc_tresp_mult(tleaf,tmean,tref)
temp=tleaf+273.15;
Ha=48700+0.82*tmean;
Hd=200000;
adels=662;
bdels=-1.31;
trefk=tref+273.15;
% tmeank=tmean+273.15;
R=8.314;
kbeg=exp((Ha.*(temp-trefk))./(trefk.*R.*temp));
kend=(1+exp((trefk.*(adels+bdels.*tmean)-Hd)./(trefk.*R)))./(1+exp((temp.*(adels+bdels.*tmean)-Hd)./(temp.*R)));

kbegkend=kbeg.*kend;