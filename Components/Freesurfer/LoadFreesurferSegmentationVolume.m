classdef LoadFreesurferSegmentationVolume < AComponent
    %LoadFreesurferSegmentationVolume Load a segmentation volume from
    %a Freesurfer segmentation

    properties
        FSVolume
        VolumeIdentifier
        SegmentationPathIdentifier
    end
    
    methods
        function obj = LoadFreesurferSegmentationVolume()
            obj.FSVolume='aseg';
            obj.VolumeIdentifier='ASEG';
            obj.SegmentationPathIdentifier='SegmentationPath';
        end
        
        function Publish(obj)
            obj.RequestDependency('Freesurfer','folder');
            if(ispc)
                obj.RequestDependency('UbuntuSubsystemPath','folder');
            end
            obj.AddOptionalInput(obj.SegmentationPathIdentifier,'PathInformation',true);
            obj.AddOutput(obj.VolumeIdentifier,'Volume');
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
        
        
        function out = Process(obj,path)
                if(nargin > 1) %segmentation path exists
                    segmentationPath=path.Path;
                    comPath=fileparts(obj.ComponentPath);
                    mgz_path=fullfile(comPath,segmentationPath,'mri',[obj.FSVolume '.mgz']); %create full path
                else
                    segmentationPath=uigetdir([],'Please select Freesurfer Segmentation');
                     if isequal(segmentationPath,0)
                         error([obj.VolumeIdentifier ' selection aborted']);
                     end
                    mgz_path=fullfile(segmentationPath,'mri',[obj.FSVolume '.mgz']);

                end
                out=obj.CreateOutput(obj.VolumeIdentifier);
                freesurferPath=obj.GetDependency('Freesurfer');
                nii_path=createTempNifti(mgz_path,obj.GetDependency('TempPath'),freesurferPath);
                out.LoadFromFile(nii_path);
                delete(nii_path);
            
        end

    end
end

