#!/bin/bash

##SBATCH --partition=rubin
#SBATCH --job-name=auxtel
#SBATCH --output=/sdf/home/a/abrought/auxtel-com/output/out.txt
#SBATCH --error=/sdf/home/a/abrought/auxtel-com/output/err.txt
#SBATCH --ntasks=5
#SBATCH --cpus-per-task=5
#SBATCH --mem-per-cpu=64G
##SBATCH --time=5:00:00


source /sdf/group/rubin/sw/tag/w_2023_33/loadLSST.bash
setup lsst_distrib -t w_2023_33

export PYTHONPATH="/sdf/home/a/abrought/bin/mixcoatl/python:${PYTHONPATH}" # Needed for using gridFit
 
# Set up repositories for collections
export REPO=/repo/embargo
export CONFIG=/sdf/home/a/abrought/auxtel-com/config
export BIAS=u/abrought/latiss/sbias.2023.08.17
export DEFECTS=u/abrought/latiss/defects.2023.08.17
export DARK=u/abrought/latiss/dark.2023.08.17


pipetask run \
  -j 5 \
  -b ${REPO} \
  -d "instrument='LATISS' AND detector IN (0)" \
  -i LATISS/runs/AUXTEL_DRP_IMAGING_2023-08A-07AB-05AB/w_2023_33/PREOPS-3613,LATISS/runs/AUXTEL_DRP_IMAGING_2023-08A-07AB-05AB/w_2023_19/PREOPS-3598,LATISS/runs/AUXTEL_DRP_IMAGING_2023-08ABC-07AB-05AB/w_2023_35/PREOPS-3726,LATISS/runs/AUXTEL_DRP_IMAGING_2023-09A-08ABC-07AB-05AB/d_2023_09_25/PREOPS-3780 \
  -o u/abrought/auxtel-drp.2023.08.03.extended.stampSize_101.samplingSize5 \
  -p ${CONFIG}/drp-reprocess.yaml \
  --register-dataset-types
