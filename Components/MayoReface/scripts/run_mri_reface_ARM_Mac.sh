#!/bin/bash
exe_name=$0
exe_dir=$3                      # need to provide tool path because we are not using the default shell script
export MCRROOT=$4               # Matlab 2022a runtime
export PATH=$PATH:$5:$6         # ANT and nifty_reg install/bin folders
export MATLAB_SHELL="/bin/bash" # change to use bash instead of zsh

exe_str="${exe_dir}/mri_reface"
if [ "$(uname)" == "Darwin" ]; then
  exe_str="${exe_dir}/mri_reface.app/Contents/MacOS/mri_reface"
fi
deps=(ANTS antsApplyTransforms reg_aladin)
if [ $# -lt 2 ]
then
  echo "mri_reface: replaces face and ear imagery in MRI with an average face, to help prevent potential re-identification"
  echo "Version 0.3.5"
  echo "By: Christopher G. Schwarz schwarz.christopher@mayo.edu"
  echo "For details, see: https://doi.org/10.1016/j.neuroimage.2021.117845"
  echo ""
  echo "Usage: "
  echo "$0 <Input .nii> <Output directory> [options]"
  echo ""
  echo "Multiple .nii files can be specified using a list of .nii files separated by a , or ;. Example: "nii1.nii,.nii2.nii". The first .nii file is treated as the base image for nonlinear registration to the template. Subsequent .nii files will be coregistered to the base image and transformed using the base image's nonlinear registration. Each re-faced image will be output in its original image space. For example, you could re-face a T1 and a FLAIR, using the T1 as the base image for registration, but both will be output in their original spaces. You could also input individual 3D frames of a dynamic PET image, even if they have not been previously coregistered."
  echo "4-D .nii files can also be used. For MRIs, the 3D volumes in the 4D .nii will be treated as already-coregistered (i.e. multiple echoes), and registration to the template will use the mean across volumes. For PET, the individual frames will be automatically split up and each will be de-faced using its registration to the first frame or the first input image (if the first input image was not the 4D PET)."
  echo ""
  echo "You can also provide a directory path for the first (input) argument. This directory will be assumed to contain DICOM from a single series. It will be converted to nii with dcm2niix, de-faced, and converted back to DICOM while copying all unrelated DICOM tags from the original DICOM. Using the -imType flag is highly recommended with this approach."
  echo ""
  echo "Additional options: "
  echo " -imType <T1|T2|PD|T2ST|FLAIR|FDG|PIB|FBP|TAU|CT|AUTO>"
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
  echo " -coregistered4D <-1|0|1>"
  echo "   0: assume 4D inputs are NOT coregistered across volumes; 1: assume they are; -1 (default): automatically choose using image types (1 for multi-echo MRI, 0 for PET and other MRI)"
  echo " -TIVTolerance <VALUE>"
  echo "   Sets the radius (in mm) around the estimated TIV (brain boundary) that will be left unmodified. Defaults vary by image type. Values between 5 and and 11 are reasonable. Higher values preserve more brain but too-high may not replace the eyebrow ridge depending on face shape and head size. Generally -TIVToleranceOffset is a better choice."
  echo " -TIVToleranceOffset <VALUE>"
  echo "   Adjusts -TIVTolerance as an offset (in mm) from the per-imagetype defaults. If you are cutting too close to the brain, try setting this to 1,2, or 3. Values >3 are not recommended and may not replace the eyebrow ridge."
  echo " -faceMask <PATH>"
  echo "   Default: ''. Overrides the mask defining face regions to replace. This image MUST be in the voxel space of MCALT_FaceTemplate_T1.nii. Voxel value 1 = face; voxel value 2 = air behind the head potentially containing wraped face-parts; voxel value 3 = ears"
  echo "   Warning: Using this option may produce de-faced images that do NOT offer adequate protection from re-identification"
  echo ""
  echo "This software requires you to install the matlab runtime version 2022a from https://www.mathworks.com/products/compiler/matlab-runtime.html and export its path to \$MCRROOT"
  echo "It also requires these programs to be installed: ${deps[@]}"
  echo "Install them from: http://stnava.github.io/ANTs/ and https://sourceforge.net/projects/niftyreg/files/"
  echo ""
  exit 65;
fi

# Also provide the original LD_LIBRARY_PATH to the program, without matlab's additions that break things for some users
export USER_LD_LIBRARY_PATH="${LD_LIBRARY_PATH}"

if [ -z "${MCRROOT}" ]; then
  echo '$MCRROOT is not set. You MUST set $MCRROOT to the path to your installed matlab runtime library, version 2022a'
  echo 'You can download an installer free from: https://www.mathworks.com/products/compiler/matlab-runtime.html'
  echo 'Then, set $MCRROOT with: export MCRROOT=/path/ or MCRROOT=/path ./run_ADIR_ReFace.sh'
  exit 1
else
  if [ "$(uname)" != "Darwin" ]; then 
      LD_LIBRARY_PATH=.:${MCRROOT}/runtime/glnxa64 ;
      LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:${MCRROOT}/bin/glnxa64 ;
      LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:${MCRROOT}/sys/os/glnxa64;
      LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:${MCRROOT}/sys/opengl/lib/glnxa64;
      export LD_LIBRARY_PATH;
  else
      DYLD_LIBRARY_PATH=.:${MCRROOT}/runtime/maci64 ;
      DYLD_LIBRARY_PATH=${DYLD_LIBRARY_PATH}:${MCRROOT}/bin/maci64 ;
      DYLD_LIBRARY_PATH=${DYLD_LIBRARY_PATH}:${MCRROOT}/sys/os/maci64;
      export DYLD_LIBRARY_PATH;
  fi
fi
# Preload glibc_shim in case of RHEL7 variants
  test -e /usr/bin/ldd &&  ldd --version |  grep -q "(GNU libc) 2\.17"  \
            && export LD_PRELOAD="${MCRROOT}/bin/glnxa64/glibc-2.17_shim.so"

for i in ${deps[@]}; do
  command -v $i >/dev/null 2>&1 || { echo >&2 "This software requires $i but it\'s not installed.  Aborting."; exit 1; }
done

if [ -d $1 ]; then
  echo "You provided a directory for an input, rather than a nii file. We will assume it contains DICOM for a single series. Using the -imType flag is highly recommended with this workflow."
  dcmdir=$1
  outdir=$2

  # Try to find dependencies
  command -v "dcm2niix" >/dev/null 2>&1 || { echo >&2 "This software requires dcm2niix but it\'s not installed.  Aborting."; exit 1; }

  script_dir=$(dirname $(readlink -f ${BASH_SOURCE}))
  if [ -f "${script_dir}/ADIR_nii2dicom/bin/ADIR_nii2dicom" ]; then
    nii2d="${script_dir}/ADIR_nii2dicom/bin/ADIR_nii2dicom"
  else
    command -v "ADIR_nii2dicom" >/dev/null 2>&1 || { echo >&2 "This software requires ADIR_nii2dicom but it\'s not installed.  Aborting."; exit 1; }
    nii2d="ADIR_nii2dicom"
  fi

  if [ -f "${script_dir}/ADIR_nii2dicom/bin/ADIR_MarkDICOMDeidentified" ]; then
    markdid="${script_dir}/ADIR_nii2dicom/bin/ADIR_MarkDICOMDeidentified"
  else
    command -v "ADIR_MarkDICOMDeidentified" >/dev/null 2>&1 || { echo >&2 "This software requires ADIR_MarkDICOMDeidentified but it\'s not installed.  Aborting."; exit 1; }
    markdid="ADIR_MarkDICOMDeidentified"
  fi

  mkdir -p $outdir
  mkdir -p ${outdir}/dcm
  chmod +066 -R ${outdir}/dcm
  
  tmpdir="$(mktemp -d)"
  trap 'rm -rf -- "$tmpdir"' EXIT

  echo "Running dcm2niix to convert to nii"
  dcm2niix -o ${tmpdir} $dcmdir

  shift
  shift
  for f in ${tmpdir}/*.nii; do
    fb=$(basename $f .nii)
    cp -v $f $outdir
    ${exe_str} $f $outdir $@
    $nii2d ${outdir}/${fb}_deFaced.nii ${outdir}/dcm $dcmdir
    $markdid ${outdir}/dcm -o -c 113102 -c "replace_recognizable;Replace face, ears, and artifacts in air" --software mri_reface --softwareVersion '0.3.5'
  done
  echo "De-faced DICOM was written to "${outdir}/dcm". This DICOM metadata is NOT otherwise de-identified. Only de-facing was performed. If you need the meta-data de-identified also, you should run it through your preferred DICOM de-identification software."
else
  ${exe_str} $@
fi



exit

