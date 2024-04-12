classdef ObjOutput < AComponent
    %NIIOUTPUT Creates a .nii file as Output of VERA using spm12's save_nii
    %function
    properties
        SurfaceIdentifier
        SavePathIdentifier char
    end
    
    methods
        function obj = ObjOutput()
            obj.SurfaceIdentifier  = 'Surface';
            obj.SavePathIdentifier = '';
        end
        
        function Publish(obj)
            obj.AddInput(obj.SurfaceIdentifier,          'Surface');
            obj.AddOptionalInput(obj.SavePathIdentifier, 'PathInformation');
        end
        
        function Initialize(obj)
        end
        
        function []= Process(obj, surf)
            % if empty, use dialog (default behavior)
            if isempty(obj.SavePathIdentifier)
                [file, path] = uiputfile('*.obj');
                if isequal(file, 0) || isequal(path, 0)
                    error('Selection aborted');
                end
            % Otherwise, save on relative path in project folder using component name as file name
            else
                [path, file, ext] = fileparts(obj.SavePathIdentifier);
                file = [file,ext];

                path = fullfile(obj.ComponentPath,'..',path); 

                if ~strcmp(ext,'.obj')
                    path = fullfile(obj.ComponentPath,'..',obj.SavePathIdentifier); 
                    file = [obj.Name,'.obj'];
                    file = replace(file,' ','_');
                end
            end

            % create save folder if it doesn't exist
            if ~isfolder(path)
                mkdir(path)
            end
            
            % Make a material structure
            % material(1).type = 'newmtl';
            % material(1).data = 'skin';
            % material(2).type = 'Ka';
            % material(2).data = [0.8 0.4 0.4];
            % material(3).type = 'Kd';
            % material(3).data = [0.8 0.4 0.4];
            % material(4).type = 'Ks';
            % material(4).data = [1 1 1];
            % material(5).type = 'illum';
            % material(5).data = 2;
            % material(6).type = 'Ns';
            % material(6).data = 27;
            
            % Make OBJ structure
            OBJ_out.vertices                 = surf.Model.vert;
            % OBJ_out.material                 = material;
            OBJ_out.objects(1).type          = 'g';
            OBJ_out.objects(1).data          = 'skin';
            OBJ_out.objects(2).type          = 'usemtl';
            OBJ_out.objects(2).data          = 'skin';
            OBJ_out.objects(3).type          = 'f';
            OBJ_out.objects(3).data.vertices = surf.Model.tri;
            OBJ_out.objects(3).data.normal   = surf.Model.tri;

            write_wobj(OBJ_out, fullfile(path,file));

            % Popup stating where file was saved
            msgbox(['File saved as: ',GetFullPath(fullfile(path,file))],['"',obj.Name,'" file saved'])
        end
        
    end
end

