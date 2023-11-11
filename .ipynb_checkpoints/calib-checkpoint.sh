#!/bin/bash

##SBATCH --partition=rubin
#SBATCH --job-name=auxtel
#SBATCH --output=/sdf/home/a/abrought/auxtel-com/output/out.txt
#SBATCH --error=/sdf/home/a/abrought/auxtel-com/output/err.txt
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=5
#SBATCH --mem-per-cpu=16G
#SBATCH --time=5:00:00


source /sdf/group/rubin/sw/tag/w_2023_33/loadLSST.bash
setup lsst_distrib -t w_2023_33

export PYTHONPATH="/sdf/home/a/abrought/bin/mixcoatl/python:${PYTHONPATH}" # Needed for using gridFit
 
# Set up repositories for collections
export REPO=/repo/embargo
export CONFIG=/sdf/home/a/abrought/run5/BF/config
export BIAS=u/abrought/latiss/sbias.2023.08.17
export DEFECTS=u/abrought/latiss/defects.2023.08.17
export DARK=u/abrought/latiss/dark.2023.08.17


pipetask run \
   -j 10 \
   -d "instrument='LATISS' AND detector in (0) AND exposure.observation_type = 'bias' AND exposure.day_obs IN (20230817)" \
   -b ${REPO} \
   -i LATISS/raw/all,LATISS/calib \
   -o ${BIAS} \
   -p ${CONFIG}/cpBias.yaml \
   --register-dataset-types
   

pipetask run \
   -j 10 \
   -d "instrument='LATISS' AND detector in (0) AND exposure.observation_type = 'flat' AND exposure.observation_reason='flat' AND exposure.day_obs IN (20230817)" \
   -b ${REPO} \
   -i ${BIAS},LATISS/raw/all,LATISS/calib \
   -o ${DEFECTS} \
   -p ${CONFIG}/findDefects.yaml \
   --register-dataset-types

pipetask run \
    -j 10 \
    -d "instrument='LATISS' AND detector IN (0) AND exposure.observation_type='dark' AND exposure.observation_reason='dark' AND exposure.day_obs=20230817" \
    -b ${REPO} \
    -i ${BIAS},${DEFECTS},LATISS/raw/all,LATISS/calib \
    -o ${DARK} \
    -p ${CONFIG}/cpDark.yaml \
    --register-dataset-types
 
 
pipetask run \
   -j 25 \
   -d "instrument='LATISS' AND detector in (0) AND exposure.observation_type = 'flat' AND exposure.observation_reason = 'flat' AND physical_filter='SDSSg_65mm~empty' AND exposure.day_obs=20230817" \
   -b ${REPO} \
   -i ${BIAS},${DEFECTS},${DARK},LATISS/raw/all,LATISS/calib \
   -o u/abrought/latiss/sflat.SDSSg_65mm.2023.08.17 \
   -p ${CONFIG}/cpFlat.yaml \
   --register-dataset-types

pipetask run \
   -j 25 \
   -d "instrument='LATISS' AND detector in (0) AND exposure.observation_type = 'flat' AND exposure.observation_reason = 'flat' AND physical_filter='SDSSr_65mm~empty' AND exposure.day_obs=20230817" \
   -b ${REPO} \
   -i ${BIAS},${DEFECTS},${DARK},LATISS/raw/all,LATISS/calib \
   -o u/abrought/latiss/sflat.SDSSr_65mm.2023.08.17 \
   -p ${CONFIG}/cpFlat.yaml \
   --register-dataset-types

pipetask run \
   -j 25 \
   -d "instrument='LATISS' AND detector in (0) AND exposure.observation_type = 'flat' AND exposure.observation_reason = 'flat' AND physical_filter='SDSSi_65mm~empty' AND exposure.day_obs=20230817" \
   -b ${REPO} \
   -i ${BIAS},${DEFECTS},${DARK},LATISS/raw/all,LATISS/calib \
   -o u/abrought/latiss/sflat.SDSSi_65mm.2023.08.17 \
   -p ${CONFIG}/cpFlat.yaml \
   --register-dataset-types

# "instrument='LATISS' AND detector IN (0) AND exposure.observation_type='science' AND physical_filter='SDSSg_65mm~empty' AND exposure.day_obs=20230803 AND exposure.seq_num NOT IN (699,700,701,702,703,704,705,706,707,708,709,710,711,712,713,697,694,695,692,684,685,686,687,689,568,569,570,571,572,573,574,575,576,468,469,470)"