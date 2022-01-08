classdef PointSet < AData
    %LOCATION Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        Location
        Label
    end
    
    methods
        function obj = PointSet()
            obj.Location=zeros(0,3);
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

