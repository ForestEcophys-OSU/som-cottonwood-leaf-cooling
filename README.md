# Stomatal Optimization Model — Cottonwood Leaf Cooling

This repository stores all project code and data for the cottonwood leaf cooling modeling project. The aim of this project was to identify the limitations of using stomatal optimization models to represent the physiology process of trees during hot-droughts.

For more information visit the [project page](https://forestecophys-osu.github.io/som-cottonwood-leaf-cooling/).

## Project Directory Structure

```
├── bash/                      # Shell scripts for job scheduling and data sync
│   ├── reserve_garisom.sh     # HPC job reservation script
│   ├── sq.sh                  # Queue status script
│   ├── sync_from_box.sh       # Sync data from Box cloud storage
│   └── sync_to_box.sh         # Sync data to Box cloud storage
│
├── data/                      # Raw and processed experimental data
│   ├── ground/                # Ground truth datasets
│   ├── *.csv                  # Weather, trait, and measurement data
│   └── *.ipynb                # Data transformation notebooks
│
├── garisom/                   # GARISOM model submodule
│
├── garisom-tools/             # garisom-tools submodule
│
├── leaf-energy-balance/       # Leaf energy balance calculations
│   ├── formula.py             # Python implementation
│   └── *.R                    # R implementation
│
├── montecarlo/                # Monte Carlo simulation framework
│   ├── run_sim.py             # Simulation runner
│   └── spaces/                # Parameter space definitions
│
├── notes/                     # Project documentation and notes
│
├── optimization/              # Parameter optimization tools
│   ├── run_param_optim.py     # Optimization runner
│   └── run_configs/           # Optimization configurations
│
├── outputs/                   # Model output storage
│   └── leaftemp/              # Leaf temperature outputs
│
├── result-comparison/         # Model results in PDF's
│
├── results/                   # A bunch of figures
│
├── sensitivity-analysis/      # Sensitivity analysis framework
│   ├── sa.py                  # Main sensitivity analysis script
│   ├── sa_problems/           # Problem definitions
│   ├── run_scripts/           # Execution scripts
│   └── *.ipynb                # Plotting notebooks
│
├── tealeaves/                 # tealeaves R notebook
│
├── trait-based-leaf-energy-balance-model/  # Trait-based model
    ├── run_dbg_data.m         # Matlab file for running with data
│
├── website/                   # Project website (Jekyll)
│   ├── pages/                 # Static pages
│   └── assets/                # Images and static files
│
├── compare-model-to-ground*.ipynb  # Data visualization notebooks
├── dataset.csv                # Main dataset
└── param_data_template.csv    # Parameter template
```

