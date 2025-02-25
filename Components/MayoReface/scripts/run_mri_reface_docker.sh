#!/bin/bash

# Function to create a directory and check if it was successful, then set permissions
create_and_set_permissions() {
    local dir_path=$1
    mkdir -p "$dir_path"
    if [ ! -d "$dir_path" ]; then
        echo "Error: Failed to create directory ${dir_path}."
        exit 1
    fi
    chmod 777 "$dir_path"
    if [ $? -ne 0 ]; then
        echo "Error setting permissions on ${dir_path}."
        exit 1
    else
        echo "Permissions set correctly on ${dir_path}."
    fi
}

# Function to get the absolute path of a directory using realpath or equivalent
get_absolute_path() {
    local dir_path=$1
    if command -v realpath > /dev/null; then
        realpath "$dir_path"
    else
        # If realpath is not available, use an alternative method
        (cd "$dir_path" > /dev/null 2>&1 && pwd) || { echo "Error: Unable to access directory $dir_path"; exit 1; }
    fi
}

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

# Convert second script argument (supposedly output directory) to absolute path
outdir=$(get_absolute_path "$2")

# Ensure output directory exists and is writable
create_and_set_permissions "$outdir"
if [ ! -w "$outdir" ]; then
    echo "Output directory $outdir is not writable."
    exit 1
fi

tmpdir="$(mktemp -d)"
trap 'rm -rf -- "$tmpdir"' EXIT

# Create necessary subdirectories and check their creation
create_and_set_permissions "$tmpdir/inputs"
input_tmp="$tmpdir/inputs"

create_and_set_permissions "$tmpdir/outputs"
output_tmp="$tmpdir/outputs"

create_and_set_permissions "$tmpdir/regmask"
reg_dir="$tmpdir/regmask"

# Output the directory paths for verification
echo "Temporary directory: $tmpdir"
echo "Input directory: $input_tmp"
echo "Output directory: $output_tmp"
echo "Registration mask directory: $reg_dir"

if [ -d $1 ] #check if input is a directory
then
    input_basename=$(basename "$(get_absolute_path "$1")")
    create_and_set_permissions "$input_tmp/$input_basename"
    cp -r $1/* "$input_tmp/$input_basename"
    input="$input_tmp/$input_basename"
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

cp -r "$output_tmp"/* "$outdir" || (echo "Error copying results to ${outdir}" && exit 1)

exit 0
