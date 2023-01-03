classdef inflatablepatch < inflatableobject
    %UNTITLED Summary of this class goes here
    %   Detailed explanation goes here
    


    properties (Access = protected)
        hPatch
    end
    
    methods
        function obj = inflatablepatch(varargin)
            %inflatablepatch - Patchobject which can be moved between two
            %point clouds XYZ1 and XYZ2
            %   Usage:
            %   inflatablepatch(T,XYZ1,XYZ2,....)
            %   T - connectivity matrix
            %   XYZ1 - Pointcloud 1
            %   XYZ2 - Pointcloud 2  
            %   or
            %   inflatablepatch(inflatablepatchobj,T,XYZ1,XYZ2,....)
            %   inflatablepatchobj - binds the inflatablepatchobjs together
            %   T - connectivity matrix
            %   XYZ1 - Pointcloud 1
            %   XYZ2 - Pointcloud 2  
                sconstructorvars={};
                if(isa(varargin{1},'inflatableobject'))
                    sconstructorvars{1}=varargin{1};
                    sconstructorvars{2}=varargin{3};
                    sconstructorvars{3}=varargin{4};
                    start=5;
                    T=varargin{2};
                else
                    sconstructorvars{1}=varargin{2};
                    sconstructorvars{2}=varargin{3};
                    T=varargin{1};
                    start=4;
                end
                obj@inflatableobject(sconstructorvars{:});
                obj.hPatch=patch('faces',T,'vertices',obj.xyz1,varargin{start:end});
                obj.forwardNestProperties(obj.hPatch);
                obj.updateInflation();

            end
            
        end


    

    methods (Access = protected)
        function updateInflation(obj)
            obj.hPatch.Vertices=(obj.Inflation)*obj.xyz1 + (1-obj.Inflation)*obj.xyz2;
        end

    end
end

