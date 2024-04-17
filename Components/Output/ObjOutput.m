classdef ObjOutput < AComponent
    %NIIOUTPUT Creates a .nii file as Output of VERA using spm12's save_nii
    %function
    properties
        ElectrodeLocationIdentifier
        SurfaceIdentifier
        SavePathIdentifier char
    end
    
    methods
        function obj = ObjOutput()
            obj.ElectrodeLocationIdentifier = 'ElectrodeLocation';
            obj.SurfaceIdentifier           = 'Surface';
            obj.SavePathIdentifier          = '';
        end
        
        function Publish(obj)
            obj.AddInput(obj.ElectrodeLocationIdentifier, 'ElectrodeLocation');
            obj.AddInput(obj.SurfaceIdentifier,           'Surface');
            obj.AddOptionalInput(obj.SavePathIdentifier,  'PathInformation');
        end
        
        function Initialize(obj)
        end
        
        function []= Process(obj, eLocs, surf)
            % if empty, use dialog (default behavior)
            if isempty(obj.SavePathIdentifier)
                [file, path] = uiputfile('*.obj');
                if isequal(file, 0) || isequal(path, 0)
                    error('Selection aborted');
                end
                [path, file, ext] = fileparts(fullfile(path,file));

            % Otherwise, save on relative path in project folder using component name as file name
            else
                [path, file, ext] = fileparts(obj.SavePathIdentifier);

                path = fullfile(obj.ComponentPath,'..',path); 

                if ~strcmp(ext,'.obj')
                    path = fullfile(obj.ComponentPath,'..',obj.SavePathIdentifier); 
                    file = [obj.Name];
                    file = replace(file,' ','_');
                    ext = '.obj';
                end
            end

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
            msgbox(['File saved as: ',GetFullPath(fullfile(path,[file,ext]))],['"',obj.Name,'" file saved'])
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