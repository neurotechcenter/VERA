#!/bin/bash
# first arg is fs install directory, second arg is subject directory, third arg is subject # ID, fourth is the filename of the first dicom file
export FREESURFER_HOME=$1
source $FREESURFER_HOME/SetUpFreeSurfer.sh
export FS_LOAD_DWI=0
recon-all -sd "$2" -s "$3" -i "$4"
chmod -R +rwx "$2"
recon-all -cw256 -sd "$2" -s "$3" -all