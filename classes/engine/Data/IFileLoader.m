classdef IFileLoader < handle
    %IFileLoader Interface allows it to be used together with the
    %FileLoader Component
    %See also FileLoader
    
    properties
    end
    
    methods (Abstract)
        LoadFromFile(obj,path);
    end
end

