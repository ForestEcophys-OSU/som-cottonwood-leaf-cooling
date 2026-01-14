# Testing run

mkdir -p experiments/test/

echo "$(date '+%Y-%m-%d %H:%M:%S') - TEST RUN POPULATION CCR" >> experiments/test/test.out
python sa.py -i sa_problems/ccr/leaf-energy.json -o experiments/test/ -m ../../garisom/02_program_code -p ../../montecarlo/output/ccr/leaftemp/20250728_111936/config.json -pd ../../DBG