function nii_path = createTempNifti(inPath,tempPath,freesurferPath)
%createTempNifti create a temporary nifti file using Freesurfers
%mri_convert
%  inpath - path of the file wanting to convert
%  tempPath - path to temporary folder
%  freesurferPath - path to freesurfer
%  Output:
%   path to temporary nifti file


inPath=strrep(inPath,'\','/'); %normalize paths
tempPath=strrep(tempPath,'\','/');
freesurferPath=strrep(freesurferPath,'\','/');
[~,temp_name]=fileparts(tempname);
nii_path=fullfile(tempPath,[temp_name '.nii']);
convert_script_path=fullfile(fileparts(fileparts(mfilename('fullpath'))),'scripts','convert_to_nii.sh');
if(ismac || isunix)
    [status, cmdout] = system(['chmod +x ''' convert_script_path ''''],'-echo');
    [status, cmdout] = system([convert_script_path ' ''' freesurferPath ''' ''' ...
    inPath ''' ''' ...
    nii_path ''''],'-echo');
else
    subsyspath=DependencyHandler.Instance.GetDependency('UbuntuSubsystemPath');
    w_convert_script_path=convertToUbuntuSubsystemPath(convert_script_path,subsyspath);
    w_freesurferPath=convertToUbuntuSubsystemPath(freesurferPath,subsyspath);
    w_dicom_path=convertToUbuntuSubsystemPath(inPath,subsyspath);
    w_nii_path=convertToUbuntuSubsystemPath(nii_path,subsyspath);
    [status, cmdout] = systemWSL(['chmod +x ''' w_convert_script_path ''''],'-echo');
    %system(['bash -c '' chmod +x ' w_xfrm_matrix_path ''''],'-echo');
    [status, cmdout] = systemWSL(['''' w_convert_script_path ''' ''' w_freesurferPath ''' ''' ...
    w_dicom_path ''' ''' ...
    w_nii_path ''''],'-echo'); 
end

if status
    errordlg(cmdout)
end

end

