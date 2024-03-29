classdef FSDicomImport < AComponent
    %FSDicomImport - Import imaging using freesurfers mri-convert. 
    %In addition to using DICOM it can also be used to import data from
    %Freesurfers mgz format
    
    properties
        Identifier
    end
    
    methods
        function obj = FSDicomImport()

        end
        
        function Publish(obj)
            obj.AddOutput(obj.Identifier,'Volume');
            obj.RequestDependency('Freesurfer','folder');
            if(ispc)
                obj.RequestDependency('UbuntuSubsystemPath','folder');
            end
        end
        
        function Initialize(obj)
            path=obj.GetDependency('Freesurfer');
            if(ispc)
                obj.GetDependency('UbuntuSubsystemPath');
               if(system('WHERE bash >nul 2>nul echo %ERRORLEVEL%') == 1)
                   error('If you want to use Freesurfer components on windows, the Windows 10 Ubuntu subsystem is required!');
               else
                   disp('Found ubuntu subsystem on Windows 10!');
               end
            end
        end
        
        function out = Process(obj)
            [file,path]=uigetfile('*.*',['Please select ' obj.Identifier]);
             if isequal(file,0)
                 error([obj.Identifier ' selection aborted']);
             end
            dicom_path=fullfile(path,file);

            
            out=obj.CreateOutput(obj.Identifier);
            freesurferPath=obj.GetDependency('Freesurfer');
            nii_path=createTempNifti(dicom_path,obj.GetDependency('TempPath'),freesurferPath);
            out.LoadFromFile(nii_path);
            delete(nii_path);
            
        end
    end
end

