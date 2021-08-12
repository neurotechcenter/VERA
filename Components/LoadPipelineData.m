classdef LoadPipelineData < AComponent
    %LoadPipelineData load a Data object from another VERA project
    
    properties
        Identifier %Data identifier
        Type %Data type - See also AData
    end
    
    methods
        function obj = LoadPipelineData()
            %LoadPipelineData - Constructor
            obj.Identifier='';
            obj.Type='';
        end
        
        function Publish(obj)
            if(isempty(obj.Identifier) || isempty(obj.Type))
                error(['Cannot Publish ' obj.Name ' Identifier and Type has to be configured in the pipeline']);
            end
            obj.AddOutput(obj.Identifier,obj.Type);
        end
        
        function Initialize(obj)
            % Initialize
            %See also AComponent.Initialize
        end
        
        function [out] = Process(obj)
            % Process - opens a file selector to select the Data xml
            % out - Data object
            [file,path]=uigetfile('*.xml',['Please Select ' obj.Identifier]);
            if isequal(file,0)
                error('No file selected');
            else
                out=obj.CreateOutput(obj.Identifier);
                out.Load(fullfile(path,file));
            end

        end
    end
end

