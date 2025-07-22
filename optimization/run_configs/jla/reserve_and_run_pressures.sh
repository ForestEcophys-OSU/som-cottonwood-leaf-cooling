#!/bin/sh

#SBATCH -J garisom_optim_jla_pressures
#SBATCH -c 32
#SBATCH --mem=128G
#SBATCH --time=2-00:00:00
#SBATCH --mail-type=ALL,TIMELIMIT_90 # send email notification when job reaches 90% of time limit
#SBATCH --mail-user=pannikkc@oregonstate.edu

ml rclone gcc/14.2

cd ~/hpc-share/fremont-cottonwood-dbg-garisom/

cd ./garisom/02_program_code
make clean
make

cd ../..

source env/bin/activate
cd ./optimization/

EXP="pressures"
EXP_DIR="output/jla"
EXP_OUT="$EXP_DIR/${EXP}/optim.out"

mkdir -p "${EXP_DIR}/${EXP}/"

echo "$(date '+%Y-%m-%d %H:%M:%S') - EXPERIMENT ${EXP} POPULATION JLA" >> $EXP_OUT
python run_param_optim.py -i run_configs/jla/${EXP}.json -o $EXP_DIR -m ../garisom/02_program_code 2>&1 >> $EXP_OUT

cd ..
./bash/sync_to_box.sh