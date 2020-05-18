classdef ViewMap < handle
    %VIEWMAP Summary of this class goes here
    %   Detailed explanation goes here
    
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
            view=ObjectFactory.CreateView(type,xmlNode);
            if(any(strcmp(keys(obj.Views),view.Name)))
                error('View Names have to be unique!');
            end
            if(isObjectTypeOf(view,'IComponentView'))
                view.Pipeline=obj.Project.Pipeline;
            end
            obj.Views(view.Name)=view;
        end
        
        function [isCompV,comp]=IsComponentView(obj,compName)
            comp='';
            isCompV=false;
            if(isObjectTypeOf(obj.Views(compName),'IComponentView'))
                isCompV=true;
                comp=obj.Views(compName).Component;
            end
            
        end
        
        
        function UpdateViews(obj,data)
            for v=values(obj.Views)
                v{1}.AvailableData=data;
            end
        end
        

        
    end
end

