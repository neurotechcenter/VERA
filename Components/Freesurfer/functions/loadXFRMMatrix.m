function [xfrm_matrices] = loadXFRMMatrix(workspace_path,pathToFsInstallDirectory,fs_subj_dir)
%loadXFRMMatrix - get xfrm matrx from freesurfer volume
%workspace_path - path to workspace, location where xfrm_matrices file will
%be stored
%pathToFsInstallDirectory - path to freesurfer installation
%fs_subj_dir - subject directory


if(exist(fullfile(fs_subj_dir,'mri/orig.mgz'),'file') ~= 0)
    freesurfer_file_path=fullfile(fs_subj_dir,'mri/');
    freesurfer_file='orig.mgz';
else
    error('Could not find orig.mgz in freesurfer path');
    
end

shellcommand = ['./get_xfrm_matrices.sh ' pathToFsInstallDirectory ' ' fullfile(freesurfer_file_path,freesurfer_file) ' '  workspace_path '&'];
system(shellcommand);
pause(3);
wspace_dir=dir(workspace_path);
if(~any(contains({wspace_dir.name},'xfrm_matrices')))
    error('xfrm matrices script failed: Make sure that the get_xfrm_matrices.sh script has execution permission... run: chmod +x get_xfrm_matrices.sh');
end


xfrm_matrices = importdata(fullfile(workspace_path,'xfrm_matrices'));
end

