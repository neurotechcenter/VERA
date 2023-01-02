function [xfrm_matrices] = loadXFRMMatrix(freesurferPath,segmentationPath,fileoutPath,subsyspath)
%loadXFRMMatrix - get xfrm matrx from freesurfer volume
%workspace_path - path to workspace, location where xfrm_matrices file will
%be stored
%pathToFsInstallDirectory - path to freesurfer installation
%fs_subj_dir - subject directory

    xfrm_matrix_path=fullfile(fileparts(fileparts(mfilename('fullpath'))),'scripts','get_xfrm_matrices.sh');
    xfrm_matrix_out_path=fileoutPath;
    mri_path=fullfile(segmentationPath,'mri/orig.mgz');
    if(~exist(mri_path,"file"))
        error('Could not find orig.mgz in the Freesurfer segmentation folder! Segmentation invalid!');
    end
    if(ismac || isunix)
        system(['chmod +x ''' xfrm_matrix_path ''''],'-echo');
        system([xfrm_matrix_path ' ''' freesurferPath ''' ''' ...
            mri_path ''' ''' ...
            xfrm_matrix_out_path ''''],'-echo');
    elseif(ispc)
        w_xfrm_matrix_path=convertToUbuntuSubsystemPath(xfrm_matrix_path,subsyspath);
        w_freesurferPath=convertToUbuntuSubsystemPath(freesurferPath,subsyspath);
        w_mri_path=convertToUbuntuSubsystemPath(mri_path,subsyspath);
        w_xfrm_matrix_out_path=convertToUbuntuSubsystemPath(xfrm_matrix_out_path,subsyspath);
        systemWSL(['chmod +x ''' w_xfrm_matrix_path ''''],'-echo');
        systemWSL(['''' w_xfrm_matrix_path ''' ''' w_freesurferPath ''' ''' ...
            w_mri_path ''' ''' ...
            w_xfrm_matrix_out_path ''''],'-echo');
    else
        error('Couldnt determine operating system');
    end
    
    xfrm_matrices=importdata(fullfile(xfrm_matrix_out_path,'xfrm_matrices'));
end

