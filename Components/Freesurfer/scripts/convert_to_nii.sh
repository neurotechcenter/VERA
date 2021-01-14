#!/bin/bash
# first arg is fs install directory, second arg is subject directory, third arg is subject # ID, fourth is the filename of the first dicom file
export FREESURFER_HOME=$1
source $FREESURFER_HOME/SetUpFreeSurfer.sh
export FS_LOAD_DWI=0
mri_convert -i "$2" -o "$3"