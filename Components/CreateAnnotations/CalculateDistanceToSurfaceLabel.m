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
            [annotation_remap,cmap,names,name_id]=createColormapFromAnnotations(surf);
            annotationIds=[surf.AnnotationLabel.Identifier];
            for i=1:length(annotationIds)
                 vert=surf.Model.vert(surf.Annotation == annotationIds(i),:);
                 if(~isempty(vert))
                     for i_loc=1:size(out.Location,1)
                        [~,dist]=findNearestNeighbors(pointCloud(vert),out.Location(i_loc,:),1);
                        old_data=out.GetAnnotation(i_loc,'Distance');
                        old_data_label=out.GetAnnotation(i_loc,'Label');
                        old_data_label_id=out.GetAnnotation(i_loc,'LabelId');
                        old_data(end+1)=dist;
                        old_data_label{end+1}=surf.AnnotationLabel(find([surf.AnnotationLabel.Identifier] == annotationIds(i))).Name;
                        old_data_label_id(end+1)=annotationIds(i);
                        out.SetAnnotation(i_loc,'Distance',old_data);
                        out.SetAnnotation(i_loc,'Label',old_data_label); 
                        out.SetAnnotation(i_loc,'LabelId',old_data_label_id);
                        %voxLoc=round(surf.Ras2Vox(out.Location(i_loc,:)));
                        %out.SetAnnotation(i_loc,['Is' replace(obj.internalLabels{i},replace_for_Annotation,'')],binaryVol(voxLoc(1),voxLoc(2),voxLoc(3)));
                     end
                 end
            end
        end

    end
end

