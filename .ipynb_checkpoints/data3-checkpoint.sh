#!/bin/bash

##SBATCH --partition=rubin
#SBATCH --job-name=auxtel3
#SBATCH --output=/sdf/home/a/abrought/auxtel-com/output/out3.txt
#SBATCH --error=/sdf/home/a/abrought/auxtel-com/output/err3.txt
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=5
#SBATCH --mem-per-cpu=16G
##SBATCH --time=5:00:00


source /sdf/group/rubin/sw/tag/w_2023_33/loadLSST.bash
setup lsst_distrib -t w_2023_33

export PYTHONPATH="/sdf/home/a/abrought/bin/mixcoatl/python:${PYTHONPATH}" # Needed for using gridFit
 
# Set up repositories for collections
export REPO=/repo/embargo
export CONFIG=/sdf/home/a/abrought/auxtel-com/config

# exposure.seq_num to exclude
# 8-29-2023 (192, 211, 212, 213, 214, 217, 218, 287, 348, 349, 350, 351, 352, 353, 355, 356, 357, 358, 359, 360, 361, 363, 509, 510, 513, 514, 515, 546, 547)
# 8-17-2023 (166, 167, 170, 171, 172, 176, 180, 181, 184, 185, 191, 194, 198, 199, 204, 205, 213, 215, 216, 224, 241, 304, 321, 403, 413, 414, 417, 418, 419, 446, 480, 481, 487, 494, 505, 507, 508, 509, 510, 511, 512, 513, 514, 516, 517, 518, 519, 520, 521, 522, 523, 524, 525, 526, 527, 528, 529, 530, 531, 532, 533, 534, 535, 536, 537, 538, 539, 540, 541, 542, 543, 544, 545, 546, 547, 585)
# 8-03-2023 (699,700,701,702,703,704,705,706,707,708,709,710,711,712,713,697,694,695,692,684,685,686,687,689,568,569,570,571,572,573,574,575,576,468,469,470)

pipetask run \
   -j 5 \
   -d "instrument='LATISS' AND detector IN (0) AND exposure.observation_type='science' AND physical_filter='SDSSg_65mm~empty' AND exposure.day_obs=20230803 AND exposure.seq_num NOT IN (290, 291, 292, 302, 303, 304, 305, 306, 307, 308, 309, 310, 321, 322, 323, 339, 340, 341, 342, 343, 344, 345, 346, 347, 348, 349, 350, 351, 352, 353, 385, 408, 409, 410, 415, 420, 421, 422, 424, 426, 440, 441, 442, 443, 444, 445, 446, 447, 448, 449, 450, 451, 452, 453, 454, 455, 456, 457, 458, 459, 460, 461, 462, 463, 464, 466, 467, 468, 469, 470, 471, 472, 473, 474, 475, 476, 477, 478, 479, 480, 481, 482, 483, 484, 485, 486, 487, 488, 489, 490, 491, 492, 493, 494, 495, 496, 497, 498, 499, 500, 501, 502, 503, 515, 519, 521, 526, 527, 528, 530, 550, 562, 568, 569, 570, 571, 572, 573, 574, 575, 576, 684, 685, 686, 687, 688, 689, 690, 691, 692, 693, 694, 695, 697, 698, 699, 700, 701, 702, 703, 704, 705, 706, 707, 708, 709, 710, 711, 712, 713)" \
   -b ${REPO} \
   -i u/abrought/latiss/sflat.SDSSg_65mm.2023.08.03,u/abrought/latiss/sbias.2023.08.03,u/abrought/latiss/defects.2023.08.03,u/abrought/latiss/dark.2023.08.03,LATISS/raw/all,LATISS/calib \
   -o u/abrought/latiss/stars.SDSSg_65mm.2023.08.03 \
   -p ${CONFIG}/stars.yaml \
   --register-dataset-types

pipetask run \
   -j 5 \
   -d "instrument='LATISS' AND detector IN (0) AND exposure.observation_type='science' AND physical_filter='SDSSr_65mm~empty' AND exposure.day_obs=20230803 AND exposure.seq_num NOT IN (290, 291, 292, 302, 303, 304, 305, 306, 307, 308, 309, 310, 321, 322, 323, 339, 340, 341, 342, 343, 344, 345, 346, 347, 348, 349, 350, 351, 352, 353, 385, 408, 409, 410, 415, 420, 421, 422, 424, 426, 440, 441, 442, 443, 444, 445, 446, 447, 448, 449, 450, 451, 452, 453, 454, 455, 456, 457, 458, 459, 460, 461, 462, 463, 464, 466, 467, 468, 469, 470, 471, 472, 473, 474, 475, 476, 477, 478, 479, 480, 481, 482, 483, 484, 485, 486, 487, 488, 489, 490, 491, 492, 493, 494, 495, 496, 497, 498, 499, 500, 501, 502, 503, 515, 519, 521, 526, 527, 528, 530, 550, 562, 568, 569, 570, 571, 572, 573, 574, 575, 576, 684, 685, 686, 687, 688, 689, 690, 691, 692, 693, 694, 695, 697, 698, 699, 700, 701, 702, 703, 704, 705, 706, 707, 708, 709, 710, 711, 712, 713)" \
   -b ${REPO} \
   -i u/abrought/latiss/sflat.SDSSr_65mm.2023.08.03,u/abrought/latiss/sbias.2023.08.03,u/abrought/latiss/defects.2023.08.03,u/abrought/latiss/dark.2023.08.03,LATISS/raw/all,LATISS/calib \
   -o u/abrought/latiss/stars.SDSSr_65mm.2023.08.03 \
   -p ${CONFIG}/stars.yaml \
   --register-dataset-types
   
pipetask run \
   -j 5 \
   -d "instrument='LATISS' AND detector IN (0) AND exposure.observation_type='science' AND physical_filter='SDSSi_65mm~empty' AND exposure.day_obs=20230803 AND exposure.seq_num NOT IN (290, 291, 292, 302, 303, 304, 305, 306, 307, 308, 309, 310, 321, 322, 323, 339, 340, 341, 342, 343, 344, 345, 346, 347, 348, 349, 350, 351, 352, 353, 385, 408, 409, 410, 415, 420, 421, 422, 424, 426, 440, 441, 442, 443, 444, 445, 446, 447, 448, 449, 450, 451, 452, 453, 454, 455, 456, 457, 458, 459, 460, 461, 462, 463, 464, 466, 467, 468, 469, 470, 471, 472, 473, 474, 475, 476, 477, 478, 479, 480, 481, 482, 483, 484, 485, 486, 487, 488, 489, 490, 491, 492, 493, 494, 495, 496, 497, 498, 499, 500, 501, 502, 503, 515, 519, 521, 526, 527, 528, 530, 550, 562, 568, 569, 570, 571, 572, 573, 574, 575, 576, 684, 685, 686, 687, 688, 689, 690, 691, 692, 693, 694, 695, 697, 698, 699, 700, 701, 702, 703, 704, 705, 706, 707, 708, 709, 710, 711, 712, 713)" \
   -b ${REPO} \
   -i u/abrought/latiss/sflat.SDSSi_65mm.2023.08.03,u/abrought/latiss/sbias.2023.08.03,u/abrought/latiss/defects.2023.08.03,u/abrought/latiss/dark.2023.08.03,LATISS/raw/all,LATISS/calib \
   -o u/abrought/latiss/stars.SDSSi_65mm.2023.08.03 \
   -p ${CONFIG}/stars.yaml \
   --register-dataset-types
