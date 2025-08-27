# SA for discerning effect of input parameters on leaf energy balance

PARAMS="../montecarlo/output/ccr/leaftemp/20250728_111936/config.json"

echo "EXPERIMENT LEAF-ENERGY POPULATION 1" >> exp-leaf.out
nohup python sa.py -i sa_problems/ccr/leaf-energy.json -o ./experiments/ccr/exp_leaf -m ../garisom/02_program_code -p $PARAMS -pd ../DBG-leaf -v 2>&1 >> exp-leaf.out &