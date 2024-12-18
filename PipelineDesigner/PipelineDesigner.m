function PipelineDesigner()
    % Create the main figure for the GUI
    fig = uifigure('Position', [100, 100, 1400, 800], 'Name', 'Pipeline Designer');
    
    %% Create the TextArea for writing pipeline code
    uilabel(fig, ...
        'Position', [20, 730, 300, 20], ...
        'Text','Pipeline','FontName', 'Courier New', 'FontSize', 12);
    
    pipelineTextArea = uitextarea(fig, ...
        'Position', [20, 20, 560, 710], ...
        'Value','', 'FontName', 'Courier New', 'FontSize', 12, 'Editable', 'on');
    
    
    %% Listbox of Input components
    uilabel(fig, ...
        'Position', [590, 730, 300, 20], ...
        'Text','Input Components','FontName', 'Courier New', 'FontSize', 12);
    
    availableInputComponentsListBox = uilistbox(fig, ...
        'Position', [590, 605, 390, 125], ...
        'Items',{''}, 'FontName', 'Courier New', 'FontSize', 12);

    %% Listbox of Processing components
    uilabel(fig, ...
        'Position', [590, 580, 300, 20], ...
        'Text','Processing Components','FontName', 'Courier New', 'FontSize', 12);

    availableProcessingComponentsListBox = uilistbox(fig, ...
        'Position', [590, 455, 390, 125], ...
        'Items',{''}, 'FontName', 'Courier New', 'FontSize', 12);

    %% Listbox of Output components
    uilabel(fig, ...
        'Position', [590, 430, 300, 20], ...
        'Text','Output Components','FontName', 'Courier New', 'FontSize', 12);

    availableOutputComponentsListBox = uilistbox(fig, ...
        'Position', [590, 305, 390, 125], ...
        'Items',{''}, 'FontName', 'Courier New', 'FontSize', 12);
    
    %% Create the TextArea for modifying component code
    uilabel(fig, ...
        'Position', [590, 280, 300, 20], ...
        'Text','Current Component','FontName', 'Courier New', 'FontSize', 12);

    componentTextArea = uitextarea(fig, ...
        'Position', [590, 20, 390, 260], ...
        'Value','', 'FontName', 'Courier New', 'FontSize', 12, 'Editable', 'on');
    
    
    %% Listbox of possible views
    uilabel(fig, ...
        'Position', [990, 730, 300, 20], ...
        'Text','Available Views','FontName', 'Courier New', 'FontSize', 12);
    
    availableViewsListBox = uilistbox(fig, ...
        'Position', [990, 305, 390, 425], ...
        'Items',{''}, 'FontName', 'Courier New', 'FontSize', 12);
    
    %% Create the TextArea for modifying view code
    uilabel(fig, ...
        'Position', [990, 280, 300, 20], ...
        'Text','Current View','FontName', 'Courier New', 'FontSize', 12);

    viewTextArea = uitextarea(fig, ...
        'Position', [990, 20, 390, 260], ...
        'Value','', 'FontName', 'Courier New', 'FontSize', 12, 'Editable', 'on');
    
    
    %% Create a Load button to load a pipeline from a file
    uibutton(fig, 'push', 'Text', 'Load Pipeline', ...
        'Position', [20, 755, 100, 30], 'ButtonPushedFcn', @(btn, event) loadPipeline(pipelineTextArea));
    
    %% Create a Save button to save the pipeline to a file
    uibutton(fig, 'push', 'Text', 'Save Pipeline', ...
        'Position', [140, 755, 100, 30], 'ButtonPushedFcn', @(btn, event) savePipeline(pipelineTextArea));
    

    %% On startup, display demo pipeline
    path_to_demo = GetFullPath(fullfile(mfilename('fullpath'),'..','..','PipelineDefinitions','SimpleTutorialPipeline.pwf'));
    loadPipeline(pipelineTextArea,path_to_demo);
    

    %% Get all components
    componentParentClasses = {'AComponent'};
    componentPath = GetFullPath(fullfile(mfilename('fullpath'),'..','..','Components'));
    [AvailableComponents, componentTypes] = getAvailableElements(componentPath, componentParentClasses, 'component');
    
    %% Populate list of possible Input components
    inputIDXs = contains(componentTypes,'Input');
    
    availableInputComponentsListBox.Items = AvailableComponents(inputIDXs);
    
    % Update view window to display current component
    availableInputComponentsListBox.ValueChangedFcn = @(src,event) viewComponent(componentTextArea, componentParentClasses, availableInputComponentsListBox.Value);
    

    %% Populate list of possible Processing components
    processingIDXs = contains(componentTypes,'Processing');
    
    availableProcessingComponentsListBox.Items = AvailableComponents(processingIDXs);
    
    % Update view window to display current component
    availableProcessingComponentsListBox.ValueChangedFcn = @(src,event) viewComponent(componentTextArea, componentParentClasses, availableProcessingComponentsListBox.Value);
    

    %% Populate list of possible Output components
    outputIDXs = contains(componentTypes,'Output');
    
    availableOutputComponentsListBox.Items = AvailableComponents(outputIDXs);
    
    % Update view window to display current component
    availableOutputComponentsListBox.ValueChangedFcn = @(src,event) viewComponent(componentTextArea, componentParentClasses, availableOutputComponentsListBox.Value);
    

    %% Populate list of possible views
    viewParentClasses = {'uix.Grid','AView','IComponentView'};
    viewPath = GetFullPath(fullfile(mfilename('fullpath'),'..','..','classes','GUI','Views'));
    [availableViewsListBox.Items] = getAvailableElements(viewPath, viewParentClasses, 'view');
    
    % Update view window to display current view
    availableViewsListBox.ValueChangedFcn = @(src,event) viewView(viewTextArea, viewParentClasses, availableViewsListBox.Value);




%% Function to load pipeline from a file
    function loadPipeline(textArea,varargin)
        if ~isempty(varargin)
            [path, file, ext] = fileparts(varargin{1});
            file = [file,ext];
        else
            [file, path] = uigetfile('*.pwf', 'Select a pipeline file to load');
        end
        if file ~= 0
            fullPath = fullfile(path, file);

            pipelineContent = readcell(fullPath,'FileType','text','Delimiter','\n','LeadingDelimitersRule','keep',...
                'ConsecutiveDelimitersRule','split','Whitespace','\t');

            textArea.Value = pipelineContent;
        else
            uialert(fig, 'Error reading the file.', 'File Error');
        end
    end

%% Function to save pipeline to a file
    function savePipeline(textArea)
        defaultSavePath = GetFullPath(fullfile(mfilename('fullpath'),'..','..','PipelineDefinitions'));
        [file, path]    = uiputfile(fullfile(defaultSavePath,'*.pwf'), 'Save pipeline file');
        if file ~= 0
            fullPath = fullfile(path, file);
            fid = fopen(fullPath, 'wt');
            if fid ~= -1
                for i = 1:length(textArea.Value)
                    fprintf(fid, [textArea.Value{i},'\n']);
                end
                fclose(fid);
                uialert(fig, 'pipeline saved successfully!', 'Success');
            else
                uialert(fig, 'Error saving the file.', 'File Error');
            end
        end
    end

%% Function to get all components/views in a given directory
    function [Names, componentTypes] = getAvailableElements(dirPath,parentClasses, compOrView)

        % set up parentClasses to be used in regular expression
        parentClassesString = [];
        for i = 1:length(parentClasses)
            parentClassesString = [parentClassesString,  parentClasses{i}, '|'];
        end
        parentClassesString(end) = [];

        % Get all subdirectories, including the root directory
        allSubdirs = genpath(dirPath);

        % Split the subdirectories into a cell array
        subdirs = strsplit(allSubdirs, pathsep);

        % Initialize an empty array to store files that inherit from parentClass
        filesInheritingParentClass = [];

        % Loop over each subdirectory and look for class definitions
        for i = 1:length(subdirs)
            % Get all .m files in the current subdirectory
            files = dir(fullfile(subdirs{i}, '*.m'));

            % Loop over each file and check if it defines a class inheriting from parentClass
            for j = 1:length(files)
                filePath = fullfile(subdirs{i}, files(j).name);

                % Try to read the class definition from the file
                try
                    % Read the file's contents
                    fileContents = fileread(filePath);

                    % Look for a class definition and check for inheritance from parentClass
                    classDefPattern = ['classdef\s+(\w+)\s*(?:\w+\s*<\s*)?[^>]*(', parentClassesString, ')'];

                    % Check if the pattern matches
                    if ~isempty(regexp(fileContents, classDefPattern, 'once'))
                        % If the class inherits from parentClass, add it to the list
                        filesInheritingParentClass = [filesInheritingParentClass; files(j)];
                    end
                catch
                    % If there's an error reading the file (e.g., not a MATLAB file), skip it
                    continue;
                end
            end
        end

        % Collect names of components
        Names = {};
        for i = 1:length(filesInheritingParentClass)
            [~, Name] = fileparts(filesInheritingParentClass(i).name);
            Names{i,1} = Name;
        end
        Names = sort(Names);

        % Collect types of components
        if strcmp(compOrView,'component')
            for i = 1:length(Names)
                componentTypes{i,1} = getComponentType(Names{i});
            end
        else
            componentTypes = {};
        end

    end

%% Function to inspect the properties of a component selected in the listbox
    function viewComponent(textArea,parentClass,currentcomponent)
        [~,componentName] = fileparts(currentcomponent);
        component = eval(componentName);

        % Get the component type (e.g., 'uibutton', 'uitable', 'uieditfield', etc.)
        componentType = class(component);

        % Get the list of properties for the component
        props = properties(component);

        % Get the properties of the parent class(es)
        iter = 1;
        for i = 1:length(parentClass)
            parentClassProps = meta.class.fromName(parentClass{i});
            for j = 1:length(parentClassProps.PropertyList) 
                parentClassNames{iter,1} = parentClassProps.PropertyList(j).Name;
                iter = iter + 1;
            end
        end

        uniqueComponentProperties = setdiff(props,parentClassNames,'stable');
        uniqueComponentProperties = [uniqueComponentProperties; 'Name']; % add back Name

        % Start building the XML string
        textArea.Value{1,1} = [sprintf('    <Component Type="%s">', componentType)];

        % Loop through the properties and add them to the XML string
        for i = 1:length(uniqueComponentProperties)
            % Get the property value
            propValue = component.(uniqueComponentProperties{i});

            % Convert the property value to a string if it's not already
            if ischar(propValue) || isstring(propValue)
                propValue = sprintf('"%s"', propValue);
            elseif isnumeric(propValue)
                propValue = sprintf('"%g"', propValue);
            elseif islogical(propValue)
                propValue = sprintf('"%s"', mat2str(propValue));
            else
                propValue = '"Unknown"';  % For unsupported or complex types
            end

            % Add property to XML (with the property name as the tag)
            textArea.Value{i+1,1} = [sprintf('        <%s>%s</%s>', uniqueComponentProperties{i}, propValue, uniqueComponentProperties{i})];
        end

        % Close the component and XML structure
        textArea.Value{end+1,1} = '    </Component>';

    end

%% Function to inspect the properties of a view selected in the listbox
    function viewView(textArea,parentClass,currentView)
        [~,viewName] = fileparts(currentView);
        view = eval(viewName);

        % Get the view type (e.g., 'uibutton', 'uitable', 'uieditfield', etc.)
        viewType = class(view);

        % Get the list of properties for the view
        props = properties(view);

        % Get the properties of the parent class(es)
        iter = 1;
        for i = 1:length(parentClass)
            parentClassProps = meta.class.fromName(parentClass{i});
            for j = 1:length(parentClassProps.PropertyList) 
                parentClassNames{iter,1} = parentClassProps.PropertyList(j).Name;
                iter = iter + 1;
            end
        end

        uniqueViewProperties = setdiff(props,parentClassNames,'stable');
        uniqueViewProperties = [uniqueViewProperties; 'Name']; % add back Name

        % Start building the XML string
        textArea.Value{1,1} = [sprintf('    <View Type="%s">', viewType)];

        % Loop through the properties and add them to the XML string
        for i = 1:length(uniqueViewProperties)
            % Get the property value
            propValue = view.(uniqueViewProperties{i});

            % Convert the property value to a string if it's not already
            if ischar(propValue) || isstring(propValue)
                propValue = sprintf('"%s"', propValue);
            elseif isnumeric(propValue)
                propValue = sprintf('"%g"', propValue);
            elseif islogical(propValue)
                propValue = sprintf('"%s"', mat2str(propValue));
            else
                propValue = '"Unknown"';  % For unsupported or complex types
            end

            % Add property to XML (with the property name as the tag)
            textArea.Value{i+1,1} = [sprintf('        <%s>%s</%s>', uniqueViewProperties{i}, propValue, uniqueViewProperties{i})];
        end

        % Close the view and XML structure
        textArea.Value{end+1,1} = '    </View>';

    end

end

%% Function to get component type (input, processing, or output)
function [componentType] = getComponentType(className)
    % This function examines a given class to determine its type.
    % Inputs:
    %   - className: The name of the class as a string (e.g., 'MayoReface')
    % Outputs:
    %   - componentType: can be Input, Processing, or Output

    % Check if the class exists
    if ~exist('className', 'var') || ~ischar(className)
        error('Class name must be a valid string');
    end

    componentType = '';
    
    % Get the class definition
    classInfo = meta.class.fromName(className);
    
    % Iterate through the class methods
    for i = 1:length(classInfo.MethodList)
        methodName = classInfo.MethodList(i).Name;
        
        % Check for AddInput and AddOutput methods
        if strcmp(methodName, 'Publish')
            % Look at the Publish method to get inputs and outputs
            [inputs, outputs] = extractInputsOutputs(className);
        end
        
    end

    if ~isempty(inputs) && ~isempty(outputs)
        componentType = 'Processing';
    elseif ~isempty(inputs) && isempty(outputs)
        componentType = 'Output';
    elseif isempty(inputs) && ~isempty(outputs)
        componentType = 'Input';
    else
        componentType = 'NotValid';
    end
end

%% Function to 
function [inputs, outputs] = extractInputsOutputs(className)

    % Check for calls to AddInput and AddOutput in the method body
    filePath   = which([className '.m']);
    methodCode = fileread(filePath);
    
    % Regular expression to find AddInput and AddOutput calls
    inputPattern  = 'obj.AddInput\((.*?)\);';
    outputPattern = 'obj.AddOutput\((.*?)\);';
    
    % Extract inputs and outputs
    inputsMatch  = regexp(methodCode, inputPattern,  'match');
    outputsMatch = regexp(methodCode, outputPattern, 'match');

    % Parse the matched results
    inputs = parseAddInputOutput(inputsMatch);
    outputs = parseAddInputOutput(outputsMatch);
end

%%
function result = parseAddInputOutput(matches)
    % Parse the AddInput/Output calls into structured results
    result = {};
    
    for i = 1:length(matches)
        match      = matches{i};
        parts      = strsplit(match, '(');
        object     = strsplit(parts{2},',');
        identifier = object{1};

        result{end+1} = identifier;
    end
end
