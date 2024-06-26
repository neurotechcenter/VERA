classdef MatOutputNoElectrodes < AComponent
    %MATOUTPUT Creates a .mat file as Output of VERA similar to neuralact
    %but with additional information about electrode locations
    properties
        SurfaceIdentifier
        SavePathIdentifier char
    end
    
    methods
        function obj = MatOutputNoElectrodes()
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
                [file, path] = uiputfile('*.mat');
                if isequal(file, 0) || isequal(path, 0)
                    error('Selection aborted');
                end
            % Otherwise, save on relative path in project folder using component name as file name
            else
                [path, file, ext] = fileparts(obj.SavePathIdentifier);
                file = [file,ext];

                path = fullfile(obj.ComponentPath,'..',path); 

                if ~strcmp(ext,'.mat')
                    path = fullfile(obj.ComponentPath,'..',obj.SavePathIdentifier); 
                    file = [obj.Name,'.mat'];
                    file = replace(file,' ','_');
                end
            end

            % create save folder if it doesn't exist
            if ~isfolder(path)
                mkdir(path)
            end

            surfaceModel.Model           = surf.Model;           % Contains vert (x,y,z points) and tri (triangle triangulation vector) to create the 3D model
                                                                 % specified through SurfaceIdentifier in VERA. Additionally, it also contains triId and vertId,
                                                                 % which allows you to distinguish between the left (1) and right (2) hemisphere if your data 
                                                                 % comes from a freesurfer Surface.
            surfaceModel.Annotation      = surf.Annotation;      % Identifier number associating each vertice of a surface with a given annotation
            surfaceModel.AnnotationLabel = surf.AnnotationLabel; % Surface annotation map connecting identifier values with annotation
            
            save(fullfile(path,file),'surfaceModel');

            % Popup stating where file was saved
            msgbox(['File saved as: ',GetFullPath(fullfile(path,file))],['"',obj.Name,'" file saved'])
        end
       
    end
end

