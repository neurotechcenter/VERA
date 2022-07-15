classdef Pipeline < handle
    %Pipeline - Defines the Components in a Project
    %   The pipeline ensures that a Component can only be added if previous
    %   components provide the necessary Data
    
    properties (SetAccess = protected)
        Components  {} % List of components
        %Dependency Graph of the components
        %   The Dependency Graph can be used to determine the best order
        %   in which Components should be executed
        %See also digraph
        DependencyGraph 
        
    end
    
    properties(Access = private)
        availableData  containers.Map %Data theoretically available after the last component
        componentMap  containers.Map  %Map of Components See also, containers.Map
        localOutputList = containers.Map(); 
        availableDataPerStage {} %Data seperatly for each Container in order of appearance
    end
    
    methods(Static)
       function pipeline=CreateFromPipelineDefinition(pipePath)
           %CreateFromPipelineDefinition - Create A Pipeline object from a Pipeline definition file 
           pipeline=Pipeline();
            poss_p=xml2struct(pipePath);
            if(isfield(poss_p,'PipelineDefinition') && ...
                numel(poss_p.PipelineDefinition) ==1 && ...
                isfield(poss_p.PipelineDefinition{1},'Component'))
            
                for ip=1:length(poss_p.PipelineDefinition{1}.Component)
                    comp=poss_p.PipelineDefinition{1}.Component{ip};
                    if(isfield(comp,'Attributes') && isfield(comp.Attributes,'Type'))
                        pipeline.AddComponent(comp.Attributes.Type,comp);
                    else
                        error('Component Definition is missing mandatory Type definition');
                    end
                end
                
                
            else
                error('Pipeline definition xml malformed');
            end
       end
        
    end
    
    methods
        function obj = Pipeline(obj)
            obj.Components = {};
            obj.componentMap = containers.Map();
            obj.availableData = containers.Map();
            obj.localOutputList =containers.Map();
            obj.DependencyGraph = digraph();
            obj.availableDataPerStage={};
        end

        function compName=FindUpstreamData(obj,downstreamCompName,dataName)
            %FindUpstreamData = find the fist upstream (i.e, component
            %earlier in the pipeline) relative to downstreamCompName that
            %produces data with the ID dataName
            obj.availableDataPerStage;
            
            compIdx=find(cellfun(@(x)strcmp(x,downstreamCompName),obj.Components));
            compIdx=find(cellfun(@(x) any(strcmp(dataName,obj.componentMap(x).Outputs)),obj.Components(1:compIdx)),1,'last');
            compName=obj.Components{compIdx};  
        end
        
        function execSequence=GetProcessingSequence(obj,compName)
            %GetProcessingSequence - Returns the required processing
            %sequence to successfully execute a specific component
            % compName - name of the component which should be executed
            % execSequence - Sequence of components that needs to be
            % executed excluding compName
            [~,execSequence]=inedges(obj.DependencyGraph,compName);
            
        end
        
        function processComp=GetProcessingComponentNames(obj)
            %GetProcessingComponentNames - Returns the names of all
            %Processing Components
            % Processing Components are defined as those which need Input
            % Data objects and produce output Data objects
            processComp={};
            for k=obj.Components
                if((numel(obj.GetComponent(k{1}).Inputs) ~= 0) && (numel(obj.GetComponent(k{1}).Outputs) ~= 0))
                    processComp{end+1}=k{1};
                end
            end
        end
        
        function inpComp=GetInputComponentNames(obj)
            %GetInputComponentNames - Returns the name of the Components
            %defined as Inputs
            %Input components are defined as those not requiring any input
            %data
             inpComp={};
            for k=obj.Components
                if(numel(obj.GetComponent(k{1}).Inputs) == 0)
                    inpComp{end+1}=k{1};
                end
            end
        end
        
        function outComp=GetOutputComponentNames(obj)
            %GetOutputComponentNames - Returns the name of Components
            %defined as output
            %An output component is defined as a Component that does not
            %have any output Data
             outComp={};
            for k=obj.Components
                if(numel(obj.GetComponent(k{1}).Outputs) == 0)
                    outComp{end+1}=k{1};
                end
            end
        end
        
        function [inputs, outputs, optInputs]=InterfaceInformation(obj,compName)
            % InterfaceInformation - Returns Inputs, Outputs and optional
            % Inputs for a specific component
            % compName: Name of the Component
            outputs=obj.GetComponent(compName).Outputs;
            inputs=obj.GetComponent(compName).Inputs;
            optInputs=obj.GetComponent(compName).OptionalInputs;
        end
        
        function c=GetComponent(obj,compName)
            %GetComponent - returns the Component Object
            if(obj.componentMap.isKey(compName))
                c=obj.componentMap(compName);
            else
                error(['Component ' compName ' not found in Pipeline']);
            end
        end
        
        function graph=GetDependencyGraph(obj)
            %GetDependencyGraph - returns the DependencyGraph for the
            %current Pipeline
            % see also digraph
            graph=obj.DependencyGraph;
        end
        
        function AddComponent(obj,compName,compXml)
            %AddComponent - Adds a component to the Pipeline, if compXml is
            %not empty the component will be set accordingly
            c=ObjectFactory.CreateComponent(compName,compXml);
            c.Pipeline=obj;
            try
                obj.localOutputList =containers.Map();
                c.Publish();
                names=keys(obj.componentMap);
                if(~isempty(obj.componentMap) && ...
                        any(strcmp(names,c.Name)))
                    %c.Name=createUniqueName(c.Name,names);
                    error(['Duplicate of Component with Name ' c.Name  ' found. Component names have to be unique']);
                   % warning('Component names have to be unique!');
                end
                obj.componentMap(c.Name)=c;
                obj.Components{end+1}=c.Name;
                
                kNames=keys(obj.localOutputList);
                if(numel(obj.availableDataPerStage) < 1)
                    obj.availableDataPerStage{end+1}=kNames;
                else
                    obj.availableDataPerStage{end+1}=unique([obj.availableDataPerStage{end} kNames]);
                end
                for k=kNames
                    obj.availableData(k{1})=obj.localOutputList(k{1});
                end
                obj.updateDependencyGraph();
            catch e
                c.Pipeline=[];
                rethrow(e);
            end
            c.Pipeline=[];
        end
    end
    
    methods(Access = protected)
        
            function updateDependencyGraph(obj)
                %updateDependencyGraph - recalculates the DependencyGraphs
            s={};
            t={};
            w={};
            compKeys=obj.Components;
            for c=1:length(compKeys)
                outp=obj.componentMap(compKeys{c}).Outputs;
                for io=1:length(outp)
                    for cp=c+1:length(obj.Components) %search if it is input for any other component
                        outcp=obj.componentMap(compKeys{cp}).Outputs;
                        inpcp=[obj.componentMap(compKeys{cp}).Inputs obj.componentMap(compKeys{cp}).OptionalInputs];
                       
                        if(any(strcmp(inpcp,outp{io})))
                            s{end+1}=compKeys{c};
                            t{end+1}=compKeys{cp};
                            w{end+1}=outp{io};
                        end
                        if(any(strcmp(outcp,outp{io}))) %break if the output of component is current output
                            break;
                        end
                    end
                end
            end
            widx=unique(w);
            w_idx=zeros(size(w));
            for i=1:length(w)
                w_idx(i)=find(strcmp(widx,w(i)));
            end
            g = digraph(s,t,w_idx);
            if(~isempty(g.Edges))
                tmp=widx(g.Edges.Weight);
                g.Edges.Name=tmp(:); 
            end
            obj.DependencyGraph=g;
        end
    end
    
    methods(Access = ?AComponent)
        function AddInput(obj,cobj,Identifier,inpType)
            %AddInput - Adds input for the current component to the
            %pipeline
            %   This method can only be called by a Component
            %   See also AComponent
            if(obj.availableData.isKey(Identifier) ...
                && isObjectTypeOf(inpType,'AData') ...
                && strcmp(obj.availableData(Identifier),inpType))
                cobj.Inputs{end+1}=Identifier;
                cobj.inputMap(Identifier)=inpType;
            else
                error(['Requested Input: ' Identifier ' is not available for Component ' class(cobj) ' or ' inpType ' not a Subclass of AData, or the available Data is not from the same type']);
            end
        end
        
        function AddOptionalInput(obj,cobj,Identifier,inpType, mustUseIfAvailable)
            %AddOptionalInput - Adds an optional input for the current component to the
            %pipeline
            %   This method can only be called by a Component
            %   See also AComponent
            

            if(obj.availableData.isKey(Identifier) ...
                && isObjectTypeOf(inpType,'AData') ...
                && strcmp(obj.availableData(Identifier),inpType))
                if(mustUseIfAvailable)
                    cobj.Inputs{end+1}=Identifier;
                    cobj.inputMap(Identifier)=inpType;
                else
                    cobj.OptionalInputs{end+1}=Identifier;
                    cobj.optionalinputMap(Identifier)=inpType;
                end
            end
        end
        
        function AddOutput(obj,cobj,Identifier,outputType)
            %AddOutput - Adds an output for the current component to the
            %pipeline
            %   This method can only be called by a Component
            %   See also AComponent
            if(isObjectTypeOf(outputType,'AData')) %check if class exists
                cobj.Outputs{end+1}=Identifier;
                cobj.outputMap(Identifier)=outputType;
                obj.localOutputList(Identifier)=outputType;
            end
        end
    end
end

