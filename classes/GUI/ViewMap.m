classdef ViewMap < handle
    %ViewMap - Map for all Views in a Pipeline Definition
    %See also AView, Pipeline
    
    properties
        Views containers.Map
        Project Project
    end
    
    methods(Static)
         function vmap=LoadViewsFromPipelineFile(file,project)
            vmap=ViewMap(project);
            poss_p=xml2struct(file);
            if(isfield(poss_p,'PipelineDefinition') && ...
                numel(poss_p.PipelineDefinition) ==1)
                if(isfield(poss_p.PipelineDefinition{1},'View')) %check if views exist
                    for ip=1:length(poss_p.PipelineDefinition{1}.View)
                        comp=poss_p.PipelineDefinition{1}.View{ip};
                        if(isfield(comp,'Attributes') && isfield(comp.Attributes,'Type'))
                            vmap.AddView(comp.Attributes.Type,comp);
                        else
                            error('View definition is missing mandatory Type definition');
                        end
                    end
                end
                
            else
                error('Pipeline definition xml malformed');
            end
        end
    end
    
    methods
        function obj = ViewMap(proj)
            obj.Views = containers.Map();
            obj.Project=proj;
           
        end
        
        function AddView(obj,type,xmlNode)
            %AddView - Add a View to the Map
            %type - View type
            %xmlNode - xml configuration for this View
            view=ObjectFactory.CreateView(type,xmlNode);
            if(any(strcmp(keys(obj.Views),view.Name)))
                error('View Names have to be unique!');
            end
            if(isObjectTypeOf(view,'IComponentView'))
                view.Pipeline=obj.Project.Pipeline;
            end
            obj.Views(view.Name)=view;
        end
        
        function [isCompV,comp]=IsComponentView(obj,view)
            %IsComponentView - Check if the View as a ComponentView
            %view - name of the View
            %returns:
            %isCompV - true if the Component is a ComponentView
            %comp - returns the View
            %See also AView, IComponentView
            comp='';
            isCompV=false;
            if(isObjectTypeOf(obj.Views(view),'IComponentView') && ~isempty(obj.Views(view).Component))
                isCompV=true;
                comp=obj.Views(view).Component;
            end
            
        end
        
        
        function UpdateViews(obj,data)
            for v=values(obj.Views)
                v{1}.AvailableData=data;
            end
        end
        

        
    end
end

