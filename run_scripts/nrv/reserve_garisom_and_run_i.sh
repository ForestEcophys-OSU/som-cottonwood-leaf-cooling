#!/bin/sh

#SBATCH -J garisom_nrv
#SBATCH -c 32
#SBATCH --mem=128G
#SBATCH --time=2-00:00:00
#SBATCH --mail-type=ALL,TIMELIMIT_90 # send email notification when job reaches 90% of time limit
#SBATCH --mail-user=pannikkc@oregonstate.edu

cd ~/hpc-share/fremont-cottonwood-dbg-garisom/
source env/bin/activate

./run_scripts/nrv/run_i.sh 1 4096 32