classdef PointSet < AData
    %LOCATION Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        Location
    end
    
    methods
        function obj = PointSet()
            obj.Location=zeros(0,3);
        end

    end
end

