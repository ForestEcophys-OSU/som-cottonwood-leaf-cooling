#!/bin/sh

#SBATCH -J garisom_tsz
#SBATCH -c 32
#SBATCH --mem=128G
#SBATCH --time=2-00:00:00
#SBATCH --mail-type=ALL,TIMELIMIT_90 # send email notification when job reaches 90% of time limit
#SBATCH --mail-user=pannikkc@oregonstate.edu

cd ~/hpc-share/fremont-cottonwood-dbg-garisom/
source env/bin/activate

EXP_NUM=1
N=4096
W=32

EXP_DIR="experiments/tsz/exp_${EXP_NUM}"
EXP_OUT="$EXP_DIR/exp-${EXP_NUM}.out"

mkdir -p $EXP_DIR

echo "$(date '+%Y-%m-%d %H:%M:%S') - EXPERIMENT ${EXP_NUM} POPULATION $POP" >> $EXP_OUT
python sa.py -i sa_problems/tsz/exp-${EXP_NUM}_sa-problem.json -o $EXP_DIR -m ./garisom/02_program_code -w $W -s $N -p 4 2>&1 >> $EXP_OUT