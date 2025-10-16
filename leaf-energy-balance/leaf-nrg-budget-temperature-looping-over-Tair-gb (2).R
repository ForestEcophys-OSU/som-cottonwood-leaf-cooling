## script to calculate Tleaf in various ways (steady state)
##  script to calculate iterating leaf temperature based on Matlab routine originally from Joe Berry with modifications by CJS
## /Users/christopherstill/still/ncar/files/joeberry/photosynthesis_model/Energy_budget/ebudget.m
#

tair <- c(15:25); counter1 <- 0;
tleaf_arr <- matrix(nrow=length(tair), ncol=15); tleaf_arr[,] <- 0

for (i in tair) {
  print(i)
  counter1 <- counter1 + 1
  print("-------------------------------------------")
  print(counter1)
  #print(tair[counter1])

# ----------------------------------------------------------
#   Constants
#-----------------------------------------------------------
#  alb = absorptance of leaf to SW radiation
alb = 0.5
#  ems = longwave emissivity
ems = 1
#  sbc = Stefan-Boltzman constant
sbc = 5.6703e-8
#  lhv = latent heat of vaporization (J mol^-1)
lhv = 49.33e3
#  cpa = molar specific heat of air (J mol^-1 oC^-1)
cpa = 25.9
# heat capacity of air - value from Appendix 6 in Jones 2014
# specific heat of air (heat capacity is specific heat times air density for units of J/m3/C)
# note that according to Matteo Detto, Cp varies with temperature
# cp=(1.0029+5.4e-5*tair)+xv.*(1.856+2.0e-4*tair);
# where xv is specific humidity.
CPAIR = 1012.0 #[J kg^-1 K^-1]
press = 101325 #[Pa or J/m3] atmospheric pressure in a standard atmosphere
rho = 1.15 #[kg/m^3] density of air
unit_convert = 41.0 #to convert from m/s conductance unit to mol/m2 sec conductance unit
# molar mass of air
AIRMA = 29.e-3 #[kg mol^-1]
# Ideal gas constant (R)
R = 8.3144 #[J/mol K]

# ----------------------------------------------------------
#   Variables
#-----------------------------------------------------------

tleaf_guess = tair[counter1]; #print(tleaf_guess)
# relative hunidity [%]
rh <- 50
# boundary layer conductance to heat and water vapor (2-sided leaf value) [mol/m2/s]
gb <- .5
# stomatal conductance to water vapor (1-sided or hypostomatous leaf value) [mol/m2/s]
gs <- .25
#  Tair = air temperature in C
ta = tair[counter1]; print(paste("Air temperature = ", ta))
tleaf_arr[counter1,1] <- ta

#  SWd = down-welling solar radiation
SWd = 750
#  LWd = down-welling longwave radiation
LWd = ems*sbc*(283)^4
#  Ra = SW and LW absorbed radiation (W m^-2)
Ra = SWd * (1 - alb) + LWd * ems; print(paste("SW and LW absorbed radiation = ", round(Ra,1)))
#  Re = radiation emitted (W m^-2), assumes surface is at air temperature, so calculation is isothermal Rnet
Re = ems * sbc * tkelvin^(4); #print(paste("LW emitted radiation (W/m^2) =", round(Re,2), ""))

#  Rn = net radiation (Ra - Re)
Rnet = Ra - Re; print(paste("Isothermal net radiation (W/m^2) =", round(Rnet,1), ""))

esat = 6.112*exp(17.67*ta/(ta + 243.5)) #(mbar) SVP versus Temp relationship from Jacobson 1999
esat = esat*100 #[Pa] convert to Pa from mbar : 100Pa/mbar #print(esat)

#slope of saturated vapor pressure versus tempersature curve evaluated at a given tair in C
#function from EcoHydRology package named SatVapPresSlope(temp_C) - units are kPa/C
s = (2508.3/(ta + 237.3)^2) * exp(17.3 * ta/(ta + 237.3))
s = s*1e3 #convert to Pa/C from kPa/C using conversion factor of 1000Pa/kPa
tleaf_arr[counter1,8] <- s

#from Table 3.2 in Bonan -latent heats of vaporization (J/g) at different air temperatures (C)
# latent heat of vaporization [J/kg] at different temperatures - see values from Table 3.2 in Bonan 2008
# lambda = 2454000 #[J/kg] latent heat of vaporization at 20C
intercept = 2503115; slope = -2497
lambda = intercept + ta*slope #[J/kg]
gamma = (CPAIR*press)/(0.622*lambda)

# Groff-Gratch equation for the saturation vapor pressure of
# water as a function of temperaure in (Celsius), tc
tkelvin = ta + 273.16; u = tkelvin / 373.16; v = 373.16 / tkelvin
temp <- -7.90298 * (v - 1.0) + 5.02808 * log10(v) -
    1.3816e-7 * (10.0 ^(11.344 * (1.0 - u)) - 1.0) +
    8.1328e-3 * (10.0 ^(-3.49149 * (v - 1.0)) - 1.0) + log10(1013.246)
esat2	= 100.0 * (10.0 ^ temp); #print(esat2)

# relative humidity of air (#)
rh = 50
# ea = water vapor pressure of air (Pa)
ea = esat*rh/100 #[Pa]  print(ea)
vpd = (esat - ea)/1000; print(paste("Atmospheric VPD (kPa) at Tair of", ta, " = ", round(vpd,2)))
tleaf_arr[counter1,9] <- vpd

# leaf stomatal conductance with inverse VPD dependence (recall that 0.4 mol/m2/sec = 100 s/m)
#gs = 0.25/sqrt(vpd)  #0.25 #[mol m^-2 s^-1]
# leaf stomatal conductance with VPD dependence based on Oren et al. 1999 example values (Table 1
b <- 333; m <- 216 #aspen b <- 500; m <- 225 #Glycine ;#b <- 191; m <- 113; #Acacia #b <- 1080; m <- 787 (Teak)
#b <- 191; m <- 113
gs = -m*log(vpd) + b; gs = gs/1000
tleaf_arr[counter1,10] <- gs
print(paste("Modified gs with VPD dependence =", round(gs,2)))

# total combined (stomatal plus boundary layer) conductance to water vapor flux
gtot = gb * gs/(gb + gs) #[mol m^-2 s^-1]
tleaf_arr[counter1,13] <- gtot
print(paste("Total conductance to water vapor flux (mol m^-2 s^-1) = ", round(gtot,4)))
denominator = CPAIR * AIRMA * gb;

#-----------------------------------------------------------
# start solution with leaf temperature guess
#-----------------------------------------------------------

t1 = tleaf_guess #[C] first guess at leaf temperature based on user input
t2 = ta + 0.1 #[C] initialize t2 to prevent escape

#------------------------------------------------------------
#  begin iterative solution of tl
#------------------------------------------------------------
ctr = 0

  while (abs(t2 - t1) > 0.01) {
    ctr = ctr + 1; #print(paste("loop counter = ", ctr)) #print(ctr)

    t1 = (t1 + t2)/2; #print(paste("average temperature in iteration = ", round(t1,2)))
    tk = t1 + 273.16 #[K] convert to K

    #  Ra = SW and LW absorbed radiation (W m^-2)
    Ra = SWd * (1 - alb) + LWd * ems; #print(Ra)

    #  Re = radiation emitted (W m^-2)
    Re = ems * sbc * tk^(4); #print(paste("LW emitted radiation (W/m^2) =", round(Re,2), ""))

    #  Rn = net radiation (Ra - Re)
    Rn = Ra - Re; #print(paste("Net radiation (W/m^2) =", round(Rn,2), ""))

    # derivative of radiative dissipation
    dR = 4 * ems * sbc * tk^3

    #  H = sensible heat transfer to air(W m^-2)
    H = cpa * (t1 - ta) * gb; #print(paste("Leaf-level SH flux (W/m2) =", round(H,2)))

    #  dH = derivative of H
    dH = cpa * gb

    # evaporation rate (mol m^-2 s^-1)
    E = gtot*(esat - ea)/press #; print((esat - ea)/press)
    #print(paste("Leaf-level ET flux (mol m^-2 s^-1) =", round(E,3), ""))

    #  LE = latent heat (W m^-2)
    LE = E * lhv; #print(paste("Leaf-level ET flux (W/m2) =", round(LE,2)))

    # slope of saturated vapor pressure versus temperature curve evaluated at a given Tair in C
    # function from EcoHydRology package named SatVapPresSlope(temp_C) - units are kPa/C
    s = (2508.3/(t1 + 237.3)^2) * exp(17.3 * t1/(t1 + 237.3))
    s = s*1000 #convert to Pa/C from kPa/C using 1000Pa/kPa
    #print(paste("Slope of SVP vs temperature (Pa/C) at air temperature of", round(ta,1), "C =", round(s,1), ""))
    dfnpsvp = s

    #  dle = derivative of lE
    dLE = lhv * gtot * dfnpsvp/press

    #  Y = error in energy balance calculation
    Y = Rn - H - LE; #print(paste("Error in energy balance sum (W/m2) = ", round(Y,2)))

    #  t1 = guess for leaf temperature
    #  Dt = Delta-temperature
    Dt = Y/(dR + dH + dLE)

    #  t2 = new guess for leaf temperature
    t2 = t1 + Dt; #print(paste("Tleaf Berry = ",  round(t2,1)))

    #Rl = ems * sbc *(ta+273.15)^4
    #tleaf3 = ta + (Ra - Rl- lhv*gtot*vpd/press)/(cpa*gtot + lhv*s*gtot)
    #print(paste("Tleaf3 = ", tleaf3))
}

print(paste("Final Bowen ratio (SH/LE) = ", round(H/LE,2)))
print(paste("Final Rnet (W/m2) = ", round(Rn,2)))
# now calculate the wet bulb temperature (Twet) to see how much a leaf could cool in theory
# estimate vapor pressure difference between esat(Twet) and ea as 1000 (Pa)
# Twet = ta - (lhv/(cpa*press))*1000; print(paste("Wet bulb temperature estimate (C) = ", round(Twet,1)))

# equations below are from Jones 2014 text book pages 100-101 with some rearrangement
# radiative conductance term in m/s (from eqns 5.9 and 5.10 in Jones 2014)
# updated to fix  error in gR calculation reported by Guilioni et al. 2008. ‘4’ should be an ‘8’.
# A value of 4 gives an error of up to 9% for stomatal resistance estimates in high temps,
# low wind speeds (according to the paper, Table 2). http://www.sciencedirect.com/science/article/pii/S0168192308002074

gR = (4*ems*sbc*tkelvin^3)/(rho*CPAIR) #[m/s]
# now convert from m/s units using formula 3.23a from Jones 2014
gR_mol = gR*(press/(R*tkelvin)) #[mol/m2 s]
tleaf_arr[counter1,14] <- gR_mol
#Rni = Rn + ems*sbc*((t2+273.2)^4 - tkelvin^4); print(paste("Isothermal Rnet based on Berry Tleaf = ",  round(Rni,1)))
Rni = Rnet
#print(Rnet-Rni)

# first formula of Tleaf/surf assuming Rn = LE + SH
# need to convert gb from mol/m2 s to m/s so units are consistent in the denominator
# sum of g - and then multiply both by rho*CPAIR so denominator is W/m2 K and numerator
# is in W/m2, and thus the remaining unit is K
gb_ms = gb/(press/(R*tkelvin))
Tsurf = ta + (Rni - LE)/(gb_ms*rho*CPAIR + gR*rho*CPAIR)
print(paste("Tleaf Jones = ",  round(Tsurf,1)))
# formula derived from eqn. 5.10 in Jones 2014
#Tsurf2 = ta + (Rni - Rn)/(gR*rho*CPAIR)
#print(paste("Tleaf Jones based on gR = ",  round(Tsurf2,1)))

# code below from MAESPA Tleaf solution
# which comes from Leuning et al. 1995 (PC&E 18:1183-1200)
# note that using Rni (isothermal Rnet) produces values closer to Berry loop and to Jones
TDIFF = (Rni - LE) / (CPAIR * AIRMA * gb)
#now calculate using full Leuning expression from 1995 paper (equation 10 and appendix D)
Y = gb/(gb + gR_mol); #print(Y)
TDIFF_Rni = Y*Rni / (CPAIR * AIRMA * gbH); TDIFF_LE = Y*LE / (CPAIR * AIRMA * gb)
#print(paste("TDIFF from Rniso (C) = ", round(TDIFF_Rni,1), ""))
#print(paste("TDIFF from LE (C) = ", round(TDIFF_LE,1), ""))
TLEAF_Leuning = ta + Y*(Rni - LE) / (CPAIR * AIRMA * gb)
print(paste("Tleaf Leuning = ",  round(TLEAF_Leuning,1)))

#print(paste("loop counter = ", ctr))
#print(paste("Net radiation (W/m^2) =", round(Rn,1), ""))
#print(paste("Leaf-level sensible heat flux (W/m^2) =", round(H,2), ""))
#print(paste("Leaf-level latent heat flux  (W/m^2) =", round(LE,1), ""))

print(paste("Tleaf Berry = ", round(t2,1)))
#print(paste("Tleaf - Tair deviation = ", round(t2-ta,1)))

epsilon = s/gamma; print(paste("Epsilon (s/gamma) =", round(epsilon,2)))
omega = (epsilon + 1)/(epsilon + 1 + gb/gs)
#print(paste("Omega decoupling factor =", round(omega,2)))

tleaf_arr[counter1,2] <- Tsurf; tleaf_arr[counter1,3] <- gtot; tleaf_arr[counter1,4] <- TLEAF_Leuning; #
tleaf_arr[counter1,5] <- t2; tleaf_arr[counter1,6] <- t2 - ta; tleaf_arr[counter1,7] <- omega
tleaf_arr[counter1,11] <- LE; tleaf_arr[counter1,12] <- epsilon; tleaf_arr[counter1,15] <- H

}

#print(round(tleaf_arr,2))
par(mfcol=c(2,4))
plot(tleaf_arr[,1], tleaf_arr[,2], xlab="Tair (C)", ylab="Tleaf (C)", type="l", ylim=c(15,40),
     col="blue", main=paste("Rnet = ", round(Rn, 0), "; gb = ", gb))
lines(tleaf_arr[,1], tleaf_arr[,1]*1)
#text(17, 34, paste("Rni (W/m2) =", round(Rni,2)))
#text(22, 34, paste("Rnet (W/m2) =", round(Rn,2)))
#text(17, 31, paste("SWdown (W/m2) =", round(SWdown,1)))
#text(17, 28, paste("gs (mol/m2/s) =", round(gs,2)))
#text(22, 28, paste("gb (mol/m2/s) =", round(gb,2)));
#text(17, 25, paste("gR (mol/m2/s) =", round(gR_mol,2)))
#lines(tleaf_arr[,1], tleaf_arr[,3], col="blue")
lines(tleaf_arr[,1], tleaf_arr[,4], col="red")
lines(tleaf_arr[,1], tleaf_arr[,5], col="green")
plot(tleaf_arr[,1], tleaf_arr[,2]-tleaf_arr[,1], xlab="Tair (C)", ylab="Tdiff (C)", type="l")
#text(17, 34, paste("Rni (W/m2) =", round(Rni,2)))
#text(22, 34, paste("Rnet (W/m2) =", round(Rn,2)))
#text(17, 31, paste("SWdown (W/m2) =", round(SWdown,1)))
#text(17, 28, paste("gs (mol/m2/s) =", round(gs,2)))
#text(22, 28, paste("gb (mol/m2/s) =", round(gb,2)));
#text(17, 25, paste("gR (mol/m2/s) =", round(gR_mol,2)))
lines(tleaf_arr[,1], tleaf_arr[,3]-tleaf_arr[,1], col="blue")
lines(tleaf_arr[,1], tleaf_arr[,4]-tleaf_arr[,1], col="red")
lines(tleaf_arr[,1], tleaf_arr[,5]-tleaf_arr[,1], col="green")
#plot(tleaf_arr[,1], tleaf_arr[,6], xlab="Tair (C)", ylab="Tleaf-Tair (C)")
plot(tleaf_arr[,1], tleaf_arr[,10], xlab="Tair (C)", ylab="Stomatal conductance", type="l")
plot(tleaf_arr[,1], tleaf_arr[,7], xlab="Tair (C)", ylab="Omega decoupling", type="l",
     main=paste("RH (%) = ", rh))
#plot(tleaf_arr[,1], tleaf_arr[,8], xlab="Tair (C)", ylab="s value (Pa/K)")
#plot(tleaf_arr[,1], tleaf_arr[,12], xlab="Tair (C)", ylab="epsilon (s/gamma)", type="l")
plot(tleaf_arr[,1], tleaf_arr[,12]/(tleaf_arr[,12]+1), xlab="Tair (C)", ylab="epsilon/(epsilon +1)", type="l")

#plot(tleaf_arr[,9], tleaf_arr[,10], xlab="VPD (kPa)", ylab="gs (mol/m2/s)",
#      main=paste("b = ", b, "; m = ", m))
#plot(tleaf_arr[,1], tleaf_arr[,10], xlab="Tair (C)", ylab="gs (mol/m2/s)", type="l")
plot(tleaf_arr[,1], gb/tleaf_arr[,10], xlab="Tair (C)", ylab="gb/gs ratio", type="l")
#plot(tleaf_arr[,1], tleaf_arr[,14], xlab="Tair (C)", ylab="gR (mol/m2/s)", type="l")
plot(tleaf_arr[,1], tleaf_arr[,11], xlab="Tair (C)", ylab="LE (W/m2)", type="l")
plot(tleaf_arr[,1], tleaf_arr[,15], xlab="Tair (C)", ylab="H (W/m2)", type="l")


slope1 <- lm(tleaf_arr[,1] ~ tleaf_arr[,2]); #print(slope1)
slope2 <- lm(tleaf_arr[,1] ~ tleaf_arr[,3]); #print(slope2)
slope3 <- lm(tleaf_arr[,1] ~ tleaf_arr[,4]); #print(slope3)
#slope4 <- lm(tleaf_arr[,1] ~ tleaf_arr[,5]); #print(slope4)


