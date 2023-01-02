classdef (Abstract)  inflatableobject < handle & dynamicprops
    %INFLATABLEOBJECT baseclass to visualize inflatable surface or scatter3
    %   
    
    properties(SetObservable, Dependent)
        Inflation % Value between 0 and 1
    end
    properties (GetAccess = public, SetAccess=private)
        xyz1
        xyz2
    end

    properties (Access = private)
        inflation_
        parent_ = []
    end

    
    methods

        function obj = inflatableobject(varargin)
            %INFLATABLEOBJECT Construct an instance of this class
            %   Creates a new inflatableobject which inflates from a point
            %   cloud xyz1 to xyz2
            
            if(nargin == 2)
                obj.xyz1 = varargin{1};
                obj.xyz2 = varargin{2};
                obj.parent_=[];
            elseif(nargin == 3 && isa(varargin{1},'inflatableobject')) 
                obj.xyz1 = varargin{2};
                obj.xyz2 = varargin{3};
                obj.parent_ = varargin{1};
                addlistener(obj.parent_,'Inflation','PostSet',@(x,y)obj.updateInflation);
            else
                error('unknown Constructor call');
            end
        end

        function set.Inflation(obj,val)
            if(~isempty(obj.parent_))
                obj.parent_.inflation_=val;
                obj.parent_.updateInflation();
            else
                if(~((val >= 0) && (val <= 1)))
                    error('Inflation value has to be between 0 and 1');
                end
                obj.inflation_=val;
            end
            obj.updateInflation();
        end

        function val= get.Inflation(obj)
            if(~isempty(obj.parent_))
                val=obj.parent_.inflation_;
            else
                val=obj.inflation_;
            end
        end


    end



    methods(Access = protected,Abstract)
        updateInflation(obj);
    end
end

