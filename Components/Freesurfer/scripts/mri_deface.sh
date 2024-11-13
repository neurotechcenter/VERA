#!/bin/bash
# first arg is fs install directory, second arg is input volume, third arg is path to talairach_mixed_with_skull.gca, fourth is path to face.gca, and fifth is output volume
export FREESURFER_HOME=$1
source $FREESURFER_HOME/SetUpFreeSurfer.sh
mri_deface "$2" "$3" "$4" "$5"