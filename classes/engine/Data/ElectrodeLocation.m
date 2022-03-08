classdef ElectrodeLocation < PointSet
    %ElectrodeLocation Electrode Location in 3D Space 
    %
    
    properties
        DefinitionIdentifier %Identifier connecting the location to the Electrode Definiton
    end
    
    methods
        function obj = ElectrodeLocation()
            obj.DefinitionIdentifier=zeros(1,0,'uint32');
        end
        

        function RemoveWithIdentifier(obj, identifier)
            % RemoveWithIdentifier - Remove Locations based on the
            % Identifier
            obj.Location(obj.DefinitionIdentifier == identifier,:)=[];
            obj.DefinitionIdentifier(obj.DefinitionIdentifier == identifier)=[];
            obj.Label(obj.DefinitionIdentifier == identifier)=[];
        end

        function elLocs=GetWithIdentifier(obj,identifier)
            % GetWithIdentifier - Return all locations for a specific
            % Electrode Definition Identifier
            elLocs=obj.Location(obj.DefinitionIdentifier==identifier,:);
        end
        
        function AddWithIdentifier(obj,identifier,location)
            % AddWithIdentifier - Adds in new locations with a specific
            % identifier - Identifier to connect an electrode location to a
            % specific electrode definition
            % location - all locations corresponding to the identifier as
            % (n x3 ) vector
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

