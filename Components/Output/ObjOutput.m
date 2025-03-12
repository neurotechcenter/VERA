classdef ObjOutput < AComponent
    %ObjOutput Creates an .obj file as Output of VERA using obj_write_color
    properties
        SurfaceIdentifier
        SavePathIdentifier char
    end
    
    methods
        function obj = ObjOutput()
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
                file = [ProjectName, '_', obj.Name];
                ext  = '.obj';

            % if empty, use dialog
            elseif isempty(obj.SavePathIdentifier)
                [file, path]      = uiputfile('*.obj');
                [path, file, ext] = fileparts(fullfile(path,file));
                
                if isequal(file, 0) || isequal(path, 0)
                    error('Selection aborted');
                end
                
            % Otherwise, save with specified file name
            else
                [path, file, ext] = fileparts(obj.SavePathIdentifier);

                path = fullfile(obj.ComponentPath,'..',path);
            end

            % convert spaces to underscores
            file = replace(file,' ','_');

            % create save folder if it doesn't exist
            if ~isfolder(path)
                mkdir(path)
            end

            % surface
            obj_out.vertices = surf.Model.vert;
            obj_out.faces    = surf.Model.tri;

            % rotate 90 degrees in x so the brain is oriented correctly
            obj_out.vertices = rotation(obj_out.vertices, 1, pi/2);

            % colors
            LabelIdx = zeros(size(surf.Annotation));
            RGBvec   = zeros(length(surf.Annotation),3);
            for i = 1:length(surf.Annotation)
                if surf.Annotation(i) ~= 0
                    LabelIdx(i) = find([surf.AnnotationLabel.Identifier] == surf.Annotation(i));
                    RGBvec(i,:) = surf.AnnotationLabel(LabelIdx(i)).PreferredColor;
                end
            end

            % Delete old file (save function appends instead of overwriting)
            if exist(fullfile(path,[file,ext]))
                delete(fullfile(path,[file,ext]));
                delete(fullfile(path,[file,'.mtl']));
            end

            % Save obj
            obj_write_color(obj_out,fullfile(path,file),RGBvec);
          

            % Popup stating where file was saved
            message    = {'File saved as:',GetFullPath(fullfile(path,[file,ext]))};
            msgBoxSize = [350, 125];
            obj.VERAMessageBox(message,msgBoxSize);
        end
        
    end
end

function vertex = rotation(V, indice, angle)
%     [V, F]=stlread("isopoison.stl"); 
%     angle=-pi/2;
    Rz = [ cos(angle), -sin(angle), 0 ;
          sin(angle), cos(angle), 0 ;
    0, 0, 1 ];
    Ry = [ cos(angle), 0, sin(angle) ;
    0, 1, 0 ;
          -sin(angle), 0, cos(angle) ];
    Rx = [ 1, 0, 0 ;
    0, cos(angle), -sin(angle);
    0, sin(angle), cos(angle) ];
    
    if(indice==1)
           vertex = V*Rx;
    end
    if(indice==2)
           vertex = V*Ry;
    end
    if(indice==3)
           vertex = V*Rz;
    end
end 