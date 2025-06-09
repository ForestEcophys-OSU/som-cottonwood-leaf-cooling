# Testing run

mkdir -p experiments/test/

echo "$(date '+%Y-%m-%d %H:%M:%S') - TEST RUN POPULATION $1" >> experiments/test/test.out
nohup python sa.py -i sa_problems/exp-5_sa-problem.json -o ./experiments/test -m ./garisom/02_program_code -w 32 -s 2 -p $1 2>&1 >> experiments/test/test.out &