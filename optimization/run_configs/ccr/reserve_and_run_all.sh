#!/bin/sh

#SBATCH -J garisom_optim_ccr_all
#SBATCH -c 32
#SBATCH --mem=128G
#SBATCH --time=2-00:00:00
#SBATCH --mail-type=ALL,TIMELIMIT_90 # send email notification when job reaches 90% of time limit
#SBATCH --mail-user=pannikkc@oregonstate.edu

cd ~/hpc-share/fremont-cottonwood-dbg-garisom/
source env/bin/activate
cd ./optimization/

EXP="all"
EXP_DIR="output/ccr"
EXP_OUT="$EXP_DIR/${EXP}/optim.out"

mkdir -p "${EXP_DIR}/${EXP}/"

echo "$(date '+%Y-%m-%d %H:%M:%S') - EXPERIMENT ${EXP} POPULATION CCR" >> $EXP_OUT
python run_param_optim.py -i run_configs/ccr/${EXP}.json -o $EXP_DIR -m ../garisom/02_program_code 2>&1 >> $EXP_OUT