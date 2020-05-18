classdef LoadPipelineData < AComponent
    %LOADPIPELINEDATA Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        Identifier
        Type
    end
    
    methods
        function obj = LoadPipelineData()
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
        end
        
        function [out] = Process(obj)
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

