classdef CalculateDistanceToSurfaceLabel < AComponent
    %CALCULATECLOSESTSURFACELABEL Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        SurfaceIdentifier
        ElectrodeLocationIdentifier
    end
    
    methods
        function obj = CalculateDistanceToSurfaceLabel()
            %CALCULATECLOSESTSURFACELABEL Construct an instance of this class
            %   Detailed explanation goes here
            obj.SurfaceIdentifier ='Surface';
            obj.ElectrodeLocationIdentifier='ElectrodeLocation';
        end
        
        function  Publish(obj)
            obj.AddInput(obj.SurfaceIdentifier,'Surface');
            obj.AddInput(obj.ElectrodeLocationIdentifier,'ElectrodeLocation');
            obj.AddOutput(obj.ElectrodeLocationIdentifier,'ElectrodeLocation');
           
        end

        function Initialize(obj)          
        end

        function out=Process(obj,surf,elLocs)
            out=obj.CreateOutput(obj.ElectrodeLocationIdentifier,elLocs);
            replace_for_Annotation={'_','-','(',')'};
            annotationIds=[surf.AnnotationLabel.Identifier];
            for i=1:length(annotationIds)
                 vert=surf.Model.vert(surf.Annotation == annotationIds(i),:);
                 if(~isempty(vert))
                     for i_loc=1:size(out.Location,1)
                        [~,dist]=findNearestNeighbors(pointCloud(vert),out.Location(i_loc,:),1);
                        out.SetAnnotation(i_loc,[replace(surf.AnnotationLabel(i).Name,replace_for_Annotation,'') 'Distance'],dist);
                        %voxLoc=round(surf.Ras2Vox(out.Location(i_loc,:)));
                        %out.SetAnnotation(i_loc,['Is' replace(obj.internalLabels{i},replace_for_Annotation,'')],binaryVol(voxLoc(1),voxLoc(2),voxLoc(3)));
                     end
                 end
            end
        end

    end
end

