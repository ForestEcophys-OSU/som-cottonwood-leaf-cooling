#!/bin/bash

populations=("ccr" "jla" "nrv" "tsz")
runs=("gw" "leaftemp" "pressures")

for pop in ${populations[@]}; do
    for run in ${runs[@]}; do
        export pop run
        envsubst '${pop} ${run}' <<'EOF' | sbatch
#!/bin/bash

#SBATCH -J garisom_optim_${pop}_${run}
#SBATCH -c 32
#SBATCH --mem=128G
#SBATCH --time=2-00:00:00
#SBATCH --mail-type=ALL,TIMELIMIT_90
#SBATCH --mail-user=pannikkc@oregonstate.edu
#SBATCH --output=out/R-%x.%j.out
#SBATCH --error=out/R-%x.%j.err

mkdir -p out

ml rclone gcc/14.3

SHARED_SOURCE_DIR=~/hpc-share/fremont-cottonwood-dbg-garisom/garisom/02_program_code
WORKDIR=/scratch/$USER/job_${SLURM_JOB_ID}

mkdir -p $WORKDIR
cp -r $SHARED_SOURCE_DIR/* $WORKDIR

cd $WORKDIR
make clean
make

cd ~/hpc-share/fremont-cottonwood-dbg-garisom/
source env/bin/activate
cd ./optimization/

EXP="${run}"
EXP_DIR="output/${pop}"
EXP_OUT="${EXP_DIR}/${EXP}/optim.out"

mkdir -p "${EXP_DIR}/${EXP}/"

echo "$(date '+%Y-%m-%d %H:%M:%S') - EXPERIMENT ${EXP} POPULATION ${pop}" >> $EXP_OUT
python run_param_optim.py -i run_configs/${pop}/${EXP}.json -o $EXP_DIR -m $WORKDIR -pd ../DBG-leaf/ 2>&1 >> $EXP_OUT

rm -rf $WORKDIR

cd ..
./bash/sync_to_box.sh
EOF
    done
done
