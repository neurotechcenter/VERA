classdef IFileLoader < handle
    %IFileLoader Interface allows it to be used together with the
    %FileLoader Component
    %See also FileLoader
    
    properties
    end
    
    methods (Abstract)
        LoadFromFile(obj,path);
        %LoadFrom File - path to file which should be loaded through
        %interface
    end
end

