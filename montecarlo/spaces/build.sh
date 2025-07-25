#!/bin/bash

populations=("ccr" "jla" "nrv" "tsz")
runs=("gw GW.a gw" "leaftemp leaftemp.c leaftemp" "pressures P-PD.a pd" "pressures P-MD.a md")

for pop in ${populations[@]}; do
    for run in "${runs[@]}"; do
        read -r name key result <<< $run
        cp ./$pop/$pop.json ./$pop/$result.json
        python build.py ./$pop/$result.json ./$pop/param/$name.json $key
    done
done