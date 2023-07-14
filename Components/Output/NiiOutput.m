classdef NiiOutput < AComponent
    %NIIOUTPUT Creates a .nii file as Output of VERA using spm12's save_nii
    %function
    properties
        VolumeIdentifier
    end
    
    methods
        function obj = NiiOutput()
            obj.VolumeIdentifier='MRI';
        end
        
        function Publish(obj)
            obj.AddInput(obj.VolumeIdentifier,'Volume');
        end
        
        function Initialize(obj)
        end
        
        function []= Process(obj, vol)
            [file,path]=uiputfile('*.nii');
            if isequal(file,0) || isequal(path,0)
                error('Selection aborted');
            end
            
            if(isfield(vol.Image,'untouch') && vol.Image.untouch == 1)
                save_untouch_nii(vol.Image,fullfile(path,file));
            else
                save_nii(vol.Image,fullfile(path,file));
            end   
        end
        
    end
end

