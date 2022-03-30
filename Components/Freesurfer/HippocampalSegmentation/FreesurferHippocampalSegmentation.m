classdef FreesurferHippocampalSegmentation < AComponent
    %FreesurferHippocampalSegmentation runs Freesurfers hippocampal
    %subsegmentation and loads the volume with L and R prefixes
    
    properties
        VolumeIdentifier
        SegmentationPathIdentifier
    end
    
    methods
        function obj = FreesurferHippocampalSegmentation()
            obj.VolumeIdentifier='Hippocampus';
            obj.SegmentationPathIdentifier='SegmentationPath';
        end
        
        function Publish(obj)
            obj.AddOptionalInput(obj.SegmentationPathIdentifier,'PathInformation',true);
            obj.AddOutput(['L' obj.VolumeIdentifier],'Volume');
            obj.AddOutput(['R' obj.VolumeIdentifier],'Volume');

            
        end
        
        function Initialize(obj)
            path=obj.GetDependency('Freesurfer');
            addpath(fullfile(path,'matlab'));
            if(ispc)
                obj.GetDependency('UbuntuSubsystemPath');
               if(system('WHERE bash >nul 2>nul echo %ERRORLEVEL%') == 1)
                   error('If you want to use Freesurfer components on windows, the Windows 10 Ubuntu subsystem is required!');
               else
                   disp('Found ubuntu subsystem on Windows 10!');
                   disp('This Component requires GUI Access to freeview, make sure you can run freeview from the Linux subsystem, together with the matlab R2014b runtime');
               end
            end
        end
        
        function [lHC,rHC]=Process(obj,optInp)
            if(nargin > 1) %segmentation path exists
                segmentationPath=optInp.Path;
                comPath=fileparts(obj.ComponentPath);
                segmentationPath=fullfile(comPath,segmentationPath); %create full path
            else
                segmentationPath=uigetdir([],'Please select Freesurfer Segmentation');
                if(isempty(segmentationPath))
                    error('No path selected!');
                end
            end
            LfileName=fullfile(segmentationPath,'mri','lh.hippoAmygLabels-T1.v21.mgz');
            RfileName=fullfile(segmentationPath,'mri','rh.hippoAmygLabels-T1.v21.mgz');

            freesurferPath=obj.GetDependency('Freesurfer');
            if(~exist(LfileName,'file') || ~exist(RfileName,'file'))
                
                recon_script=fullfile(fileparts(fileparts(mfilename('fullpath'))),'/scripts/recon-hippocampus.sh');
                [segmentationPath,subj_name]=fileparts(segmentationPath);
                if(ispc)
                    subsyspath=obj.GetDependency('UbuntuSubsystemPath');
                    wsl_segm_path=convertToUbuntuSubsystemPath(segmentationPath,subsyspath);
                    wsl_recon_script=convertToUbuntuSubsystemPath(recon_script,subsyspath);
                    w_freesurferPath=convertToUbuntuSubsystemPath(freesurferPath,subsyspath);
                    systemWSL(['chmod +x ''' wsl_recon_script ''''],'-echo');
                    shellcmd=['''' wsl_recon_script ''' ''' w_freesurferPath ''' ''' ...
                    wsl_segm_path ''' ' ...
                    '''' subj_name ''''];
                    systemWSL(shellcmd,'-echo');
                else
                    system(['chmod +x ''' recon_script ''''],'-echo');
                    shellcmd=['''' recon_script ''' ''' freesurferPath ''' ''' ...
                    segmentationPath ''' ' ...
                    '''' subj_name ''''];
                    system(shellcmd,'-echo');
                end
            end
            if(~exist(LfileName,'file') || ~exist(RfileName,'file'))
                error('Error - no output files generated after running segmentation!');
            end
            nii_path=createTempNifti(LfileName,obj.GetDependency('TempPath'),freesurferPath);
            lHC=obj.CreateOutput(['L' obj.VolumeIdentifier]);
            lHC.LoadFromFile(nii_path);
            delete(nii_path);
            nii_path=createTempNifti(RfileName,obj.GetDependency('TempPath'),freesurferPath);
            rHC=obj.CreateOutput(['R' obj.VolumeIdentifier]);
            rHC.LoadFromFile(nii_path);   
            delete(nii_path);
        end
        

    end
end

