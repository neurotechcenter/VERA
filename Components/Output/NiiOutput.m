classdef NiiOutput < AComponent
    %NiiOutput Creates a .nii file as Output of VERA using spm12's save_nii
    %function
    properties
        VolumeIdentifier
        RASResliceFlag
        SavePathIdentifier char
    end
    
    methods
        function obj = NiiOutput()
            obj.VolumeIdentifier   = 'MRI';
            obj.RASResliceFlag     = 1;
            obj.SavePathIdentifier = 'default';
        end
        
        function Publish(obj)
            obj.AddInput(obj.VolumeIdentifier, 'Volume');
        end
        
        function Initialize(obj)
        end
        
        function []= Process(obj, vol)

            % create output file in DataOutput folder with ProjectName_ComponentName.mat (default behavior)
            if strcmp(obj.SavePathIdentifier,'default')
                ProjectPath      = fileparts(obj.ComponentPath);
                [~, ProjectName] = fileparts(ProjectPath);

                path = fullfile(obj.ComponentPath,'..','DataOutput');
                file = [ProjectName, '_', obj.Name,'.nii'];

            % if empty, use dialog
            elseif isempty(obj.SavePathIdentifier)
                [file, path] = uiputfile('*.nii');
                if isequal(file, 0) || isequal(path, 0)
                    error('Selection aborted');
                end
                
            % Otherwise, save with specified file name
            else
                [path, file, ext] = fileparts(obj.SavePathIdentifier);
                file = [file,ext];
                path = fullfile(obj.ComponentPath,'..',path);

                if ~strcmp(ext,'.nii')
                    path = fullfile(obj.ComponentPath,'..',obj.SavePathIdentifier);
                    file = [obj.Name,'.nii'];
                end
            end

            % convert spaces to underscores
            file = replace(file,' ','_');

            % create save folder if it doesn't exist
            if ~isfolder(path)
                mkdir(path)
            end

            % Reslice volume to be in RAS coordinates using same pixel size
            if obj.RASResliceFlag
                vol = vol.GetRasSlicedVolume(vol.Image.hdr.dime.pixdim(2:4),1);
            end
            
            if(isfield(vol.Image,'untouch') && vol.Image.untouch == 1)
                save_untouch_nii(vol.Image,fullfile(path,file));
            else
                save_nii(vol.Image,fullfile(path,file));
            end

            % Popup stating where file was saved
            message    = {'File saved as:',GetFullPath(fullfile(path,file))};
            msgBoxSize = [350, 125];
            obj.VERAMessageBox(message,msgBoxSize);
        end
        
    end
end

