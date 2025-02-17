classdef CalculateDistanceToSurfaceLabel < AComponent
    %CalculateDistanceToSurfaceLabel Calculates the distance from an electrode
    %to every available Label defined on a Surface.
    
    properties
        SurfaceIdentifier
        ElectrodeLocationIdentifier
        ElectrodeLocationIdentifierOut
        Prefix
        Radius
        
    end
    
    methods
        function obj = CalculateDistanceToSurfaceLabel()
            %CALCULATECLOSESTSURFACELABEL Construct an instance of this class
            %   Detailed explanation goes here
            obj.SurfaceIdentifier              = 'Surface';
            obj.ElectrodeLocationIdentifier    = 'ElectrodeLocation';
            obj.ElectrodeLocationIdentifierOut = 'ElectrodeLocation';
            obj.Prefix                         = '';
            obj.Radius                         = '0';
        end
        
        function Publish(obj)
            obj.AddInput(obj.SurfaceIdentifier,               'Surface');
            obj.AddInput(obj.ElectrodeLocationIdentifier,     'ElectrodeLocation');
            obj.AddOutput(obj.ElectrodeLocationIdentifierOut, 'ElectrodeLocation');
           
        end

        function Initialize(obj)          
        end

        function out = Process(obj,surf,elLocs)
            out = obj.CreateOutput(obj.ElectrodeLocationIdentifierOut,elLocs);

            [annotation_remap,cmap,names,name_id] = createColormapFromAnnotations(surf);
            annotationIds                         = [surf.AnnotationLabel.Identifier];
            
            if isnumeric(obj.Radius)
                radius = obj.Radius;
            else
                radius = str2double(obj.Radius);
            end

            f = waitbar(0,'Calculating Distance from Electrode to Labels');
            for i = 1:length(annotationIds)
                vert = surf.Model.vert(surf.Annotation == annotationIds(i),:);
                waitbar(i/length(annotationIds),f);
                if(~isempty(vert))
                    for i_loc = 1:size(out.Location,1)
                       [~,dist] = findNearestNeighbors(pointCloud(vert),out.Location(i_loc,:),1);

                       old_data                 = out.GetAnnotation(i_loc,'Distance');
                       old_data_label           = out.GetAnnotation(i_loc,'Label');
                       old_data_label_id        = out.GetAnnotation(i_loc,'LabelId');
                       old_data(end+1)          = dist;
                       old_data_label{end+1}    = [obj.Prefix surf.AnnotationLabel(find([surf.AnnotationLabel.Identifier] == annotationIds(i))).Name];
                       old_data_label_id(end+1) = annotationIds(i);

                       out.SetAnnotation(i_loc, 'Distance', old_data);
                       out.SetAnnotation(i_loc, 'Label',    old_data_label); 
                       out.SetAnnotation(i_loc, 'LabelId',  old_data_label_id);

                       %voxLoc=round(surf.Ras2Vox(out.Location(i_loc,:)));
                       %out.SetAnnotation(i_loc,['Is' replace(obj.internalLabels{i},replace_for_Annotation,'')],binaryVol(voxLoc(1),voxLoc(2),voxLoc(3)));

                    end
                end
            end
               
            % James added
            for i_loc = 1:size(out.Location,1)

                % only surface labels
                surfaceLabel_logical = ismember(out.Annotation(i_loc).Label,names);
                surfaceLabel_idx     = find(surfaceLabel_logical == 1);

                currentLoc           = out.Annotation(i_loc);
                [~,idx]              = min(currentLoc.Distance(surfaceLabel_idx));
                minSurfaceLabel_idx  = surfaceLabel_idx(idx);

                if currentLoc.Distance(minSurfaceLabel_idx) < radius 
                   out.AddLabel(i_loc,currentLoc.Label{minSurfaceLabel_idx}); 
                end
                
            end

            close(f);

        end

    end
end
















