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
    
    properties(Access = protected)
        comp
    end
    
    methods
        function obj = IComponentView()
            obj.Component = '';
             addlistener(obj,'Pipeline','PostSet',@obj.componentChanged);
        end
        
        function SetComponent(obj,comp)
            obj.comp=comp;
            obj.componentChanged([],[]);
        end
        
        function comp=GetComponent(obj)
            %GetComponent - returns the Component associated with the View
            comp=[];
            if(~isempty(obj.Component))
                if(~isempty(obj.Pipeline))
                    comp=obj.Pipeline.GetComponent(obj.Component);
                end
            end
            if(~isempty(obj.comp))
                comp=obj.comp;
            else

            end
        end
    end
    methods (Abstract,Access = protected)
        
        componentChanged(obj,a,b);

    end
end

