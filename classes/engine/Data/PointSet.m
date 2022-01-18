classdef PointSet < AData
    %LOCATION Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        Location
        Label
        Annotation
    end
    
    methods
        function obj = PointSet()
            obj.Location=zeros(0,3);
            obj.Annotation=struct;
            obj.Label={};
        end
        function SetLabel(obj,identifier, label)
            for i=1:length(identifier)
                obj.Label{identifier(i)}=label;
            end
        end
        function AddLabel(obj,identifier, label)
            for i=1:length(identifier)
                if(~any(strcmp(obj.Label{identifier(i)},label))) %avoid duplicate labels
                    obj.Label{identifier(i)}{end+1}=label;
                end
            end
        end
        function SetAnnotation(obj, identifier, label, value)
            if(isfield(obj.Annotation,identifier) &&  ~isempty(obj.Annotation(identifier).(label)))
                error(['Annotation ' label ' is already set for Electrode ' num2str(identifier) '!']);
            end
            obj.Annotation(identifier).(label)=value;
            
        end
        function annot=GetAnnotation(obj, identifier, label)
            if(length(obj.Annotation) >= identifier && isfield(obj.Annotation(identifier),label))
                annot=obj.Annotation(identifier).(label);
            else
                annot=[];
            end
        end
    end
    
    methods (Access = protected)
        function deSerializationDone(obj,docNode)
            fileprops=fieldnames(docNode);
            if(~any(strcmp('Label',fileprops))) %make sure Label gets filled correctly if the property wasnt serialized .. important for backwards compatability
                obj.Label(1:size(obj.Location,1))={''};
            end
        end
    end
end

