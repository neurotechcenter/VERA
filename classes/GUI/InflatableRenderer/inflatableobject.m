classdef (Abstract)  inflatableobject < handle & dynamicprops
    %INFLATABLEOBJECT baseclass to visualize inflatable surface or scatter3
    %   
    
    properties(Dependent)
        Inflation % Value between 0 and 1
    end
    properties (GetAccess = public, SetAccess=private)
        xyz1
        xyz2
    end

    properties (Access = protected,SetObservable)
        inflation_ = 1
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
            else
                error('unknown Constructor call');
            end
            obj.subscribeToInflationParent(@(x,y)obj.updateInflation);
        end

        function set.Inflation(obj,val)
            if(~((val >= 0) && (val <= 1)))
               error('Inflation value has to be between 0 and 1');
            end
            obj.setInflationRecursive(val);
            
        end

        function val= get.Inflation(obj)
            val=obj.getInflationRecursive();
        end


    end

    methods(Access = protected)
        function subscribeToInflationParent(obj,func)
            %recursive function to find ancestor who holds the actual
            %inflation value
            if(isempty(obj.parent_))
                addlistener(obj,'inflation_','PostSet',func);
            else
                obj.parent_.subscribeToInflationParent(func);
            end
        end

        function infl=getInflationRecursive(obj)
            if(~isempty(obj.parent_))
                infl=obj.parent_.getInflationRecursive();
            else
                infl=obj.inflation_;
            end
        end

        function setInflationRecursive(obj,infl)
            if(~isempty(obj.parent_))
                obj.parent_.setInflationRecursive(infl);
            else
                obj.inflation_=infl;
            end
        end



        function forwardNestProperties(obj,nobj)
            allprops = properties(nobj);
            %forward all patch properties to inflatable patch class
            for i=1:numel(allprops)
                p = addprop(obj,allprops{i});
                p.SetMethod=@(x,y)set(nobj,allprops{i},y); 
                p.GetMethod=@(x)get(nobj,allprops{i}); 
            end
        end
    end



    methods(Access = protected,Abstract)
        updateInflation(obj);
    end
end

