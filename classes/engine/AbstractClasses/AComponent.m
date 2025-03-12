classdef (Abstract) AComponent < Serializable
    %ACOMPONENT Abstract Baseclass for all Components
    %   A Component is an executable part of a Pipeline
    %   Each Component defines the inputs and outputs it requires. For
    %   exmaple, a component which coregisters a CT and an MRI will need a
    %   CT and MRI as input. The component can only be executed if the data
    %   is available.
    %   To add a Component to a Pipeline it has to be added to the Pipeline
    %   workflow file (pwf). These files are simple xml files.
    %
    %   Example:
    %   Adding a Component to the Pipline. The Component Class is called
    %   TestComponent:
    %
    %   <Component Type="TestComponent">
    %   </Component>
    %
    %   All public properties can be configured in the pipeline definiton
    %   file. This allows to modify Components for the use within a
    %   pipeline. 
    %   Example: Set the Name Property in the TestComponent to Test 
    %
    %   <Component Type="TestComponent">
    %       <Name>"Test"</Name>
    %   </Component>
    %
    %   For more complex datatypes the Element value is formatted as json.
    %
    %   Markus Adamek (adamek@neurotechcenter.org)
    %   See also jsonencode

    
    
    properties
        Name   % Unique Identifier of the Component within the Pipeline, if empty will be set to class name
        ComponentPath % The Path in which the component information is stored
    end
    properties (SetAccess = ?Pipeline)
        Inputs {};  % List of required inputs
        Outputs {}; % List of generated outputs
        OptionalInputs {};  % Inputs that are not necessary but will be used if available. A Component can be executed even if the optional inputs aren't available
    end
    
    properties (SetAccess = {?Runner,?Serializable})
        ComponentStatus %Current Component stauts. This status determines if the component can be executed. 
    end
    
    properties (SetAccess = ?Pipeline, GetAccess = public)
        inputMap 
        optionalinputMap 
        outputMap
        Pipeline Pipeline
    end
    methods
        function obj = AComponent()
            % AComponent Constructor
            % Initialize all relevant properties and configure the
            % serialization properly
            obj.Inputs = {};
            obj.Outputs = {};
            obj.OptionalInputs = {};
            obj.inputMap = containers.Map;
            obj.outputMap = containers.Map;
            obj.optionalinputMap = containers.Map;
            obj.Name=class(obj);
            obj.nodeName='Component';
            obj.ignoreList{end+1}='ComponentPath';
            obj.acStorage{end+1}='ComponentStatus'; %save component status
            obj.ComponentStatus='Invalid';
        end
        
        function type=GetOutputType(obj,outName)
            % GetOutputType returns the datatype (subclass of AData)
            % Returns the specific output identifier
            % See also AData, ElectrodeDefinition, ElectrodeLocation,
            % IFileLoader, Surface, Volume
            type=obj.outputMap(outName);
        end
        function type=GetInputType(obj,inName)
            % Retuns the datatype for a specified identifier
            % See also AData, ElectrodeDefinition, ElectrodeLocation,
            % IFileLoader, Surface, Volume
            type=obj.inputMap(inName);
        end 
    end
    
    
    methods(Abstract)
        % Publish - Method called when the object is added to the Pipeline
        % This method is used to specify the inputs and outputs of the
        % component as well as dependencies to external tools
        % See also AComponent.AddInput, AComponent.AddOptionalInput,
        % AComponent.AddOutput, AComponent.RequestDependency
        Publish(obj);
        % Initialize - Has to be called at least once before Process()
        % This method can be used to validate configurations and
        % Dependencies before a component runs process
        %See also AComponent.Process, AComponent.RequestDependency
        Initialize(obj);
        % Process - runs the main task of the component
        % varagin - Contains inputs defined in the publish section in order
        % of definition. Optional inputs are added afterwards. Every
        % optional input is preceded by argument naming the optional input
        % varargout - Has to be equal to the number of specified Outputs in
        % the Publish section. The output arguments have to be in the same
        % order as they were specified in the Publish section
        % See also Publish, AddInput, AddOutput, CreateOutput
        varargout = Process(varagin);
        
     %   helptext=Documentation(obj);
        
            
    end
    
    methods(Access = protected)

        function deSerializationDone(obj,~)
            if(contains(obj.Name,{'/','\','*',',',':',';'}))
                error('A Component name cannot contain any of the following characters: \ / , : ; * ');
            end
        end
        
        function path=GetTempPath(obj)
            % GetTempPath - returns the Temp Path defined in the
            % Dependencies
            path=obj.GetDependency('TempPath');
        end

        function d=GetDependency(~,name)
            % GetDependency - Tries to resolve and return a Dependency
            % See also DependencyHandler
            d=DependencyHandler.Instance.GetDependency(name);
        end

        function d=GetOptionalDependency(~,name)
            % GetOptionalDependency - Tries to resolve and return a Dependency
            % See also DependencyHandler
            % This exists to make it easier to search through GetDependency calls
            d=DependencyHandler.Instance.GetDependency(name);
        end
        
        function RequestDependency(~,name,type)
            % RequestDependency - Request a dependency to be resolved
            % If a Dependency does not exist, it can be created with this
            % method
            % name - Identifier for the dependency
            % type - Type of the dependency (Folder, File ...)
            % See also DependencyHandler
            DependencyHandler.Instance.PostDepencenyRequest(name,type);
        end
        
        function AddOptionalInput(obj,Identifier,inpDataTypeName,mustUseIfAvailable)
            % AddOptionalInput add an optional input to this component
            % In the Publish method, optional inputs can be defined
            % If the input exists it will be added as an argument to the
            % process method
            % Identifier - Name associated with the data, created as an
            % output by another component
            % inpDataTypeName - Name of the data type - has to be a subtype
            % of AData
            % mustUseIfAvailable - Decide wether the input must be used if
            % it is avialable
            % See also AComponent.Publish, AComponent.Process, AData,
            % ElectrodeDefinition, IFileLoader, Surface, Volume
            if(isempty(obj.Pipeline))
                error('Component has to be part of a Pipeline, Pipeline is only available during Publish phase');
            end
            if(nargin < 4)
                mustUseIfAvailable=false;
            end
            obj.Pipeline.AddOptionalInput(obj,Identifier,inpDataTypeName,mustUseIfAvailable);
        end
        
        function AddInput(obj,Identifier,inpDataTypeName)
            % AddInput add an input to this component
            % In the Publish method, inputs can be defined
            % Inputs need to be available for the process method to be
            % called
            % Identifier - Name associated with the data, created as an
            % output by another component
            % inpDataTypeName - Name of the data type - has to be a subtype
            % of AData
            % See also AComponent.Publish, AComponent.Process, AData,
            % ElectrodeDefinition, IFileLoader, Surface, Volume
            if(isempty(obj.Pipeline))
                error('Component has to be part of a Pipeline, Pipeline is only available during Publish phase');
            end
            obj.Pipeline.AddInput(obj,Identifier,inpDataTypeName);

        end
        
        function AddOutput(obj,Identifier,outpDataTypeName)
            % AddOutput add an output to this component
            % In the Publish method, outputs can be defined
            % Outputs can be used as Inputs for other components
            % Identifier - Name associated with the data, can be retrieved
            % by other components
            % outpDataTypeName - Name of the data type - has to be a subtype
            % of AData
            % See also AComponent.Publish, AComponent.Process, AData,
            % ElectrodeDefinition, IFileLoader, Surface, Volume
            if(isempty(obj.Pipeline))
                error('Component has to be part of a Pipeline, Pipeline is only available during Publish phase');
            end
            
            obj.Pipeline.AddOutput(obj,Identifier,outpDataTypeName);
        end
        
        function cData=CreateOutput(obj,Identifier,template)
            % CreateOutput - Creates an Output object from the Identifier
            % type name
            % Use in the Process method to create a new output object
            % See also AComponent.Process, AData, ElectrodeDefinition, IFileLoader, Surface, Volume
            if(obj.outputMap.isKey(Identifier))
                if(exist('template','var')) %copy from template
                    cData=copy(template);
                else
                    cData=ObjectFactory.CreateData(obj.outputMap(Identifier));
                end
                cData.Name=Identifier;
            else
                error('Requested Output is not part of this Component, All Outputs have to be defined during the Publish phase');
            end
        end

        function VERAMessageBox(obj,message,msgBoxSize)
            monitorPositions = get(0, 'MonitorPositions');
            mainMonitor = monitorPositions(1, :);

            % Extract width and height of the primary monitor
            mainMonitorWidth  = mainMonitor(3);
            mainMonitorHeight = mainMonitor(4);
            
            % Calculate the center of the primary monitor
            centerX = mainMonitor(1) + mainMonitorWidth / 2;
            centerY = mainMonitor(2) + mainMonitorHeight / 2;

            boxFig    = uifigure('Name',obj.Name,'Position',[centerX-msgBoxSize(1)/2 centerY-msgBoxSize(2)/2 msgBoxSize]);

            % Create a label for the message
            uilabel(boxFig, ...
                'Text',                message, ...
                'Position',            [10, 10, msgBoxSize(1)-10, msgBoxSize(2)], ... % [left, bottom, width, height]
                'WordWrap',            'on', ...
                'HorizontalAlignment', 'center', ...
                'FontSize',            12);
        
            % Create an OK button that closes the dialog
            uibutton(boxFig,'Text','OK','Position',[(msgBoxSize(1)-100)/2, 10, 100 30], ...
                'ButtonPushedFcn',@(btn, event) close(boxFig));
        end
    end
end


