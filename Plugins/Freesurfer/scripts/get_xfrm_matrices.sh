# first argument is the directory where freesurfer is installed
# second argument is path to volume (e.g., .mgz) file
# third argument is path to subject directory (not the one in freesurfer)

# set up freesurfer in shell
export FREESURFER_HOME=$1
source $FREESURFER_HOME/SetUpFreeSurfer.sh


# get and store the xfrm matrices
cd "$3"
touch xfrm_matrices
mri_info --vox2ras "$2" > xfrm_matrices
mri_info --vox2ras-tkr "$2" >> xfrm_matrices


# matlab will then use import_data() on xfrm_matrices to get the xfrm_matrices
# in its environment. then it will perform the transformation

exit