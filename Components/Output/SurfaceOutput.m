classdef SurfaceOutput < AComponent
    %NiiOutput Creates a .nii file as Output of VERA using spm12's save_nii
    %function
    properties
        SurfaceIdentifier
        SavePathIdentifier char
    end
    
    methods
        function obj = SurfaceOutput()
            obj.SurfaceIdentifier  = 'Surface';
            obj.SavePathIdentifier = 'default';
        end
        
        function Publish(obj)
            obj.AddInput(obj.SurfaceIdentifier, 'Surface');
        end
        
        function Initialize(obj)
        end
        
        function []= Process(obj, surf)

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

            % Write surface to a file
            write_surf(fullfile(path,file),surf.Model.vert,surf.Model.tri);

            % Popup stating where file was saved
            message    = {'File saved as:',GetFullPath(fullfile(path,file))};
            msgBoxSize = [350, 125];
            obj.VERAMessageBox(message,msgBoxSize);
        end
        
    end
end

