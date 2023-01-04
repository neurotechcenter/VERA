classdef inflatabletext < inflatableobject
            %INFLATABLETEXT text which can be moved between two
            %point clouds
            %   Usage:
            %   inflatabletext(XYZ2,x,y,z,text,....)
            %   XYZ2 - Inflated coordinates in Nx3 matrix
            %   x, y, z - non inflated coordinates
            %   text - character array for text to be displayed
            %
            %   or
            %
            %   inflatabletext(inflatableobj,XYZ2,x,y,z,text,....)
            %   inflatableobj - binds the inflatableobjs together 
            %   XYZ2 - inflated coordinates as Nx3 matrix
            %   x, y, z - non inflated coordinates
            %   text - character array for text to be displayed
            %   or
            %
            %   inflatabletext(inflatableobj,x,y,z,text,....)
            %   inflatableobj - binds the inflatableobjs together - takes
            %   XYZ2 from closest points in linked object
            %   x, y, z - non inflated coordinates
            %   text - character array for text to be displayed
            %
            % See also text
    properties(SetAccess = protected)
        hText
    end
    
    methods
        function obj = inflatabletext(varargin)
            %INFLATABLETEXT text which can be moved between two
            %point clouds
            %   Usage:
            %   inflatabletext(XYZ2,x,y,z,text,....)
            %   XYZ2 - Inflated coordinates in Nx3 matrix
            %   x, y, z - non inflated coordinates
            %   text - character array for text to be displayed
            %
            %   or
            %
            %   inflatabletext(inflatableobj,XYZ2,x,y,z,text,....)
            %   inflatableobj - binds the inflatableobjs together 
            %   XYZ2 - inflated coordinates as Nx3 matrix
            %   x, y, z - non inflated coordinates
            %   text - character array for text to be displayed
            %   or
            %
            %   inflatabletext(inflatableobj,x,y,z,text,....)
            %   inflatableobj - binds the inflatableobjs together - takes
            %   XYZ2 from closest points in linked object
            %   x, y, z - non inflated coordinates
            %   text - character array for text to be displayed
            %
            % See also text
            if(isa(varargin{1},'inflatableobject'))
                sconstructorvars{1}=varargin{1};
                if(size(varargin{2},2) == 3)
                    xyz2=varargin{2};
                    xyz1=[varargin{3}(:) varargin{4}(:) varargin{5}(:)];
                    start=3;
                else
                    xyz1=[varargin{2}(:) varargin{3}(:) varargin{4}(:)];
                    [~,I]=minDistance(xyz1,varargin{1}.xyz1);
                    xyz2=varargin{1}.xyz2(I,:);
                    start=2;
                end
                sconstructorvars{2}=xyz1;
                sconstructorvars{3}=xyz2;
            else
                sconstructorvars{1}=[varargin{2}(:) varargin{3}(:) varargin{4}(:)];
                sconstructorvars{2}=varargin{1};
                if(size(sconstructorvars{1}) ~= size(sconstructorvars{2}))
                    error('xyz2 and x,y,z have to be same dimensionality');
                end
                start=4;
            end
            obj@inflatableobject(sconstructorvars{:});
            obj.hText=text(varargin{start:end});
            obj.forwardNestProperties(obj.hText);
            obj.updateInflation();
        
        end
        
            
    end

        methods (Access = protected)
            function updateInflation(obj)
                updatedLocs=(obj.Inflation)*obj.xyz1 + (1-obj.Inflation)*obj.xyz2;
                obj.hText.Position  = updatedLocs;

            end
        end
end

