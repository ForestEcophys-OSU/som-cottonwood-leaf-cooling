#!/bin/bash

#SBATCH -J garisom_sensitivity-analysis_jla_leaf-energy
#SBATCH -c 32
#SBATCH --mem=128G
#SBATCH --time=2-00:00:00
#SBATCH --mail-type=ALL,TIMELIMIT_90
#SBATCH --mail-user=pannikkc@oregonstate.edu
#SBATCH --output=out/R-%x.%j.out
#SBATCH --error=out/R-%x.%j.err

run="leaf-energy"
pop="jla"
PARAMS="../montecarlo/output/jla/leaftemp/20250728_123033/config.json"

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
cd ./sensitivity-analysis/

EXP="${run}"
EXP_DIR="./experiments/${pop}"
EXP_OUT="${EXP_DIR}/${EXP}/exp.out"

mkdir -p "${EXP_DIR}/${EXP}/"

echo "EXPERIMENT LEAF-ENERGY POPULATION ${pop}" >> $EXP_OUT
nohup python sa.py -i sa_problems/${pop}/${EXP}.json -o ${EXP_DIR}/${EXP}/ -m $WORKDIR -p $PARAMS -pd ../DBG-leaf -v 2>&1 >> $EXP_OUT &

rm -rf $WORKDIR
