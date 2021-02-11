classdef FSDicomImport < AComponent
    %FSDICOMEXPORT Summary of this class goes here
    %   Detailed explanation goes here
    
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
            nii_path=fullfile(obj.GetDependency('TempPath'),'temp.nii');
            
            out=obj.CreateOutput(obj.Identifier);
            freesurferPath=obj.GetDependency('Freesurfer');
            convert_script_path=fullfile(fileparts(fileparts(mfilename('fullpath'))),'scripts','convert_to_nii.sh');
            if(ismac || isunix)
                system(['chmod +x ''' convert_script_path ''''],'-echo');
                system([convert_script_path ' ''' freesurferPath ''' ''' ...
                dicom_path ''' ''' ...
                nii_path ''''],'-echo');
            else
                subsyspath=obj.GetDependency('UbuntuSubsystemPath');
                w_convert_script_path=convertToUbuntuSubsystemPath(convert_script_path,subsyspath);
                w_freesurferPath=convertToUbuntuSubsystemPath(freesurferPath,subsyspath);
                w_dicom_path=convertToUbuntuSubsystemPath(dicom_path,subsyspath);
                w_nii_path=convertToUbuntuSubsystemPath(nii_path,subsyspath);
                systemWSL(['chmod +x ''' w_convert_script_path ''''],'-echo');
                %system(['bash -c '' chmod +x ' w_xfrm_matrix_path ''''],'-echo');
                systemWSL(['''' w_convert_script_path ''' ''' w_freesurferPath ''' ''' ...
                w_dicom_path ''' ''' ...
                w_nii_path ''''],'-echo'); 
            end
            out.LoadFromFile(nii_path);
            
        end
    end
end

