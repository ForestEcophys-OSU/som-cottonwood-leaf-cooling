# Generic SA script to run an i-th experiment

EXP_NUM=$1
N=$2
W=$3

EXP_DIR="experiments/nrv/exp_${EXP_NUM}"
EXP_OUT="$EXP_DIR/exp-${EXP_NUM}.out"

mkdir -p $EXP_DIR

echo "$(date '+%Y-%m-%d %H:%M:%S') - EXPERIMENT ${EXP_NUM} POPULATION $POP" >> $EXP_OUT
nohup python sa.py -i sa_problems/nrv/exp-${EXP_NUM}_sa-problem.json -o $EXP_DIR -m ./garisom/02_program_code -w $W -s $N -p 3 2>&1 >> $EXP_OUT &