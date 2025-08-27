import numpy as np
import matplotlib.pyplot as plt

sigma = 0.0000000567  # Stefan-Boltzmann Constant, W m-3 K-4
c_p = 29.3  # specific heat of air, J mol-1 c-1

a_s = 0.5  # short wave absorptivities
a_l = 0.97  # long wave absorptivities, this is emiss/epsilon

# View factors for a single leaf
F_a = 0.5  # atmospheric radiation view factor
F_g = 0.5  # ground thermal radiation view factor
F_p = 0.5  # solar incidence view factor
F_r = 0.5  # reflected solar radiation view factor

p_inc = 0.00075


def calc_leaftemp(
    p: float,
    eplant: list[float],
    eplantl: list[float],   # needs to be empty list,
    leaftemp: list[float],  # also empty list
    lavpd: list[float],     # another empty list
    airtemp: float,
    vpd: float,
    wind: float,
    laperba: float,
    leafwidth: float,
    patm: float,
    rs_sun: float,  # total solar incidence on sunlit leaves
    rs_ref: float,  # reflected light
    rl_atm: float,  # clear sky long wave irradiance
    rl_ground: float,  # ground long wave irradiance
    r_abs: float = None  # option to pass in summed
):

    # vpd to vpd in mole fraction
    vpd /= patm

    if not r_abs:
        r_abs = a_s * (F_p * rs_sun + F_r * rs_ref) + a_l * (F_a * rl_atm + F_g * rl_ground)

    _lambda = -42.9143 * airtemp + 45064.3  # heat of vaporization for water at air temp in J mol-1
    grad = 0.1579 + 0.0017 * airtemp + 0.00000717 * pow(airtemp, 2)  # radiative conductance (long wave) at air temp in mol m-2 s-1
    gha = 1.4 * 0.135 * pow((wind / leafwidth), 0.5)  # heat conductance in mol m-2s-1
    eplantl[p] = eplant[p] * (1.0 / laperba) * (1.0 / 3600.0) * 55.4  # convert to E per leaf area in mol m-2s-1
    numerator = r_abs - (a_l * sigma * pow((airtemp + 273.2), 4)) - (_lambda * eplantl[p] / 2.0)  # divide E by 2 because energy balance is two sided.
    denominator = c_p * (grad + gha)
    leaftemp[p] = airtemp + (numerator / denominator)  # leaf temp for supply function
    lavpd[p] = (101.3 / patm) * (-0.0043 + 0.01 * np.exp(0.0511 * airtemp))  # saturated mole fraction of vapor in air
    lavpd[p] = (101.3 / patm) * (-0.0043 + 0.01 * np.exp(0.0511 * leaftemp[p])) - lavpd[p] + vpd  # leaf-to-air vpd
    lavpd[p] *= patm  # convert back to kPa
    if (lavpd[p] < 0):
        lavpd[p] = 0  # don't allow negative lavpd


if __name__ == "__main__":
    # Example usage with fake but reasonable values
    n = 10000  # number of p's
    eplant = np.linspace(0, 350, n)  # kg hr-1 m-2 basal area
    eplantl = [0.0] * n
    leaftemp = [0.0] * n
    lavpd = [0.0] * n

    airtemp = 43.0  # degrees Celsius, typical ambient
    vpd = 7.429  # kPa
    wind = 1.4  # m/s, gentle breeze
    laperba = 827.7878117
    leafwidth = 0.034391333  # m, 5 cm wide leaf
    patm = 101.3  # kPa, sea level
    rs_sun = 52  # W/m2, sunny day
    rs_ref = 1.6  # W/m2, reflected
    rl_atm = 443  # W/m2, clear sky
    rl_ground = 549  # W/m2, warm ground
    # r_abs = 740  # W/m2
    r_abs = None

    for p in range(n):
        calc_leaftemp(
            p, eplant, eplantl, leaftemp, lavpd,
            airtemp, vpd, wind, laperba, leafwidth, patm,
            rs_sun, rs_ref, rl_atm, rl_ground, r_abs
        )
        print(f"Pressure {p * p_inc:.4f}: leaftemp={leaftemp[p]:.2f}°C, lavpd={lavpd[p]:.2f} kPa, eplant={eplant[p]:.4f} kg hr-1 m-2")

    pressures = np.arange(n) * p_inc

    plt.figure(figsize=(12, 8))

    plt.subplot(3, 1, 1)
    leaftemp_minus_airtemp = [lt - airtemp for lt in leaftemp]
    plt.plot(pressures, leaftemp_minus_airtemp, label='Leaf Temperature - Air Temperature (°C)')
    plt.ylabel('Leaf Temp - Air Temp (°C)')
    plt.legend()

    plt.subplot(3, 1, 2)
    plt.plot(pressures, lavpd, label='Leaf-to-Air VPD (kPa)', color='orange')
    plt.ylabel('Lavpd (kPa)')
    plt.legend()

    plt.subplot(3, 1, 3)
    plt.plot(pressures, eplant, label='Eplant (kg m$^{-2}$ hr$^{-1}$)', color='green')
    plt.xlabel('Pressure')
    plt.ylabel('Eplantl (mol m$^{-2}$ s$^{-1}$)')
    plt.legend()

    plt.tight_layout()
    plt.show()
