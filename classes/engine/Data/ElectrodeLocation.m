classdef ElectrodeLocation < PointSet
    %ElectrodeLocation Electrode Location in 3D Space
    % See also PointSet
    
    properties
        DefinitionIdentifier %Identifier connecting the location to the Electrode Definiton
    end
    
    methods
        function obj = ElectrodeLocation()
            obj.DefinitionIdentifier=zeros(1,0,'uint32');
        end

        function electrodeNames= GetElectrodeNames(obj,eDef)
            %GetElectrodeNames - returns the names of the electrodes based
            %on provided electrode Definition
            % eDef - ElectrodeDefiniton object
            % see also ElectrodeDefinition
            if(~isObjectTypeOf(eDef,'ElectrodeDefinition'))
                error("Input is expected to be of type ElectrodeDefinition");
            end
            electrodeNames=cell(size(obj.DefinitionIdentifier,1),1);
            idx=1;
            order=unique(obj.DefinitionIdentifier,'stable');
            for i=1:length(order)
                for ii=1:eDef.Definition(order(i)).NElectrodes
                    electrodeNames{idx}=[eDef.Definition(order(i)).Name num2str(ii)];
                    idx=idx+1;
                end
            end
        end
        

        function RemoveWithIdentifier(obj, identifier)
            % RemoveWithIdentifier - Remove Locations based on the
            % Identifier
            obj.Location(obj.DefinitionIdentifier == identifier,:)=[];
            obj.DefinitionIdentifier(obj.DefinitionIdentifier == identifier)=[];
            obj.Label(obj.DefinitionIdentifier == identifier)=[];
            obj.DeleteAnnotations(find(obj.DefinitionIdentifier == identifier));
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

