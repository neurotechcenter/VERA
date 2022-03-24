function [nii_path] = createTempNifti(inPath,tempPath,freesurferPath)
%CREATETEMPNIFTI Summary of this function goes here
%   Detailed explanation goes here
[~,temp_name]=fileparts(tempname);
nii_path=fullfile(tempPath,[temp_name '.nii']);
convert_script_path=fullfile(fileparts(fileparts(mfilename('fullpath'))),'scripts','convert_to_nii.sh');
if(ismac || isunix)
    system(['chmod +x ''' convert_script_path ''''],'-echo');
    system([convert_script_path ' ''' freesurferPath ''' ''' ...
    inPath ''' ''' ...
    nii_path ''''],'-echo');
else
    subsyspath=DependencyHandler.Instance.GetDependency('UbuntuSubsystemPath');
    w_convert_script_path=convertToUbuntuSubsystemPath(convert_script_path,subsyspath);
    w_freesurferPath=convertToUbuntuSubsystemPath(freesurferPath,subsyspath);
    w_dicom_path=convertToUbuntuSubsystemPath(inPath,subsyspath);
    w_nii_path=convertToUbuntuSubsystemPath(nii_path,subsyspath);
    systemWSL(['chmod +x ''' w_convert_script_path ''''],'-echo');
    %system(['bash -c '' chmod +x ' w_xfrm_matrix_path ''''],'-echo');
    systemWSL(['''' w_convert_script_path ''' ''' w_freesurferPath ''' ''' ...
    w_dicom_path ''' ''' ...
    w_nii_path ''''],'-echo'); 
end

end

