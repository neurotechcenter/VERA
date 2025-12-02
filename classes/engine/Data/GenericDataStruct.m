classdef GenericDataStruct < AData
    %GenericDataStruct - Data object for generic data structures
    %
    % Properties:
    %   DataStruct

    % see also AData

    properties
        DataStruct 
    end

    methods
        function obj = GenericDataStruct()
            %GenericDataStruct Constructor
            obj.DataStruct=struct();
        end
    end
end