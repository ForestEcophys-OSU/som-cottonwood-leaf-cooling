#!/bin/bash

populations=("ccr" "jla" "nrv" "tsz")
runs=("gw" "leaftemp" "pressures")

for pop in ${populations[@]}; do
    for run in ${runs[@]}; do
        sbatch $pop/reserve_and_run_$run.sh
    done
done
