# Generic SA script to run an i-th experiment

EXP_NUM=$1
POP=$2
N=$3

mkdir -p experiments/exp_${EXP_NUM}/

echo "$(date '+%Y-%m-%d %H:%M:%S') - EXPERIMENT ${EXP_NUM} POPULATION $POP" >> experiments/exp_${EXP_NUM}/exp-${EXP_NUM}.out
nohup python sa.py -i sa_problems/exp-${EXP_NUM}_sa-problem.json -o ./experiments/exp_${EXP_NUM} -m ./garisom/02_program_code -w 30 -s $N -p $POP 2>&1 >> experiments/exp_${EXP_NUM}/exp-${EXP_NUM}.out &