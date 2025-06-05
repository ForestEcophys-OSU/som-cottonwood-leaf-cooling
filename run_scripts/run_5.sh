# SA of baperga, height, leafAreaIndex, and RootBeta

mkdir experiments/exp_5/

echo "EXPERIMENT 5 POPULATION $1" >> exp_5/exp-5.out
nohup python sa.py -i sa_problems/exp-5_sa-problem.json -o ./exp_5 -m ./garisom/02_program_code -w 32 -s 35000 -p $1 2>&1 >> experiments/exp_5/exp-5.out &