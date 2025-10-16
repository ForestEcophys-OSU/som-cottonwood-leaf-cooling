#!/bin/sh

#SBATCH -J garisom_optim_full-irrigation_ccr_leaftemp
#SBATCH -c 32
#SBATCH --mem=128G
#SBATCH --time=2-00:00:00
#SBATCH --mail-type=ALL,TIMELIMIT_90 # send email notification when job reaches 90% of time limit
#SBATCH --mail-user=pannikkc@oregonstate.edu

ml rclone gcc/14.3

cd ~/hpc-share/fremont-cottonwood-dbg-garisom/
git checkout full-irrigation

cd ./garisom/02_program_code
git checkout full-irrigation
make clean
make

cd ../..

source env/bin/activate
cd ./optimization/

EXP="leaftemp"
EXP_DIR="output/ccr-full-irrigation"
EXP_OUT="$EXP_DIR/${EXP}/optim.out"

mkdir -p "${EXP_DIR}/${EXP}/"

echo "$(date '+%Y-%m-%d %H:%M:%S') - EXPERIMENT ${EXP} POPULATION CCR" >> $EXP_OUT
python run_param_optim.py -i run_configs/ccr/${EXP}.json -o $EXP_DIR -m ../garisom/02_program_code -pd ../DBG-full-irrigation/ 2>&1 >> $EXP_OUT

cd ..
git checkout main

./bash/sync_to_box.sh