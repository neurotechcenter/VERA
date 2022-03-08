classdef PathInformation < AData
    %PathInformation Data object to share paths between components
    
    properties
        Path
    end
    
    methods
        function obj = PathInformation()
            obj.Path='';
        end
    end
end

