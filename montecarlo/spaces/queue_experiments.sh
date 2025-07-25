#!/bin/bash

populations=("ccr" "jla" "nrv" "tsz")
runs=("gw" "leaftemp" "pd" "md")

for pop in ${populations[@]}; do
    for run in ${runs[@]}; do
        export pop run
        envsubst '${pop} ${run}' <<'EOF' | sbatch
#!/bin/bash

#SBATCH -J garisom_montecarlo_${pop}_${run}
#SBATCH -c 32
#SBATCH --mem=128G
#SBATCH --time=2-00:00:00
#SBATCH --mail-type=ALL,TIMELIMIT_90
#SBATCH --mail-user=pannikkc@oregonstate.edu
#SBATCH --output=out/R-%x.%j.out
#SBATCH --error=out/R-%x.%j.err

mkdir -p out

ml rclone gcc/14.2

SHARED_SOURCE_DIR=~/hpc-share/fremont-cottonwood-dbg-garisom/garisom/02_program_code
WORKDIR=/scratch/$USER/job_${SLURM_JOB_ID}

mkdir -p $WORKDIR
cp -r $SHARED_SOURCE_DIR/* $WORKDIR

cd $WORKDIR
make clean
make

cd ~/hpc-share/fremont-cottonwood-dbg-garisom/
source env/bin/activate
cd ./montecarlo/

EXP="${run}"
EXP_DIR="output/${pop}"
EXP_OUT="${EXP_DIR}/${EXP}/sim.out"

mkdir -p "${EXP_DIR}/${EXP}/"

echo "$(date '+%Y-%m-%d %H:%M:%S') - MONTECARLO ${EXP} POPULATION ${pop}" >> $EXP_OUT
python run_sim.py -i spaces/${pop}/${EXP}.json -o $EXP_DIR -m $WORKDIR 2>&1 >> $EXP_OUT

rm -rf $WORKDIR

cd ..
./bash/sync_to_box.sh
EOF
    done
done
