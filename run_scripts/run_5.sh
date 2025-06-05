# SA of baperga, height, leafAreaIndex, and RootBeta

mkdir -p experiments/exp_5/

echo "$(date '+%Y-%m-%d %H:%M:%S') - EXPERIMENT 5 POPULATION $1" >> experiments/exp_5/exp-5.out
nohup python sa.py -i sa_problems/exp-5_sa-problem.json -o ./experiments/exp_5 -m ./garisom/02_program_code -w 32 -s 32768 -p $1 2>&1 >> experiments/exp_5/exp-5.out &