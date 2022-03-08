classdef TransformationMatrix < AData
%TransformationMatrix - Data object for 4x4 transformation matrices

    
    properties
        T
    end
    
    methods
        function obj = TransformationMatrix()
            T=NaN(4,4,1);
        end
        
    end
end

