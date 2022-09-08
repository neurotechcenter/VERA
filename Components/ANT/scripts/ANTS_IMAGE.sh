#!/bin/tcsh
set ANTSPATH=$argv[1]
set targetnii = $argv[2]
set patidnii = $argv[3]
set patid = reg_out
set tmpPath = $argv[4]
@ coregtype= $argv[5]



set ANTS = ${ANTSPATH}/antsRegistration
set WARP = ${ANTSPATH}/antsApplyTransforms





 ######## compute warping maps
set cmd0="${ANTS} -d 3 --float 1 --verbose 1 -u 1 -w [ 0.01,0.99 ] -z 1 -r [ ${targetnii},${patidnii},1 ] "
set cmd1="-t Rigid[ 0.1 ] -m MI[ ${targetnii},${patidnii},0.5,32,Regular,0.25 ] -c [ 1000x500x250x0,1e-6,10 ] -f 6x4x2x1 -s 3x2x1x0 "
if( ${coregtype} >= 2 ) then 
    set cmd2="-t Affine[ 0.1 ] -m MI[ ${targetnii},${patidnii},0.5,32,Regular,0.25 ] -c [ 1000x500x250x0,1e-6,10 ] -f 6x4x2x1 -s 3x2x1x0 "
else
    set cmd2=""
endif
if( ${coregtype} >= 3 ) then
    set cmd3="-t SyN[ 0.1,3,0 ] -m MI[ ${targetnii},${patidnii},0.5,32,Regular,0.25 ] -c [ 1000x500x250x0,1e-6,10 ] -f 6x4x2x1 -s 3x2x1x0 -o ${tmpPath}/${patid}"
else
    set cmd3="-o ${tmpPath}/${patid}"
endif
set CMD="${cmd0} ${cmd1} ${cmd2} ${cmd3}"
echo ${CMD} >> ${tmpPath}/${patid}.log
${CMD} >> ${tmpPath}/${patid}.log

######## apply warp - structural images
set cmd4=" ${WARP} -d 3 --float 1 --verbose 1 -i ${patidnii} -o ${tmpPath}/${patid}_111_ants.nii"
if ( ${coregtype} >= 3 ) then
    set cmd5=" -t ${tmpPath}/${patid}1Warp.nii.gz"
else
    set cmd5=""
endif

if ( ${coregtype} >= 1 ) then
    set cmd6=" -t ${tmpPath}/${patid}0GenericAffine.mat"
else
    set cmd6=""
endif

set cmd7=" -r ${targetnii}"

set CMD2="${cmd4} ${cmd5} ${cmd6} ${cmd7}"

echo 	"Applying warp fields to images ${patid}" >> ${patid}.log
echo ${CMD2} >> ${tmpPath}/${patid}.log
${CMD2} >> ${tmpPath}/${patid}.log
