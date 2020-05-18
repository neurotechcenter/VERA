classdef AComponent < Serializable
    %ACOMPONENT Summary of this class goes here
    %   Detailed explanation goes here
    properties
        Name
        ComponentPath
    end
    properties (SetAccess = ?Pipeline)
        Inputs {};
        Outputs {};
        OptionalInputs {};
    end
    
    properties (SetAccess = {?Runner,?Serializable})
        ComponentStatus
    end
    
    properties (SetAccess = ?Pipeline, GetAccess = ?Pipeline)
        inputMap
        optionalinputMap
        outputMap
        Pipeline Pipeline
    end
    methods
        function obj = AComponent()
            obj.Inputs = {};
            obj.Outputs = {};
            obj.OptionalInputs = {};
            obj.inputMap = containers.Map;
            obj.outputMap = containers.Map;
            obj.Name=class(obj);
            obj.nodeName='Component';
            obj.ignoreList{end+1}='ComponentPath';
            obj.acStorage{end+1}='ComponentStatus'; %save component status
            obj.ComponentStatus='Invalid';
        end
        
        function type=GetOutputType(obj,outName)
            type=obj.outputMap(outName);
        end
        function type=GetInputType(obj,inName)
            type=obj.inputMap(inName);
        end 
    end
    
    
    methods(Abstract)

        Publish(obj);
        Initialize(obj);
        varargout = Process(varagin);
        
            
    end
    
    methods(Access = protected)
        function d=GetDependency(~,name)
            d=DependencyHandler.Instance.GetDependency(name);
        end
        
        function RequestDependency(~,name,type)
            DependencyHandler.Instance.PostDepencenyRequest(name,type);
        end
        
        function AddOptionalInput(obj,Identifier,inpDataTypeName)
            if(isempty(obj.Pipeline))
                error('Component has to be part of a Pipeline, Pipeline is only available during Publish phase');
            end
            obj.Pipeline.AddOptionalInput(obj,Identifier,inpDataTypeName);
        end
        
        function AddInput(obj,Identifier,inpDataTypeName)
            if(isempty(obj.Pipeline))
                error('Component has to be part of a Pipeline, Pipeline is only available during Publish phase');
            end
            
            obj.Pipeline.AddInput(obj,Identifier,inpDataTypeName);

        end
        
        function AddOutput(obj,Identifier,outpDataTypeName)
            if(isempty(obj.Pipeline))
                error('Component has to be part of a Pipeline, Pipeline is only available during Publish phase');
            end
            
            obj.Pipeline.AddOutput(obj,Identifier,outpDataTypeName);
        end
        
        function cData=CreateOutput(obj,Identifier)
            if(obj.outputMap.isKey(Identifier))
                cData=ObjectFactory.CreateData(obj.outputMap(Identifier));
                cData.Name=Identifier;
            else
                error('Requested Output is not part of this Component, All Outputs have to be defined during the Publish phase');
            end
        end
    end
end


