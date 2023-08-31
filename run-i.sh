#!/bin/bash

##SBATCH --partition=rubin
#SBATCH --job-name=auxtel-i
#SBATCH --output=/sdf/home/a/abrought/auxtel-com/output/out-i.txt
#SBATCH --error=/sdf/home/a/abrought/auxtel-com/output/err-i.txt
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=6
#SBATCH --mem-per-cpu=16G
#SBATCH --time=5:00:00


source /sdf/group/rubin/sw/tag/w_2023_33/loadLSST.bash
setup lsst_distrib -t w_2023_33

python run-i.py