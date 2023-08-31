#!/bin/bash

##SBATCH --partition=rubin
#SBATCH --job-name=auxtel-g
#SBATCH --output=/sdf/home/a/abrought/auxtel-com/output/out-g.txt
#SBATCH --error=/sdf/home/a/abrought/auxtel-com/output/err-g.txt
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=6
#SBATCH --mem-per-cpu=16G
#SBATCH --time=5:00:00


source /sdf/group/rubin/sw/tag/w_2023_33/loadLSST.bash
setup lsst_distrib -t w_2023_33

python run-g.py