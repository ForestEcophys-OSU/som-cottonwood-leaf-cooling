# Generic SA script to run an i-th experiment

EXP_NUM=$1
POP=$2

echo "EXPERIMENT ${EXP_NUM} POPULATION $POP" >> exp_${EXP_NUM}/exp-${EXP_NUM}.out
nohup python sa.py -i sa_problems/exp-${EXP_NUM}_sa-problem.json -o ./exp_${EXP_NUM} -m ./garisom/02_program_code -w 60 -s 35000 -p $POP 2>&1 >> exp_${EXP_NUM}/exp-${EXP_NUM}.out &