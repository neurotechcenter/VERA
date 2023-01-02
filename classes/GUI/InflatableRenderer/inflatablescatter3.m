classdef inflatablescatter3 < inflatableobject
    %INFLATABLESCATTER3 Creates a scatter object which can be morphed between two
    %   point clouds
    

    properties (SetAccess = protected)
        hScatter
    end
    
    methods
        function obj = inflatablescatter3(varargin)
            %   inflatablescatter3 Creates a new scatter3 plot with the
            %   ability to morph between two point clouds
            % Call as:
            %   inflatablescatter3(xyz2,x,y,z,...)
            %   xyz2 - Nx3 matrix of the point cloud which will be morphed
            %   x,y,z ... Nx1 matrix of points
            %
            %   or
            %   inflatablescatter3(o,x,y,z,...)
            %   o - inflatable object to which scatter 3 will be linked
            %   x,y,z - x,y,z coordinate of the scatter data, for morphing
            %   closest point in xyz1 of o will be used to determine
            %   morphing trajectory
            % See also scatter3
            if(isa(varargin{1},'inflatableobject'))
                sconstructorvars{1}=varargin{1};
                xyz1=[varargin{2}(:) varargin{3}(:) varargin{4}(:)];
                sconstructorvars{2}=xyz1;
                [~,I]=minDistance(xyz1,varargin{1}.xyz1);
                sconstructorvars{3}=varargin{1}.xyz2(I,:);
                start=2;
            else
                sconstructorvars{1}=[varargin{2}(:) varargin{3}(:) varargin{4}(:)];
                sconstructorvars{2}=varargin{1};
                if(size(sconstructorvars{1}) ~= size(sconstructorvars{2}))
                    error('xyz2 and x,y,z have to be same dimensionality');
                end
                start=4;
            end
            obj@inflatableobject(sconstructorvars{:});
            
            obj.hScatter=scatter3(varargin{start:end});

            allprops = properties(obj.hScatter);
            %forward all patch properties to inflatable patch class
            for i=1:numel(allprops)
                p = addprop(obj,allprops{i});
                p.SetMethod=@(x,y)set(obj.hPatch,allprops{i},y); 
                p.GetMethod=@(x)get(obj.hScatter,allprops{i}); 
            end
        end
    end

        methods (Access = protected)
            function updateInflation(obj)
                updatedLocs=(obj.Inflation)*obj.xyz1 + (1-obj.Inflation)*obj.xyz2;
                obj.hScatter.XData  = updatedLocs(:,1);
                obj.hScatter.YData  = updatedLocs(:,2);
                obj.hScatter.ZData  = updatedLocs(:,3);
            end
        end
end

