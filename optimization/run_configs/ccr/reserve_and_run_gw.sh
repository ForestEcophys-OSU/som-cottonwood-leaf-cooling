#!/bin/sh

#SBATCH -J garisom_optim_ccr_gw
#SBATCH -c 32
#SBATCH --mem=128G
#SBATCH --time=2-00:00:00
#SBATCH --mail-type=ALL,TIMELIMIT_90 # send email notification when job reaches 90% of time limit
#SBATCH --mail-user=pannikkc@oregonstate.edu

# Load slurm modules
ml rclone gcc/14.2

# Make a tmp scratch space to allow for isolated model builds and prevent race conditions
SHARED_SOURCE_DIR=~/hpc-share/fremont-cottonwood-dbg-garisom/garisom/02_program_code
WORKDIR=/scratch/$USER/job_${SLURM_JOB_ID}

mkdir -p $WORKDIR
cp -r $SHARED_SOURCE_DIR/* $WORKDIR

# Build GARISOM
cd $WORKDIR
make clean
make

# Run optimization
cd ~/hpc-share/fremont-cottonwood-dbg-garisom/
source env/bin/activate
cd ./optimization/

EXP="gw"
EXP_DIR="output/ccr"
EXP_OUT="$EXP_DIR/${EXP}/optim.out"

mkdir -p "${EXP_DIR}/${EXP}/"

echo "$(date '+%Y-%m-%d %H:%M:%S') - EXPERIMENT ${EXP} POPULATION CCR" >> $EXP_OUT
python run_param_optim.py -i run_configs/ccr/${EXP}.json -o $EXP_DIR -m $WORKDIR 2>&1 >> $EXP_OUT

# Delete scratch space after
rm -rf $WORKDIR

# Sync to box folder
cd ..
./bash/sync_to_box.sh