#!/bin/bash
exe_name=$0
exe_dir=`dirname "$0"`

if [ $# -lt 2 ]
then
    echo "run_reface_docker.sh is a script to run the mri_reface Docker image using the same syntax as run_mri_reface.sh"
    echo "mri_reface: replaces face and ear imagery in MRI with an average face, to help prevent potential re-identification"
    echo "Script version 0.3.3"
    echo "By: Christopher G. Schwarz and Carl M. Prakaashana, schwarz.christopher@mayo.edu"
    echo "For details, see: https://doi.org/10.1016/j.neuroimage.2021.117845"
    echo ""
    echo "Usage: "
    echo "$0 <Input .nii> <Output directory> [options]"
    echo ""
  echo "<Input .nii> : Multiple .nii files can be specified using a list of .nii files separated by a , or ;. Example: "nii1.nii,.nii2.nii". The first .nii file is treated as the base image for nonlinear registration to the template. Subsequent .nii files will be coregistered to the base image and transformed using the base image's nonlinear registration. Each re-faced image will be output in its original image space. For example, you could re-face a T1 and a FLAIR, using the T1 as the base image for registration, but both will be output in their original spaces. You could also input individual 3D frames of a dynamic PET image, even if they have not been previously coregistered."
  echo "4-D .nii files can also be used. For MRIs, the 3D volumes in the 4D .nii will be treated as already-coregistered (i.e. multiple echoes), and registration to the template will use the mean across volumes. For PET, the individual frames will be automatically split up and each will be de-faced using its registration to the first frame or the first input image (if the first input image was not the 4D PET)."
    echo ""
    echo "You can also provide a directory path for the first (input) argument. This directory will be assumed to contain DICOM from a single series. It will be converted to nii with dcm2niix, de-faced, and converted back to DICOM while copying all unrelated DICOM tags from the original DICOM. Using the -imType flag is highly recommended with this approach."
    echo ""
    echo "Additional options: "
    echo " -imType <T1|T2|FLAIR|FDG|PIB|FBP|TAU|CT|AUTO>"
    echo "   If set to AUTO, it will look for these strings in your input filename to determine automatically. default=AUTO."
    echo "   If you are using multiple image types, you can specify as a list separated by a , or ;"
    echo " -verbose <0|1>"
    echo "   default=1."
    echo " -saveQCRenders <0|1>"
    echo "   If set to 1, saves .png files before/after de-facing in the output directory, for QC purposes. default=1."
    echo " -regFile <file .txt or .mat>"
    echo "   Overrides the affine registration between input and MCALT_FaceTemplate. If not specified, one will be generated using reg_aladin. Designed to read matrix save formats from: Matlab/SPM (.txt ascii or .mat binary), reg_aladin (.txt ascii), ITK/ANTs (.txt ascii), or FLIRT (.mat ascii)."
    echo " -threads <count>"
    echo "   How many threads to use? Default: 1. Only very small portions of the software can use multiple threads, so users should expect only very modest speed gains from multithreading."
    echo " -matchNoise <0|1>"
    echo "   Should we add noise to the replacement face to try to match the input image?  Default: 1 (yes). In versions before 0.3, this feature did not exist, so you can get the old behavior with -matchNoise 0"
    echo " -altReg <0|1>"
    echo "   Default: 0. If coreg failed, try clearing your output directory and re-running with -altReg 1. Internally, coreg runs with two different masks, then the one with the lowest cost function is used. Running with altReg 1 will use the other option of the two, which often times will fix things if it didn't work the first time. Running with this in general is not advised. Use it only to fix failures with specific inputs."
    echo ""
    echo " -faceMask <PATH>"
    echo "   Default: ''. Overrides the mask defining face regions to replace. This image MUST be in the voxel space of MCALT_FaceTemplate_T1.nii. Voxel value 1 = face; voxel value 2 = air behind the head potentially containing wraped face-parts; voxel value 3 = ears"
    echo "   Warning: Using this option may produce de-faced images that do NOT offer adequate protection from re-identification"
    echo ""
    exit 65;
fi

outdir=$(readlink -f $2)
if [ ! -w $outdir ] #make sure <output> exists and is writable
then
  if [ ! -d $outdir ]; then
      mkdir -p $outdir
  else
      echo "Output directory $outdir is not writable."
      exit 1
  fi
fi

tmpdir="$(mktemp -d)"
trap 'rm -rf -- "$tmpdir"' EXIT
mkdir $tmpdir/inputs
input_tmp=$tmpdir/inputs
mkdir $tmpdir/outputs
output_tmp=$tmpdir/outputs
mkdir $tmpdir/regmask
reg_dir=$tmpdir/regmask
chmod =777 -R $tmpdir

if [ -d $1 ] #check if input is a directory
then
    mkdir $input_tmp/$(basename $(readlink -f $1))
    cp -r $1/* $input_tmp/$(basename $(readlink -f $1))
    input=$input_tmp/$(basename $(readlink -f $1))
else
    IFS=',' read -a imgs <<< "$1"
    if [ ${#imgs[@]} -eq 1 ] #splitting by comma didn't do anything, try semicolon
    then
	IFS=';' read -a imgs <<< "$1"
    fi
    
    for i in ${imgs[@]}
    do
	cp -r $i $input_tmp
	nifti_str=$nifti_str,$input_tmp/$(basename $i)
    done
    input=${nifti_str:1} #trim off leading comma
fi

read -a input_array <<< $@ #looks like we need to store inputs as a named array to reference nicely in loop
for i in $(seq 0 ${#@})
do
    if [[ ${input_array[$i]} ==  "-regFile" ]] || [[ ${input_array[$i]} ==  "-faceMask" ]]
    then
	cp ${input_array[$((i+1))]} $reg_dir/$(basename ${input_array[$((i+1))]}) #copy file into temp
	input_array[$((i+1))]=$reg_dir/$(basename ${input_array[$((i+1))]}) #change argument path to temp dir
    fi 
done

docker run --mount type=bind,src\=$tmpdir,target=$tmpdir mri_reface run_mri_reface.sh $input $output_tmp ${input_array[@]:2 }

cp -r $output_tmp/* $outdir

exit

