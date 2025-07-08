#!/bin/sh

#SBATCH -J garisom
#SBATCH -c 32
#SBATCH --mem=128G
#SBATCH --time=7-00:00:00
#SBATCH --mail-type=ALL,TIMELIMIT_90 # send email notification when job reaches 90% of time limit
#SBATCH --mail-user=pannikkc@oregonstate.edu

sleep 604800
