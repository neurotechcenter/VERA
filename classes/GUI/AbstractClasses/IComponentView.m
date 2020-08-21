classdef IComponentView < handle
    %IComponentView - Interface for Views which are tied to a Component
    % Views associated with a Component are only visible if the Component
    % is selected
    %See also handle, IComponent
    
    properties
        Component %Name/Identifier of the Component associated with the View
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
            %GetComponent - returns the Component associated with the View
            if(~isempty(obj.Pipeline))
                comp=obj.Pipeline.GetComponent(obj.Component);
            else
                error('No Pipeline associated with this View!');
            end
        end
    end
    methods (Access = protected)
        
        function componentChanged(obj,a,b)
            %componentChanged - Method is called whenever Components change
        end

    end
end

