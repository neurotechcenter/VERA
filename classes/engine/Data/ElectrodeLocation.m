classdef ElectrodeLocation < PointSet
    %ElectrodeLocation Electrode Location in 3D Space 
    %
    
    properties
        DefinitionIdentifier %Identifier connecting the location to the Electrode Definiton
    end
    
    methods
        function obj = ElectrodeLocation()
            obj.DefinitionIdentifier=zeros(1,0,'uint32');
            obj.Label={};
        end
        

        function RemoveWithIdentifier(obj, identifier)
            obj.Location(obj.DefinitionIdentifier == identifier,:)=[];
            obj.DefinitionIdentifier(obj.DefinitionIdentifier == identifier)=[];
            obj.Label(obj.DefinitionIdentifier == identifier)=[];
        end

        function elLocs=GetWithIdentifier(obj,identifier)
            elLocs=obj.Location(obj.DefinitionIdentifier==identifier,:);
        end
        
        function AddWithIdentifier(obj,identifier,location)
            dim=size(location);
            if(dim(1)== 3 && dim(2)~= 3)
                location=location';
            end
           obj.DefinitionIdentifier(end+1:end+dim(1))=identifier*ones(dim(1),1);
           obj.Location(end+1:end+dim(1),:)=location;
           obj.Label(end+1:end+dim(1))={''};
        end

    end
   
end

