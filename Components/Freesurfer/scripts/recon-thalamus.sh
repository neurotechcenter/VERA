#!/bin/bash
# first arg is fs install directory, second arg is subject directory, third arg is subject
export FREESURFER_HOME="$1"
source $FREESURFER_HOME/SetUpFreeSurfer.sh
segmentThalamicNuclei.sh "$3" "$2"