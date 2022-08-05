#!/bin/tcsh
set ANTSPATH=$argv[1]
set PATH=${ANTSPATH}:$PATH

set pointset = $argv[2]
set patid = reg_out
set tmpPath = $argv[3]


set WARPPTS = ${ANTSPATH}/antsApplyTransformsToPoints




######## apply warp - structural images
set CMD=" ${WARPPTS} -d 3 -i ${pointset} -o ${tmpPath}/${patid}_rigid.csv -t [${tmpPath}/${patid}0GenericAffine.mat, 1]"


echo 	"Applying RIGID transform to ptset ${patid}" >> ${patid}.log
echo ${CMD} >> ${tmpPath}/${patid}.log
${CMD} >> ${tmpPath}/${patid}.log
