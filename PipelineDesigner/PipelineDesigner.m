function PipelineDesigner()
    % The pipeline designer is a tool to load, modify, and save VERA 
    % pipelines

    mfilePath = fileparts(mfilename('fullpath'));

    addpath(genpath(fullfile(mfilePath,'..')));
    addpath(genpath(fullfile(mfilePath,'..','classes')));
    addpath(genpath(fullfile(mfilePath,'..','Components')));
    addpath(genpath(fullfile(mfilePath,'..','Dependencies')));

    %java stuff to make sure that the GUI works as expected
    warning off
    javaaddpath(fullfile(mfilePath,'..','Dependencies/Widgets Toolbox/resource/MathWorksConsultingWidgets.jar'));
    import uiextras.jTree.*;
    warning on

    %% UI Layout Constants
    UI = struct();
    
    % Window settings
    UI.WINDOW = struct(...
        'WIDTH',   1400, ...
        'HEIGHT',  800, ...
        'START_X', 100, ...
        'START_Y', 100 ...
    );
    
    % Common dimensions
    UI.COMMON = struct(...
        'LABEL_HEIGHT',     20, ...
        'LABEL_WIDTH',      300, ...
        'LISTBOX_WIDTH',    390, ...
        'LISTBOX_HEIGHT',   138, ...
        'TEXTAREA_HEIGHT',  230, ...
        'PIPELINE_WIDTH',   560, ...
        'PIPELINE_HEIGHT',  750, ...
        'HELP_AREA_HEIGHT', 273, ...
        'HYPERLINK_WIDTH',  400, ...
        'SPACING',          6 ...
        );
    
    % X-coordinates for different sections
    UI.X = struct(...
        'LEFT_PANEL',   20, ...
        'MIDDLE_PANEL', 590, ...
        'RIGHT_PANEL',  990 ...
    );
    
    % Y-coordinates for different elements
    UI.Y = struct(...
        'TOP',             770, ...
        'INPUT_LIST',      632, ...
        'PROCESSING_LIST', 468, ...
        'OUTPUT_LIST',     305, ...
        'COMPONENT_LABEL', 255, ...
        'HELP_TEXT',       497, ...
        'HELP_LINK',       473, ...
        'BOTTOM',          20 ...
    );

    % Button specific settings
    UI.BUTTON = struct(...
        'ADD_COMPONENT', struct(...
            'X',      780, ...
            'Y',      260, ...
            'WIDTH',  150, ...
            'HEIGHT', 30 ...
        ), ...
        'ADD_VIEW', struct(...
            'X',      1130, ...
            'Y',      260, ...
            'WIDTH',  100, ...
            'HEIGHT', 30 ...
        ) ...
    );

    % Font settings
    UI.FONT = struct(...
        'REGULAR', struct('NAME', 'Arial',       'SIZE', 16), ...
        'CODE',    struct('NAME', 'Courier New', 'SIZE', 12) ...
    );
    
    %% Create the main figure for the GUI
    fig = uifigure('Position', [UI.WINDOW.START_X, UI.WINDOW.START_Y, ...
                               UI.WINDOW.WIDTH, UI.WINDOW.HEIGHT], ...
                   'Name', 'Pipeline Designer');

    % Create a menu bar
    filemenu = uimenu(fig, 'Text', 'File');
    helpmenu = uimenu(fig, 'Text', 'Help');
    
    %% Create the TextArea for writing pipeline code
     uilabel(fig, ...
        'Position', [UI.X.LEFT_PANEL, UI.Y.TOP, UI.COMMON.LABEL_WIDTH, UI.COMMON.LABEL_HEIGHT], ...
        'Text', 'Pipeline', ...
        'FontName', UI.FONT.REGULAR.NAME, ...
        'FontSize', UI.FONT.REGULAR.SIZE);
    
    pipelineTextArea = uitextarea(fig, ...
        'Position', [UI.X.LEFT_PANEL, UI.Y.BOTTOM, UI.COMMON.PIPELINE_WIDTH, UI.COMMON.PIPELINE_HEIGHT], ...
        'Value', '', ...
        'FontName', UI.FONT.CODE.NAME, ...
        'FontSize', UI.FONT.CODE.SIZE, ...
        'Editable', 'on');

    %% Listbox of Input components
    uilabel(fig, ...
        'Position', [UI.X.MIDDLE_PANEL, UI.Y.TOP, UI.COMMON.LABEL_WIDTH, UI.COMMON.LABEL_HEIGHT], ...
        'Text', 'Input Components', ...
        'FontName', UI.FONT.REGULAR.NAME, ...
        'FontSize', UI.FONT.REGULAR.SIZE);
    
    availableInputComponentsListBox = uilistbox(fig, ...
        'Position', [UI.X.MIDDLE_PANEL, UI.Y.INPUT_LIST, UI.COMMON.LISTBOX_WIDTH, UI.COMMON.LISTBOX_HEIGHT], ...
        'Items', {''}, ...
        'FontName', UI.FONT.CODE.NAME, ...
        'FontSize', UI.FONT.CODE.SIZE);

    %% Listbox of Processing components
    uilabel(fig, ...
        'Position', [UI.X.MIDDLE_PANEL, UI.Y.PROCESSING_LIST + UI.COMMON.LISTBOX_HEIGHT + UI.COMMON.SPACING, UI.COMMON.LABEL_WIDTH, UI.COMMON.LABEL_HEIGHT], ...
        'Text', 'Processing Components', ...
        'FontName', UI.FONT.REGULAR.NAME, ...
        'FontSize', UI.FONT.REGULAR.SIZE);

    availableProcessingComponentsListBox = uilistbox(fig, ...
        'Position', [UI.X.MIDDLE_PANEL, UI.Y.PROCESSING_LIST, UI.COMMON.LISTBOX_WIDTH, UI.COMMON.LISTBOX_HEIGHT], ...
        'Items', {''}, ...
        'FontName', UI.FONT.CODE.NAME, ...
        'FontSize', UI.FONT.CODE.SIZE);

    %% Listbox of Output components
    uilabel(fig, ...
        'Position', [UI.X.MIDDLE_PANEL, UI.Y.OUTPUT_LIST + UI.COMMON.LISTBOX_HEIGHT + UI.COMMON.SPACING, UI.COMMON.LABEL_WIDTH, UI.COMMON.LABEL_HEIGHT], ...
        'Text', 'Output Components', ...
        'FontName', UI.FONT.REGULAR.NAME, ...
        'FontSize', UI.FONT.REGULAR.SIZE);

    availableOutputComponentsListBox = uilistbox(fig, ...
        'Position', [UI.X.MIDDLE_PANEL, UI.Y.OUTPUT_LIST, UI.COMMON.LISTBOX_WIDTH, UI.COMMON.LISTBOX_HEIGHT], ...
        'Items', {''}, ...
        'FontName', UI.FONT.CODE.NAME, ...
        'FontSize', UI.FONT.CODE.SIZE);
    
    %% Create the TextArea for modifying component code
    uilabel(fig, ...
        'Position', [UI.X.MIDDLE_PANEL, UI.Y.COMPONENT_LABEL, UI.COMMON.LABEL_WIDTH, UI.COMMON.LABEL_HEIGHT], ...
        'Text', 'Current Component', ...
        'FontName', UI.FONT.REGULAR.NAME, ...
        'FontSize', UI.FONT.REGULAR.SIZE);

    componentTextArea = uitextarea(fig, ...
        'Position', [UI.X.MIDDLE_PANEL, UI.Y.BOTTOM, UI.COMMON.LISTBOX_WIDTH, UI.COMMON.TEXTAREA_HEIGHT], ...
        'Value', '', ...
        'FontName', UI.FONT.CODE.NAME, ...
        'FontSize', UI.FONT.CODE.SIZE, ...
        'Editable', 'on');
    
    %% Listbox of possible views
    uilabel(fig, ...
        'Position', [UI.X.RIGHT_PANEL, UI.Y.OUTPUT_LIST + UI.COMMON.LISTBOX_HEIGHT + UI.COMMON.SPACING, UI.COMMON.LABEL_WIDTH, UI.COMMON.LABEL_HEIGHT], ...
        'Text', 'Available Views', ...
        'FontName', UI.FONT.REGULAR.NAME, ...
        'FontSize', UI.FONT.REGULAR.SIZE);
    
    availableViewsListBox = uilistbox(fig, ...
        'Position', [UI.X.RIGHT_PANEL, UI.Y.OUTPUT_LIST, UI.COMMON.LISTBOX_WIDTH, UI.COMMON.LISTBOX_HEIGHT], ...
        'Items', {''}, ...
        'FontName', UI.FONT.CODE.NAME, ...
        'FontSize', UI.FONT.CODE.SIZE);
    
    %% Create the TextArea for modifying view code
    uilabel(fig, ...
        'Position', [UI.X.RIGHT_PANEL, UI.Y.COMPONENT_LABEL, UI.COMMON.LABEL_WIDTH, UI.COMMON.LABEL_HEIGHT], ...
        'Text', 'Current View', ...
        'FontName', UI.FONT.REGULAR.NAME, ...
        'FontSize', UI.FONT.REGULAR.SIZE);

    viewTextArea = uitextarea(fig, ...
        'Position', [UI.X.RIGHT_PANEL, UI.Y.BOTTOM, UI.COMMON.LISTBOX_WIDTH, UI.COMMON.TEXTAREA_HEIGHT], ...
        'Value', '', ...
        'FontName', UI.FONT.CODE.NAME, ...
        'FontSize', UI.FONT.CODE.SIZE, ...
        'Editable', 'on');
    
    %% Create the TextArea for showing component/view help
    uilabel(fig, ...
        'Position', [UI.X.RIGHT_PANEL, UI.Y.TOP, UI.COMMON.LABEL_WIDTH, UI.COMMON.LABEL_HEIGHT], ...
        'Text', 'Help', ...
        'FontName', UI.FONT.REGULAR.NAME, ...
        'FontSize', UI.FONT.REGULAR.SIZE);

    helpTextArea = uitextarea(fig, ...
        'Position', [UI.X.RIGHT_PANEL, UI.Y.HELP_TEXT, UI.COMMON.LISTBOX_WIDTH, UI.COMMON.HELP_AREA_HEIGHT], ...
        'Value', '', ...
        'FontName', UI.FONT.CODE.NAME, ...
        'FontSize', UI.FONT.CODE.SIZE, ...
        'Editable', 'off');
    
    helpHyperlink = uihyperlink(fig, ...
        'Position', [UI.X.RIGHT_PANEL, UI.Y.HELP_LINK, UI.COMMON.HYPERLINK_WIDTH, UI.COMMON.LABEL_HEIGHT], ...
        'FontName', UI.FONT.CODE.NAME, ...
        'FontSize', UI.FONT.REGULAR.SIZE);

    helpHyperlink.Text    = '';
    helpHyperlink.URL     = '';
    helpHyperlink.Tooltip = '';

    %% Create a Load menu button to load a pipeline from a file
    uimenu(filemenu, 'Text', 'Load Pipeline', 'MenuSelectedFcn', @(src, event) loadPipeline(fig,pipelineTextArea));
    
    %% Create a Save menu button to save the pipeline to a file
    uimenu(filemenu, 'Text', 'Save Pipeline', 'MenuSelectedFcn', @(src, event) savePipeline(fig,pipelineTextArea));

    %% Create a clear pipeline button
    uimenu(filemenu, 'Text', 'Clear Pipeline', 'MenuSelectedFcn', @(src, event) confirmAction(@() clearPipeline(pipelineTextArea)));

    %% Create a Save menu button to save the pipeline to a file
    uimenu(filemenu, 'Text', 'Check Pipeline', 'MenuSelectedFcn', @(src, event) checkPipeline(fig,pipelineTextArea));

    %% Create a help button to link to the wiki
    uimenu(helpmenu, 'Text', 'VERA Wiki', 'MenuSelectedFcn', @(src, event) web('https://github.com/neurotechcenter/VERA/wiki/PipelineDesigner', '-browser'));

    %% Create an Add Component button to move current component to the bottom of the pipeline text area
    uibutton(fig, 'push', 'Text', 'Add Component', ...
        'Position', [UI.BUTTON.ADD_COMPONENT.X, UI.BUTTON.ADD_COMPONENT.Y, ...
                    UI.BUTTON.ADD_COMPONENT.WIDTH, UI.BUTTON.ADD_COMPONENT.HEIGHT], ...
        'FontSize', UI.FONT.REGULAR.SIZE, ...
        'ButtonPushedFcn', @(btn, event) AddComponent(pipelineTextArea, componentTextArea));

    %% Create an Add View button to move current view to the bottom of the pipeline text area
    uibutton(fig, 'push', 'Text', 'Add View', ...
        'Position', [UI.BUTTON.ADD_VIEW.X, UI.BUTTON.ADD_VIEW.Y, ...
                    UI.BUTTON.ADD_VIEW.WIDTH, UI.BUTTON.ADD_VIEW.HEIGHT], ...
        'FontSize', UI.FONT.REGULAR.SIZE, ...
        'ButtonPushedFcn', @(btn, event) AddView(pipelineTextArea, viewTextArea));
    %% On startup, display demo pipeline
    % path_to_demo = GetFullPath(fullfile(mfilename('fullpath'),'..','..','PipelineDefinitions','SimpleTutorialPipeline.pwf'));
    % loadPipeline(pipelineTextArea,path_to_demo);
    
    %% On startup, display empty pipeline
    clearPipeline(pipelineTextArea);

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
function [fullPath] = savePipeline(fig,textArea,varargin)
    fullPath = [];

    % if there is an input file given, assume it comes from the
    % checkPipeline function. This is used to avoid recursively checking
    % the pipeline when using the 'check pipeline' file dialog
    if nargin > 2
        inputFilePath = varargin{1};
        calledFromCheckPipeline = 1;
    else
        inputFilePath = [];
        calledFromCheckPipeline = 0;
    end

    % check pipeline to see if it is valid in VERA
    % Only check in SavePipeline if SavePipeline is called directly.
    % Not sure if this logic is sound.
    if ~calledFromCheckPipeline
        pipelineStatus = checkPipeline(fig,textArea);
    else
        pipelineStatus = 1;
    end

    if pipelineStatus
        defaultSavePath = GetFullPath(fullfile(mfilename('fullpath'),'..','..','PipelineDefinitions'));

        % get save path
        fig.Visible = 'off'; % Hide the main window
        if ~isempty(inputFilePath)
            [path, file, ext] = fileparts(inputFilePath);
            file = [file, ext];
        else
            [file, path] = uiputfile(fullfile(defaultSavePath,'*.pwf'), 'Save pipeline file');
        end
        fig.Visible = 'on'; % Show the main window

        % write text area to file
        if file ~= 0
            fullPath = fullfile(path, file);
            fid = fopen(fullPath, 'wt');
            if fid ~= -1
                for i = 1:length(textArea.Value)
                    fprintf(fid, [textArea.Value{i},'\n']);
                end
                fclose(fid);
            else
                uialert(fig, 'Error saving the file.', 'File Error');
            end

            if ~calledFromCheckPipeline
                uialert(fig, 'Pipeline saved!', 'Save Success');
            end
        else
            uialert(fig, 'Pipeline not saved! No file name selected', 'Save Failure');
        end

    else
        uialert(fig, 'Pipeline cannot be saved because pipeline check failed! See error/warning messages!', 'Save Failure');
    end
end

%% function to clear pipeline
function clearPipeline(textArea)
    textArea.Value = {'<?xml version="1.0" encoding="utf-8"?>';
                              '<PipelineDefinition Name="Pipeline Name">';
                              '';
                              '';
                              '</PipelineDefinition>'};

end

%% function to check the validity of the pipeline
function pipelineStatus = checkPipeline(fig,textArea)

    % Save working pipeline to be loaded into VERA and checked
    currentPath  = fileparts(mfilename('fullpath'));
    tempProjPath = fullfile(currentPath,'temp/tempProj');

    if ~exist(tempProjPath,'dir')
        mkdir(tempProjPath);
    else
        % delete temporary folder
        warning off;
        rmdir(fullfile(tempProjPath,'..'),'s');
        warning on;
        % make it fresh
        mkdir(tempProjPath);
    end

    tempPipelinePath = fullfile(tempProjPath,'tempPipeline.pwf');
    pipelinePath     = savePipeline(fig,textArea,tempPipelinePath);


    % start VERA (would like to change this so pipelines can be checked
    % without running VERA...)
    VERAvisiblity    = 'off';
    VERAhandle       = MainGUI(VERAvisiblity);
    allFigureHandles = findall(groot,'Type','figure');
    VERAfig          = allFigureHandles(end);

    % Create dialog boxes when there are warnings or errors
    errormessage = [];
    try 
        % create VERA project to see if the pipeline is viable
        lastwarn('');
        createNewProject(VERAhandle,tempProjPath,pipelinePath);

        warnMsg_create = formatWarning();

        if ~isempty(warnMsg_create)
            warndlg(warnMsg_create);

            % no need to continue testing if we find an issue
            % close VERA
            close(VERAfig);
        
            % delete temporary folder
            warning off;
            rmdir(fullfile(tempProjPath,'..'),'s');
            warning on;

            uialert(fig, 'Pipeline check failed!','Pipeline Check Results')
            pipelineStatus = 0;

            return;
        end

        % configure all components to see if any inputs or outputs are missing
        lastwarn('');
        configureAll(VERAhandle);

        warnMsg_configure = formatWarning();

        if ~isempty(warnMsg_configure)
            warndlg(warnMsg_configure);

            % no need to continue testing if we find an issue
            % close VERA
            close(VERAfig);
        
            % delete temporary folder
            warning off;
            rmdir(fullfile(tempProjPath,'..'),'s');
            warning on;

            uialert(fig, 'Pipeline check failed!','Pipeline Check Results')
            pipelineStatus = 0;

            return;
        end
    catch me
        errormessage = me.message;
        errordlg(errormessage);
    end

    % Pipeline check results
    if isempty(warnMsg_create) && isempty(warnMsg_configure) && isempty(errormessage)
        pipelineStatus = 1;
        uialert(fig, 'Pipeline check passed!','Pipeline Check Results')
    else
        uialert(fig, 'Pipeline check failed!','Pipeline Check Results')
        pipelineStatus = 0;
    end

    % sclose VERA
    close(VERAfig);

    % delete temporary folder
    warning off;
    rmdir(fullfile(tempProjPath,'..'),'s');
    warning on;
end

% reformat matlab warning for nicer display in warn dialog box
function warnMsg = formatWarning()
    warnMsg = lastwarn;

    if ~isempty(warnMsg)
        % isolate meaningful message
        [warnMsg, matches] = strsplit(warnMsg,{'Error','</a>'});
        start   = find(contains(matches,'</a>'),1,'first') + 1;
        warnMsg = warnMsg{start};

        % remove return lines in warning
        warnMsg = regexprep(warnMsg,'[\n\r]+',' ');

        % remove leading space
        warnMsg(1) = [];
    end
end

% %% Function to ensure there are no duplicate names of components or views
% function isDuplicated = checkforDuplicateNames(textArea)
%     % Use a regular expression to extract all 'Name' values from the XML text
%     pattern = '<Name>"(.*?)"</Name>';  % This regex matches text between <Name>"..."</Name>
%     names = regexp(textArea.Value, pattern, 'tokens');
% 
%     % Flatten the cell array and remove quotes from the extracted names
%     % names = cellfun(@(x) x{1}, names, 'UniformOutput', false);
% 
%     notnames = cellfun(@isempty, names, 'UniformOutput', true);
%     names(notnames) = [];
% 
%     names = cellfun(@(x) x{1}, names, 'UniformOutput', false);
% 
%     % Check for duplicates
%     duplicate_names = find_duplicates(names);
% 
%     % Display result
%     if ~isempty(duplicate_names)
%         isDuplicated = 1;
%         for i = 1:length(duplicate_names)
%             warndlg(['Duplicate component names! Check for multiple components named ', duplicate_names{i}])
%         end
%     else
%         isDuplicated = 0;
%     end
% end
% 
% % Helper function to find duplicate names
% function duplicates = find_duplicates(names)
%     % Find duplicates by comparing each name with others
%     duplicates = {};
%     seen = {};
%     for i = 1:length(names)
%         name = names{i}{1};
%         if any(strcmp(seen, name))
%             duplicates{end+1} = name;  % Add to duplicates list
%         else
%             seen{end+1} = name;  % Mark this name as seen
%         end
%     end
% end

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
    
    optionalInputPattern  = 'obj.AddOptionalInput\((.*?)\);';
    optionalOutputPattern = 'obj.AddOptionalOutput\((.*?)\);';

    % Extract inputs and outputs
    inputsMatch  = regexp(methodCode, inputPattern,  'match');
    outputsMatch = regexp(methodCode, outputPattern, 'match');

    optionalInputsMatch  = regexp(methodCode, optionalInputPattern,  'match');
    optionalOutputsMatch = regexp(methodCode, optionalOutputPattern, 'match');
    
    % Parse the matched results
    inputs  = parseAddInputOutput(inputsMatch);
    outputs = parseAddInputOutput(outputsMatch);

    optionalInputs  = parseAddInputOutput(optionalInputsMatch);
    optionalOutputs = parseAddInputOutput(optionalOutputsMatch);

    inputs  = [inputs,  optionalInputs];
    outputs = [outputs, optionalOutputs];
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
    choice = questdlg('Are you sure you want to clear this pipeline?', ...
        'Clear Pipeline', 'Yes', 'No', 'No');
    
    % If the user selects 'Yes', execute the action
    if strcmp(choice, 'Yes')
        action();  % Call the action
    end
end