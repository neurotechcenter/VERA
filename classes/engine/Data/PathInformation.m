classdef PathInformation < AData
    %PathInformation Data object to share paths between components
    
    properties
        Path % path information
    end
    
    methods
        function obj = PathInformation()
            % PathInformation - Constructor
            obj.Path='';
        end

        function obj = set.Path(obj,value)
            obj.Path=obj.normalizeSlashes(value);
        end

        function path = get.Path(obj)
            path=obj.normalizeSlashes(obj.Path);
        end
    end

end

