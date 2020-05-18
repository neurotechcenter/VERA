classdef IComponentView < handle
    %ICOMPONENTVIEW Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        Component
    end
    
    properties (Access = ?ViewMap, SetObservable)
        Pipeline Pipeline
    end
    
    methods
        function obj = IComponentView()
            obj.Component = '';
             addlistener(obj,'Pipeline','PostSet',@obj.componentChanged);
        end
        
        function comp=GetComponent(obj)
            if(~isempty(obj.Pipeline))
                comp=obj.Pipeline.GetComponent(obj.Component);
            else
                error('No Pipeline associated with this View!');
            end
        end
    end
    methods (Access = protected)
        
        function componentChanged(obj,a,b)
        end

    end
end

