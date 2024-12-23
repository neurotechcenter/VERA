function PipelineDesigner()
    % The pipeline designer is a tool to load, modify, and save VERA 
    % pipelines

    addpath(genpath(fullfile('..','classes')));
    addpath(genpath(fullfile('..','Components')));

    % Create the main figure for the GUI
    fig = uifigure('Position', [100, 100, 1400, 800], 'Name', 'Pipeline Designer');

    % Create a menu bar
    filemenu = uimenu(fig, 'Text', 'File');
    helpmenu = uimenu(fig, 'Text', 'Help');
    
    %% Create the TextArea for writing pipeline code
    uilabel(fig, ...
        'Position', [20, 770, 300, 20], ...
        'Text','Pipeline','FontName', 'Courier New', 'FontSize', 16);
    
    pipelineTextArea = uitextarea(fig, ...
        'Position', [20, 20, 560, 750], ...
        'Value','', 'FontName', 'Courier New', 'FontSize', 12, 'Editable', 'on');

    %% Listbox of Input components
    uilabel(fig, ...
        'Position', [590, 770, 300, 20], ...
        'Text','Input Components','FontName', 'Courier New', 'FontSize', 16);
    
    availableInputComponentsListBox = uilistbox(fig, ...
        'Position', [590, 632, 390, 138], ...
        'Items',{''}, 'FontName', 'Courier New', 'FontSize', 12);

    %% Listbox of Processing components
    uilabel(fig, ...
        'Position', [590, 606, 300, 20], ...
        'Text','Processing Components','FontName', 'Courier New', 'FontSize', 16);

    availableProcessingComponentsListBox = uilistbox(fig, ...
        'Position', [590, 468, 390, 138], ...
        'Items',{''}, 'FontName', 'Courier New', 'FontSize', 12);

    %% Listbox of Output components
    uilabel(fig, ...
        'Position', [590, 443, 300, 20], ...
        'Text','Output Components','FontName', 'Courier New', 'FontSize', 16);

    availableOutputComponentsListBox = uilistbox(fig, ...
        'Position', [590, 305, 390, 138], ...
        'Items',{''}, 'FontName', 'Courier New', 'FontSize', 12);
    
    %% Create the TextArea for modifying component code
    uilabel(fig, ...
        'Position', [590, 255, 300, 20], ...
        'Text','Current Component','FontName', 'Courier New', 'FontSize', 16);

    componentTextArea = uitextarea(fig, ...
        'Position', [590, 20, 390, 230], ...
        'Value','', 'FontName', 'Courier New', 'FontSize', 12, 'Editable', 'on');
    
    %% Listbox of possible views
    uilabel(fig, ...
        'Position', [990, 443, 300, 20], ...
        'Text','Available Views','FontName', 'Courier New', 'FontSize', 16);
    
    availableViewsListBox = uilistbox(fig, ...
        'Position', [990, 305, 390, 138], ...
        'Items',{''}, 'FontName', 'Courier New', 'FontSize', 12);
    
    %% Create the TextArea for modifying view code
    uilabel(fig, ...
        'Position', [990, 255, 300, 20], ...
        'Text','Current View','FontName', 'Courier New', 'FontSize', 16);

    viewTextArea = uitextarea(fig, ...
        'Position', [990, 20, 390, 230], ...
        'Value','', 'FontName', 'Courier New', 'FontSize', 12, 'Editable', 'on');
    
    %% Create the TextArea for showing component/view help
    uilabel(fig, ...
        'Position', [990, 770, 300, 20], ...
        'Text','Help','FontName', 'Courier New', 'FontSize', 16);

    helpTextArea = uitextarea(fig, ...
        'Position', [990, 497, 390, 273], ...
        'Value','', 'FontName', 'Courier New', 'FontSize', 12, 'Editable', 'off');
    
    helpHyperlink = uihyperlink(fig,'Position', [990, 473, 400 20], ...
        'FontName', 'Courier New', 'FontSize', 16);

    helpHyperlink.Text    = '';
    helpHyperlink.URL     = '';
    helpHyperlink.Tooltip = '';

    %% Create a Load menu button to load a pipeline from a file
    uimenu(filemenu, 'Text', 'Load Pipeline', 'MenuSelectedFcn', @(src, event) loadPipeline(fig,pipelineTextArea));
    
    %% Create a Save menu button to save the pipeline to a file
    uimenu(filemenu, 'Text', 'Save Pipeline', 'MenuSelectedFcn', @(src, event) savePipeline(fig,pipelineTextArea));

    %% Create a clear pipeline button
    uimenu(filemenu, 'Text', 'Clear Pipeline', 'MenuSelectedFcn', @(src, event) confirmAction(@() clearPipeline(fig,pipelineTextArea)));

    %% Create a help button to link to the wiki
    uimenu(helpmenu, 'Text', 'VERA Wiki', 'MenuSelectedFcn', @(src, event) web('https://github.com/neurotechcenter/VERA/wiki/PipelineDesigner', '-browser'));

    %% Create an Add Component button to move current component to the bottom of the pipeline text area
    uibutton(fig, 'push', 'Text', 'Add Component', ...
        'Position', [780, 260, 150, 30], 'FontSize', 16,...
        'ButtonPushedFcn', @(btn, event) AddComponent(pipelineTextArea, componentTextArea));

    %% Create an Add View button to move current view to the bottom of the pipeline text area
    uibutton(fig, 'push', 'Text', 'Add View', ...
        'Position', [1130, 260, 100, 30], 'FontSize', 16,...
        'ButtonPushedFcn', @(btn, event) AddView(pipelineTextArea, viewTextArea));

    %% On startup, display demo pipeline
    % path_to_demo = GetFullPath(fullfile(mfilename('fullpath'),'..','..','PipelineDefinitions','SimpleTutorialPipeline.pwf'));
    % loadPipeline(pipelineTextArea,path_to_demo);
    
    %% On startup, display empty pipeline
    clearPipeline(fig,pipelineTextArea);

    %% Get all components
    componentParentClasses = {'AComponent'};
    componentPath          = GetFullPath(fullfile(mfilename('fullpath'),'..','..','Components'));

    [AvailableComponents, componentTypes] = getAvailableElements(componentPath, componentParentClasses, 'component');
    
    %% Populate list of possible Input components
    inputIDXs = contains(componentTypes,'Input');
    
    availableInputComponentsListBox.Items = AvailableComponents(inputIDXs);

    % Update view window to display current component
    availableInputComponentsListBox.ValueChangedFcn = @(src,event)...
        viewComponent(componentTextArea, helpTextArea, helpHyperlink, componentParentClasses, availableInputComponentsListBox.Value);

    %% Populate list of possible Processing components
    processingIDXs = contains(componentTypes,'Processing');
    
    availableProcessingComponentsListBox.Items = AvailableComponents(processingIDXs);
    
    % Update view window to display current component
    availableProcessingComponentsListBox.ValueChangedFcn = @(src,event)...
        viewComponent(componentTextArea, helpTextArea, helpHyperlink, componentParentClasses, availableProcessingComponentsListBox.Value);

    %% Populate list of possible Output components
    outputIDXs = contains(componentTypes,'Output');
    
    availableOutputComponentsListBox.Items = AvailableComponents(outputIDXs);
    
    % Update view window to display current component
    availableOutputComponentsListBox.ValueChangedFcn = @(src,event)...
        viewComponent(componentTextArea, helpTextArea, helpHyperlink, componentParentClasses, availableOutputComponentsListBox.Value);

    %% Populate list of possible views
    viewParentClasses = {'uix.Grid','AView','IComponentView','SliceViewerXYZ'}; % properties to be excluded
    viewPath          = GetFullPath(fullfile(mfilename('fullpath'),'..','..','classes','GUI','Views'));

    availableViewsListBox.Items = getAvailableElements(viewPath, viewParentClasses, 'view');
    
    % Update view window to display current view
    availableViewsListBox.ValueChangedFcn = @(src,event)...
        viewView(viewTextArea, helpTextArea, helpHyperlink, viewParentClasses, availableViewsListBox.Value);

end


%% Function to load pipeline from a file
function loadPipeline(fig,textArea,varargin)
    if ~isempty(varargin)
        [path, file, ext] = fileparts(varargin{1});
        file = [file,ext];
    else
        defaultLoadPath = GetFullPath(fullfile(mfilename('fullpath'),'..','..','PipelineDefinitions'));
        fig.Visible     = 'off'; % Hide the main window
        [file, path]    = uigetfile(fullfile(defaultLoadPath,'*.pwf'), 'Select a pipeline file to load');
        fig.Visible     = 'on'; % Show the main window
    end
    if file ~= 0
        fullPath = fullfile(path, file);

        pipelineContent = readcell(fullPath,'FileType','text','Delimiter',{'\n','\r','\r\n'},...
            'Whitespace','','EmptyLineRule','read');

        % replace empty lines with spaces so they can exist
        emptyCells = cellfun(@ismissing,pipelineContent,'UniformOutput',false);
        emptyCells = cellfun(@all,emptyCells);

        for i = 1:length(emptyCells)
            if emptyCells(i)
                pipelineContent{i} = '    ';
            end
        end

        % replace tabs with spaces
        for i = 1:length(pipelineContent)
            pipelineContent{i} = regexprep(pipelineContent{i}, '\t', '    ');
        end

        % write pipeline to text area
        textArea.Value = pipelineContent;
    else
        uialert(fig, 'Error reading the file.', 'File Error');
    end
end

%% Function to save pipeline to a file
function savePipeline(fig,textArea)
    % check component/view names to make sure there are no duplicates
    duplicateNames = checkforDuplicateNames(textArea);

    if ~duplicateNames
        defaultSavePath = GetFullPath(fullfile(mfilename('fullpath'),'..','..','PipelineDefinitions'));
        fig.Visible     = 'off'; % Hide the main window
        [file, path]    = uiputfile(fullfile(defaultSavePath,'*.pwf'), 'Save pipeline file');
        fig.Visible     = 'on'; % Show the main window
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
    else
        uialert(fig, 'Duplicate component or view names found. Ensure that all components and views have unique names.', 'File Error');
    end
end

%% function to clear pipeline
function clearPipeline(fig,textArea)
    textArea.Value = {'<?xml version="1.0" encoding="utf-8"?>';
                              '<PipelineDefinition Name="Pipeline Name">';
                              '';
                              '';
                              '</PipelineDefinition>'};

end

%% Function to ensure there are no duplicate names of components or views
function isDuplicated = checkforDuplicateNames(textArea)
    % Use a regular expression to extract all 'Name' values from the XML text
    pattern = '<Name>"(.*?)"</Name>';  % This regex matches text between <Name>"..."</Name>
    names = regexp(textArea.Value, pattern, 'tokens');
    
    % Flatten the cell array and remove quotes from the extracted names
    % names = cellfun(@(x) x{1}, names, 'UniformOutput', false);

    notnames = cellfun(@isempty, names, 'UniformOutput', true);
    names(notnames) = [];

    names = cellfun(@(x) x{1}, names, 'UniformOutput', false);
    
    % Check for duplicates
    duplicate_names = find_duplicates(names);
    
    % Display result
    if ~isempty(duplicate_names)
        isDuplicated = 1;
    else
        isDuplicated = 0;
    end
end

% Helper function to find duplicate names
function duplicates = find_duplicates(names)
    % Find duplicates by comparing each name with others
    duplicates = {};
    seen = {};
    for i = 1:length(names)
        name = names{i}{1};
        if any(strcmp(seen, name))
            duplicates{end+1} = name;  % Add to duplicates list
        else
            seen{end+1} = name;  % Mark this name as seen
        end
    end
end

%% Function to get all components/views in a given directory
function [Names, componentTypes] = getAvailableElements(dirPath,parentClasses,compOrView)

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
function viewComponent(textArea,helpArea,helpHyperlink,parentClass,currentComponent)
    [~,componentName] = fileparts(currentComponent);
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
    textArea.Value      = {''};
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
            propValue = '""';  % For unsupported or complex types
        end

        % Add property to XML (with the property name as the tag)
        textArea.Value{i+1,1} = [sprintf('        <%s>%s</%s>', uniqueComponentProperties{i}, propValue, uniqueComponentProperties{i})];
    end

    % Close the component and XML structure
    textArea.Value{end+1,1} = '    </Component>';

    % show help of selected view
    showHelp(helpArea, helpHyperlink, currentComponent)

end

%% Function to inspect the properties of a view selected in the listbox
function viewView(textArea,helpArea,helpHyperlink,parentClass,currentView)
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
    textArea.Value      = {''};
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
            propValue = '""';  % For unsupported or complex types
        end

        % Add property to XML (with the property name as the tag)
        textArea.Value{i+1,1} = [sprintf('        <%s>%s</%s>', uniqueViewProperties{i}, propValue, uniqueViewProperties{i})];
    end

    % Close the view and XML structure
    textArea.Value{end+1,1} = '    </View>';

    % show help of selected view
    showHelp(helpArea, helpHyperlink, currentView)

end

%% Help function to display help text
function showHelp(helpTextArea,helpHyperlink,element)
    helpText = help(element);
    
    % find and remove documentation text for formatting
    documentationStart = strfind(helpText,['Documentation for ', element]);
    documentationEnd   = strfind(helpText,['doc ', element]) + length(['doc ', element]);
    documentation      = helpText(documentationStart:documentationEnd);

    % find and remove folder text for formatting
    folderStart = strfind(helpText,['Folders named ', element]);
    folderName  = helpText(folderStart:end);

    % clean up help text
    helpText = strtrim(helpText(1:documentationStart-1));
    helpText = strrep(helpText, newline, '');
    helpText = strrep(helpText, '  ', newline);

    % add back documentation and folder info
    helpText = [helpText, newline, newline, documentation];
    helpText = [helpText, newline, folderName];

    helpHyperlink.Text    = element;
    helpHyperlink.URL     = ['https://github.com/neurotechcenter/VERA/wiki/', element];
    helpHyperlink.Tooltip = helpHyperlink.URL;

    % write help text to helpTextArea
    helpTextArea.Value = helpText;
end

%% Function to move component to bottom of pipeline
function AddComponent(pipelineTextArea,componentTextArea)
    pipelineTextArea.Value = [
                                pipelineTextArea.Value(1:end-2); 
                                componentTextArea.Value; 
                                '    '; 
                                pipelineTextArea.Value(end-1:end)
                             ];
end

%% Function to move component to bottom of pipeline
function AddView(pipelineTextArea,viewTextArea)
    pipelineTextArea.Value = [
                                pipelineTextArea.Value(1:end-2); 
                                viewTextArea.Value; 
                                '    '; 
                                pipelineTextArea.Value(end-1:end)
                             ];
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

% Function to extract inputs and outputs of a component
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
    inputs  = parseAddInputOutput(inputsMatch);
    outputs = parseAddInputOutput(outputsMatch);
end

% Function to parse the component for the matched string
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


%% Function to show a confirmation dialog
function confirmAction(action)
    % Ask the user for confirmation using questdlg
    choice = questdlg('Are you sure?', ...
        'Confirmation', 'Yes', 'No', 'No');
    
    % If the user selects 'Yes', execute the action
    if strcmp(choice, 'Yes')
        action();  % Call the action
    end
end