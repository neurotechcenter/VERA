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


    end
end

