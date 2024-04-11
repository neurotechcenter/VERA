classdef NiiOutput < AComponent
    %NIIOUTPUT Creates a .nii file as Output of VERA using spm12's save_nii
    %function
    properties
        VolumeIdentifier
        SavePathIdentifier char
    end
    
    methods
        function obj = NiiOutput()
            obj.VolumeIdentifier   = 'MRI';
            obj.SavePathIdentifier = '';
        end
        
        function Publish(obj)
            obj.AddInput(obj.VolumeIdentifier,           'Volume');
            obj.AddOptionalInput(obj.SavePathIdentifier, 'PathInformation');
        end
        
        function Initialize(obj)
        end
        
        function []= Process(obj, vol)
            % if empty, use dialog (default behavior)
            if isempty(obj.SavePathIdentifier)
                [file, path] = uiputfile('*.nii');
                if isequal(file, 0) || isequal(path, 0)
                    error('Selection aborted');
                end
            % Otherwise, save on relative path in project folder using component name as file name
            else
                [path, file, ext] = fileparts(obj.SavePathIdentifier);
                file = [file,ext];

                path = fullfile(obj.ComponentPath,'..',path); 

                if ~strcmp(ext,'.nii')
                    path = fullfile(obj.ComponentPath,'..',obj.SavePathIdentifier); 
                    file = [obj.Name,'.nii'];
                    file = replace(file,' ','_');
                end
            end

            % create save folder if it doesn't exist
            if ~isfolder(path)
                mkdir(path)
            end
            
            if(isfield(vol.Image,'untouch') && vol.Image.untouch == 1)
                save_untouch_nii(vol.Image,fullfile(path,file));
            else
                save_nii(vol.Image,fullfile(path,file));
            end

            % Popup stating where file was saved
            msgbox(['File saved as: ',GetFullPath(fullfile(path,file))],['"',obj.Name,'" file saved'])
        end
        
    end
end

