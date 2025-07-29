The following PDFs are the raw Jupyter notebook outputs that I used to build the
graphs.

Each PDF contains the results for model parameters fit on one output (GW, leaftemp, 
P-PD, P-MD).

There are some headers within the notebook to explain what is what, but the relative
order is:

    1. Errors
        a. Raw individual graphs for each output variable across populations
        b. Facted bar plot with everything on one graph
    2. Time series comparison of prediction and ground truth for pressures for
       each population.
    3. Per treatment averages of stomatal conductance, transpiration, leaftemp,
       and leaftemp-airtemp for each population.
    4. Leaf temperature, and difference of leaf and air temperature plots for each
       population.
        a. Also contains an error plot split by treatment periods for leaf temperature
           that is useful for seeing differences in predictive capability across
           treatments.
    5. Diurnal plots for each population.
        a. Across day plots for stomatal conductance, predawn pressure, and
           midday pressure for days right before drought (JD 237/238), and
           during drought (JD 240/241).