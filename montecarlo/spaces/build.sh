#!/bin/bash

# populations=("ccr" "jla" "nrv" "tsz")
populations=("tsz")
runs=("gw GW.a" "leaftemp leaftemp.b" "pressures P-PD.b")

for pop in ${populations[@]}; do
    for run in "${runs[@]}"; do
        read -r name key <<< $run
        cp ./$pop/$pop.json ./$pop/$name.json
        python build.py ./$pop/$name.json ./$pop/param/$name.json $key
    done
done