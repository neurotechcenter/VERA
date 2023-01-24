classdef PointSet < AData
    %PointSet - generic data object for 3D points including labels and
    %annotations 
    %See also AData
    
    properties
        Location %Location as a nx3 vector
        Label %Cell array of labels associated with location
        Annotation % Annotation for each location to add auxiliary information, Annotations are added as field to the struct
    end
    
    methods
        function obj = PointSet()
            obj.Location=zeros(0,3);
            obj.Annotation=struct;
            obj.Label={};
        end
        function SetLabel(obj,identifier, label)
            %SetLabel - removes all existing labels and replaces it with
            %the specified label 
            for i=1:length(identifier)
                if(iscell(label))
                    obj.Label{identifier(i)}=label;
                else
                    obj.Label{identifier(i)}={label};
                end
            end
        end
        
        function ResortElectrodes(obj,newLocs)
            %ResortElectrodes   - resort the electrode locations together
            %with Labels and Annotations
            oldLocs=sort(newLocs);
            
            obj.Label(oldLocs)=obj.Label(newLocs);
            obj.Location(oldLocs,:)=obj.Location(newLocs,:);
           
            if(~isempty((fieldnames(obj.Annotation))))
                obj.Annotation(oldLocs)=obj.Annotation(newLocs);
            end
        end
        
        function DeleteAnnotations(obj,identifier)
            % DeleteAnnotations - delete annotation based on the name of
            % the struct
            buffLabel=fieldnames(obj.Annotation(identifier));
            for i=1:length(buffLabel)
                for id=1:length(identifier)
                    obj.Annotation(identifier(id)).(buffLabel{i})=[];
                end
            end
        end


        function AddLabel(obj,identifier, label)
            %Adds a new Label for location - duplicates will be removed
            %automatically
            % identifier - index of the location
            % Label to add
            for i=1:length(identifier)
                if(~any(strcmp(obj.Label{identifier(i)},label))) %avoid duplicate labels
                    obj.Label{identifier(i)}{end+1}=label;
                end
            end
        end


        function SetAnnotation(obj, identifier, label, value)
            %SetAnnotation - creates a new annotation, if annotation
            %already exists, use DeleteAnnotations first
            %see Also DeleteAnnotations
            % identifier - identifier of the electrode
            % annotation struct
            % label - name of the annotation
            % value - value for the annotation
            if(isfield(obj.Annotation,identifier) &&  ~isempty(obj.Annotation(identifier).(label)))
                error(['Annotation ' label ' is already set for Electrode ' num2str(identifier) '!']);
            end
            obj.Annotation(identifier).(label)=value;
            
        end

        function annot=GetAnnotation(obj, identifier, label)
            %GetAnnotation returns the value for a specific electrode
            % identifier - point for which the annotation should be
            % retrieved
            % label - the specific annotation value
            % returns:
            % empty if no annotation was found
            if(length(obj.Annotation) >= identifier && isfield(obj.Annotation(identifier),label))
                annot=obj.Annotation(identifier).(label);
            else
                annot=[];
            end
        end
    end
    
    methods (Access = protected)
        function deSerializationDone(obj,docNode)
            % override of deSerialization to make sure that older projects
            % which didnt include Labels will load properly
            fileprops=fieldnames(docNode);
            if(~any(strcmp('Label',fileprops)))
                obj.Label(1:size(obj.Location,1))={''};
            end
        end
    end
end

