classdef IFileLoader < handle
    %IFILELOADER Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
    end
    
    methods (Abstract)
        LoadFromFile(obj,path);
    end
end

