#!/bin/tcsh
set ANTSPATH=$argv[1]

set pointset = $argv[2]
set patid = reg_out
set tmpPath = $argv[3]


set WARPPTS = ${ANTSPATH}/antsApplyTransformsToPoints




######## apply warp - structural images
set CMD=" ${WARPPTS} -d 3 -i ${pointset} -o ${tmpPath}/${patid}_syn.csv -t ${tmpPath}/reg_out1InverseWarp.nii.gz"


echo 	"Applying SyN transform to ptset ${patid}" >> ${patid}.log
echo ${CMD} >> ${tmpPath}/${patid}.log
${CMD} >> ${tmpPath}/${patid}.log
