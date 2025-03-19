function PipelineDesigner(varargin)
    % The pipeline designer is a tool to load, modify, and save VERA pipelines

    mfilePath = fileparts(mfilename('fullpath'));

    addpath(genpath(fullfile(mfilePath,'..')));
    addpath(genpath(fullfile(mfilePath,'..','classes')));
    addpath(genpath(fullfile(mfilePath,'..','Components')));
    addpath(genpath(fullfile(mfilePath,'..','Dependencies')));

    % %java stuff to make sure that the GUI works as expected
    warning off
    javaaddpath(fullfile(mfilePath,'..','Dependencies/Widgets Toolbox/resource/MathWorksConsultingWidgets.jar'));
    import uiextras.jTree.*;
    warning on

    if ~isempty(varargin)
        startupPipelineFile = varargin{1};
    else
        startupPipelineFile = [];
    end

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
        'PIPELINE_WIDTH',   520, ...
        'PIPELINE_HEIGHT',  465, ...
        'HELP_AREA_HEIGHT', 243, ...
        'HYPERLINK_WIDTH',  400, ...
        'SPACING',          0 ...
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
        'COMPONENT_LABEL', 250, ...
        'HELP_TEXT',       527, ...
        'HELP_LINK',       468, ...
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
            'WIDTH',  150, ...
            'HEIGHT', 30 ...
        ), ...
        'MOVE_ELEMENT_UP', struct(...
            'X',      545, ...
            'Y',      730, ...
            'WIDTH',  30, ...
            'HEIGHT', 30 ...
        ), ...
        'MOVE_ELEMENT_DOWN', struct(...
            'X',      545, ...
            'Y',      690, ...
            'WIDTH',  30, ...
            'HEIGHT', 30 ...
        ), ...
        'DELETE_ELEMENT', struct(...
            'X',      545, ...
            'Y',      650, ...
            'WIDTH',  30, ...
            'HEIGHT', 30 ...
        ), ...
        'EDITOR_OPEN', struct(...
            'X',      990, ...
            'Y',      490, ...
            'WIDTH',  150, ...
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
    VERAmenu = uimenu(fig, 'Text', 'VERA Tools');
    helpmenu = uimenu(fig, 'Text', 'Help');
    
    %% Create the ListBox for writing pipeline code
     uilabel(fig, ...
        'Position', [UI.X.LEFT_PANEL, UI.Y.TOP, UI.COMMON.LABEL_WIDTH, UI.COMMON.LABEL_HEIGHT], ...
        'Text', 'Pipeline', ...
        'FontName', UI.FONT.REGULAR.NAME, ...
        'FontSize', UI.FONT.REGULAR.SIZE);
    
    % pipelineText = uitextarea(fig, ...
    %     'Position', [0 0 0 0], ...
    %     'Value', '', ...
    %     'FontName', UI.FONT.CODE.NAME, ...
    %     'FontSize', UI.FONT.CODE.SIZE, ...
    %     'Editable', 'on');

    pipelineText.Value = [];

    pipelineListBox = uilistbox(fig, ...
        'Position',  [UI.X.LEFT_PANEL, UI.Y.OUTPUT_LIST, UI.COMMON.PIPELINE_WIDTH, UI.COMMON.PIPELINE_HEIGHT], ...
        'Items',     {''}, ...
        'ItemsData', {}, ...
        'FontName',  UI.FONT.CODE.NAME, ...
        'FontSize',  UI.FONT.CODE.SIZE);

    %% Create the TextArea for modifying component code
    uilabel(fig, ...
        'Position', [UI.X.LEFT_PANEL, UI.Y.COMPONENT_LABEL, UI.COMMON.LABEL_WIDTH, UI.COMMON.LABEL_HEIGHT], ...
        'Text', 'Current Component in Pipeline', ...
        'FontName', UI.FONT.REGULAR.NAME, ...
        'FontSize', UI.FONT.REGULAR.SIZE);

    pipelineElementTextArea = uitextarea(fig, ...
        'Position', [UI.X.LEFT_PANEL, UI.Y.BOTTOM, UI.COMMON.PIPELINE_WIDTH, UI.COMMON.TEXTAREA_HEIGHT], ...
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
        'Text', 'Views', ...
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
    uimenu(filemenu, 'Text', 'Load Pipeline', 'MenuSelectedFcn', @(src, event) loadPipeline(fig,pipelineListBox,pipelineElementTextArea,helpTextArea,helpHyperlink));
    
    %% Create a Save menu button to save the pipeline to a file
    uimenu(filemenu, 'Text', 'Save Pipeline', 'MenuSelectedFcn', @(src, event) savePipeline(fig,pipelineListBox,startupPipelineFile));

    %% Create a clear pipeline menu button
    uimenu(filemenu, 'Text', 'Clear Pipeline', 'MenuSelectedFcn', @(src, event) confirmAction(@() clearPipeline(pipelineListBox,pipelineElementTextArea)));

    %% Create a check pipeline menu button to save the pipeline to a file
    uimenu(VERAmenu, 'Text', 'Check Pipeline', 'MenuSelectedFcn', @(src, event) checkPipeline(fig,pipelineListBox));

    %% Create a pipeline graph menu button to save the pipeline to a file
    uimenu(VERAmenu, 'Text', 'View Pipeline Graph', 'MenuSelectedFcn', @(src, event) viewPipelineGraphInDesigner(fig,pipelineListBox));

    %% Create a help button to link to the wiki
    uimenu(helpmenu, 'Text', 'VERA Wiki', 'MenuSelectedFcn', @(src, event) web('https://github.com/neurotechcenter/VERA/wiki/PipelineDesigner', '-browser'));

    %% Create an Add Component button to move current component to the bottom of the pipeline text area
    uibutton(fig, 'push', 'Text', 'Add Component', ...
        'Position', [UI.BUTTON.ADD_COMPONENT.X, UI.BUTTON.ADD_COMPONENT.Y, ...
                    UI.BUTTON.ADD_COMPONENT.WIDTH, UI.BUTTON.ADD_COMPONENT.HEIGHT], ...
        'FontSize', UI.FONT.REGULAR.SIZE, ...
        'ButtonPushedFcn', @(btn, event) AddElement(fig, pipelineListBox, componentTextArea, pipelineElementTextArea));

    %% Create an Add View button to move current view to the bottom of the pipeline text area
    uibutton(fig, 'push', 'Text', 'Add View', ...
        'Position', [UI.BUTTON.ADD_VIEW.X, UI.BUTTON.ADD_VIEW.Y, ...
                    UI.BUTTON.ADD_VIEW.WIDTH, UI.BUTTON.ADD_VIEW.HEIGHT], ...
        'FontSize', UI.FONT.REGULAR.SIZE, ...
        'ButtonPushedFcn', @(btn, event) AddElement(fig, pipelineListBox, viewTextArea, pipelineElementTextArea));

    %% Create a Move Element Up button
    uibutton(fig, 'push', 'Text', '^', ...
        'Position', [UI.BUTTON.MOVE_ELEMENT_UP.X, UI.BUTTON.MOVE_ELEMENT_UP.Y, ...
                    UI.BUTTON.MOVE_ELEMENT_UP.WIDTH, UI.BUTTON.MOVE_ELEMENT_UP.HEIGHT], ...
        'FontSize', UI.FONT.REGULAR.SIZE, ...
        'ButtonPushedFcn', @(btn, event) MoveElementUp(pipelineListBox,pipelineElementTextArea));

    %% Create a Move Element Down button
    uibutton(fig, 'push', 'Text', 'v', ...
        'Position', [UI.BUTTON.MOVE_ELEMENT_DOWN.X, UI.BUTTON.MOVE_ELEMENT_DOWN.Y, ...
                    UI.BUTTON.MOVE_ELEMENT_DOWN.WIDTH, UI.BUTTON.MOVE_ELEMENT_DOWN.HEIGHT], ...
        'FontSize', UI.FONT.REGULAR.SIZE, ...
        'ButtonPushedFcn', @(btn, event) MoveElementDown(pipelineListBox,pipelineElementTextArea));

    %% Create a Delete Element button
    uibutton(fig, 'push', 'Text', 'x', ...
        'Position', [UI.BUTTON.DELETE_ELEMENT.X, UI.BUTTON.DELETE_ELEMENT.Y, ...
                    UI.BUTTON.DELETE_ELEMENT.WIDTH, UI.BUTTON.DELETE_ELEMENT.HEIGHT], ...
        'FontSize', UI.FONT.REGULAR.SIZE, ...
        'ButtonPushedFcn', @(btn, event) DeleteElement(pipelineListBox,pipelineElementTextArea));
    
    %% On startup either display empty pipeline or pipeline of current VERA project
    if ~isempty(startupPipelineFile)
        loadPipeline(fig,pipelineListBox,pipelineElementTextArea,helpTextArea,helpHyperlink,startupPipelineFile);
    else
        clearPipeline(pipelineListBox,pipelineElementTextArea);
    end

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

    %% Modify current pipeline when changing elements of current pipeline component
    pipelineElementTextArea.ValueChangedFcn = @(src,event)...
        modifyCurrentPipelineElement(fig,pipelineElementTextArea,pipelineListBox);

    %% Populate currently selected element of pipeline
    % Update view window to display current component
    pipelineListBox.ValueChangedFcn = @(src,event)...
        viewElementOfPipeline(pipelineElementTextArea, pipelineListBox,helpTextArea,helpHyperlink);

    %% Create button to open component/view code in MATLAB editor
    selectedElement = '';

    addlistener(availableInputComponentsListBox,      'ValueChanged', @(src,event) updateSelectedElement(src));
    addlistener(availableProcessingComponentsListBox, 'ValueChanged', @(src,event) updateSelectedElement(src));
    addlistener(availableOutputComponentsListBox,     'ValueChanged', @(src,event) updateSelectedElement(src));
    addlistener(availableViewsListBox,                'ValueChanged', @(src,event) updateSelectedElement(src));
    addlistener(pipelineListBox,                      'ValueChanged', @(src,event) updateSelectedElement_fromPipeline(src));

    uibutton(fig, 'push', 'Text', 'Open in Editor', ...
        'Position', [UI.BUTTON.EDITOR_OPEN.X, UI.BUTTON.EDITOR_OPEN.Y, ...
                    UI.BUTTON.EDITOR_OPEN.WIDTH, UI.BUTTON.EDITOR_OPEN.HEIGHT], ...
        'FontSize', UI.FONT.REGULAR.SIZE, ...
        'ButtonPushedFcn', @(btn, event) OpenInEditor(fig));

    % Function to open the most recent file (active in help text area) in the matlab editor
    function OpenInEditor(fig,~)
        if exist(selectedElement, 'file') == 2
            edit(selectedElement);
        else
            % Display a warning if the file does not exist
            uialert(fig, ['File "', selectedElement, '" does not exist.'], 'File Not Found');
        end
    end
    
    function updateSelectedElement(src,~)
        selectedElement = src.Value;
    end

    function updateSelectedElement_fromPipeline(src,~)
        selectedElement_cell = getElementTypes({src.Value});
        selectedElement      = selectedElement_cell{1};
    end

end

%% Function to load pipeline from a file
function loadPipeline(fig,pipelineListBox,pipelineElementTextArea,helpTextArea,helpHyperlink,varargin)
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
                pipelineContent{i} = '';
            end
        end

        % replace tabs with spaces
        for i = 1:length(pipelineContent)
            pipelineContent{i} = regexprep(pipelineContent{i}, '\t', '    ');
        end

        % Populate pipeline listbox and element text area
        [compNames, viewNames, elements] = getCurrentComponents(pipelineContent);

        pipelineListBox.Items     = [compNames'; viewNames'];
        pipelineListBox.ItemsData = elements;

        pipelineElementTextArea.Value = elements{1};

        % show help of selected element
        % Need element type to show help
        elementType = getElementTypes({pipelineListBox.ItemsData{1}});
        [dependencies, optionalDependencies] = getDependencies(elementType{1});
        showHelp(helpTextArea,helpHyperlink,elementType{1},dependencies,optionalDependencies);
    else
        uialert(fig, 'Error reading the file.', 'File Error');
    end
end

%% Function to save pipeline to a file
function [fullPath] = savePipeline(fig,pipelineListBox,startupPipelineFile,varargin)
    fullPath = [];

    % if there is an input file given, assume it comes from the
    % checkPipeline function. This is used to avoid recursively checking
    % the pipeline when using the 'check pipeline' file dialog
    if nargin > 3
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
        pipelineStatus = checkPipeline(fig,pipelineListBox);
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
            if ~isempty(startupPipelineFile)
                [file, path] = uiputfile(startupPipelineFile, 'Save pipeline file');
            else
                [file, path] = uiputfile(fullfile(defaultSavePath,'*.pwf'), 'Save pipeline file');
            end
        end
        fig.Visible = 'on'; % Show the main window

        % write text area to file
        if file ~= 0

            pipelineName = file;
            pipelineText = createPipeline(pipelineListBox,pipelineName);

            fullPath = fullfile(path, file);
            fid = fopen(fullPath, 'wt');
            if fid ~= -1
                for i = 1:length(pipelineText)
                    fprintf(fid, [pipelineText{i},'\n']);
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
function clearPipeline(pipelineListBox, pipelineComponentTextArea)
    pipelineListBox.Items           = {''};
    pipelineListBox.ItemsData       = {''};
    pipelineComponentTextArea.Value = '';
end

%% Function to create the pipeline text from the pipelineListBox
function pipelineText = createPipeline(pipelineListBox, pipelineName)
    pipelineText = {'<?xml version="1.0" encoding="utf-8"?>';
                    ['<PipelineDefinition Name="',pipelineName,'">'];
                    '    '
                    };
    
    for i = 1:length(pipelineListBox.ItemsData)
        pipelineText = [pipelineText;
                        pipelineListBox.ItemsData{i};
                        '    '
                        ];
    end
    
    pipelineText = [
                    pipelineText;
                    '</PipelineDefinition>'
                    ];

end

%% Function to check the validity of the pipeline
function pipelineStatus = checkPipeline(fig,pipelineListBox)

    warnMsg_create    = [];
    warnMsg_configure = [];
    errormessage      = [];

    checkingPipelineDlg = uiprogressdlg(fig,'Message','Checking Pipeline...','Title','Checking Pipeline',...
    'Icon','error','Cancelable','on','Indeterminate','on');

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
    pipelinePath     = savePipeline(fig,pipelineListBox,[],tempPipelinePath);


    % start VERA (would like to change this so pipelines can be checked
    % without running VERA...)
    VERAvisiblity = 'off';
    VERAhandle    = MainGUI(VERAvisiblity);

    % Sort through existing figures and hide the newest VERA figure (used
    % for checking the pipeline)
    % This preserves any open VERA windows
    allFigureHandles = findall(groot,'Type','figure');
    for i = 1:length(allFigureHandles)
        FigureNames{i} = allFigureHandles(i).Name;
    end
    for i = 1:length(FigureNames)
        if contains(FigureNames{i},'VERA')
            FigureNumbers(i) = allFigureHandles(i).Number;
        else
            FigureNumbers(i) = 0;
        end
    end

    [~,VERAfigIDX] = max(FigureNumbers);

    VERAfig = allFigureHandles(VERAfigIDX);

    % Create dialog boxes when there are warnings or errors
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

    % close VERA
    close(VERAfig);

    % delete temporary folder
    warning off;
    rmdir(fullfile(tempProjPath,'..'),'s');
    warning on;

    close(checkingPipelineDlg);
end

% reformat matlab warning for nicer display in warn dialog box
function warnMsg = formatWarning()
    warnMsg = lastwarn;

    if ~isempty(warnMsg)
        % isolate meaningful message
        [warnMsg, matches] = strsplit(warnMsg,{'Error','</a>'});

        % Find the name of the element causing the error
        elementNameStart = find(contains(warnMsg,'errorDocCallback'),1,'first');
        regexpString =  "(?<=\(')([^']+)(?='\))";
        elementName = regexp(warnMsg(elementNameStart),regexpString,'match');

        start   = find(contains(matches,'</a>'),1,'first') + 1;
        if ~isempty(start)
            warnMsg = warnMsg{start};
        end

        % remove return lines in warning
        warnMsg = regexprep(warnMsg,'[\n\r]+',' ');

        % remove leading space
        if isspace(warnMsg(1))
            warnMsg(1) = [];
        end

        if ~isempty(elementName)
            warnMsg = [elementName{1}{1}, ': ', warnMsg];
        end
    end
end

%% Function to view the pipeline graph
function viewPipelineGraphInDesigner(fig, pipelineListBox)
    
    % check pipeline
    pipelineStatus = checkPipeline(fig,pipelineListBox);

    if pipelineStatus
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
        pipelinePath     = savePipeline(fig,pipelineListBox,[],tempPipelinePath);
    
        % start VERA (would like to change this so pipelines can be checked
        % without running VERA...)
        VERAvisiblity    = 'off';
        VERAhandle       = MainGUI(VERAvisiblity);
        allFigureHandles = findall(groot,'Type','figure');
        VERAfig          = allFigureHandles(end);

        % Create a VERA project so we can view the pipeline graph. In
        % theory this could be done without creating a project, but I don't
        % know how
        createNewProject(VERAhandle,tempProjPath,pipelinePath);

        % Create the pipeline graph
        viewPipelineGraph(VERAhandle);

        % close the VERA figure window (hidden)
        close(VERAfig);

    end
end

%% Function to get all components/views in a given directory
function [Names, componentTypes] = getAvailableElements(dirPath,parentClasses,compOrView)

    Names          = {};
    componentTypes = {};

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

%% Function to get component names/types for the current pipeline
function [compNames, viewNames, elements] = getCurrentComponents(pipelineText)
    % Initialize variables
    compNames      = {};
    componentTypes = {};
    viewNames      = {};
    viewTypes      = {};
    
    % Process components and views
    componentStart = [];
    componentEnd   = [];
    viewStart      = [];
    viewEnd        = [];
    compHasName    = [];
    viewHasName    = [];
    
    % Loop through the pipelineText once and collect data
    for i = 1:size(pipelineText, 1)
        line = pipelineText{i};
        
        % Check for components
        if contains(line, '<Component Type="')
            componentStart(end + 1) = i;
            matches = regexp(line, '<Component Type="([^"]+)"', 'tokens');
            if ~isempty(matches)
                componentTypes{end + 1} = matches{1}{1};
            end

            if contains(line,'/>')
                componentEnd(end + 1) = i;
            end

        elseif contains(line, '</Component>')
            componentEnd(end + 1) = i;
        end

    
        % Check for views
        if contains(line, '<View Type="')
            viewStart(end + 1) = i;
            matches = regexp(line, '<View Type="([^"]+)"', 'tokens');
            if ~isempty(matches)
                viewTypes{end + 1} = matches{1}{1};
            end

            if contains(line,'/>')
                viewEnd(end + 1) = i;
            end

        elseif contains(line, '</View>')
            viewEnd(end + 1) = i;
        end
    end
    
    % Extract component names
    for i = 1:length(componentStart)
        compHasName(i) = false;
        for j = componentStart(i):componentEnd(i)
            if contains(pipelineText{j}, '<Name>"')
                compHasName(i) = true;
                matches = regexp(pipelineText{j}, '<Name>"([^"]+)"', 'tokens');
                if ~isempty(matches)
                    compNames{end + 1} = matches{1}{1};
                end
            end
        end
        
        % If no name is found, use the type as the name
        if ~compHasName(i)
            compNames{end + 1} = componentTypes{i};
        end
    end
    
    % Extract view names
    for i = 1:length(viewStart)
        viewHasName(i) = false;
        for j = viewStart(i):viewEnd(i)
            if contains(pipelineText{j}, '<Name>"')
                viewHasName(i) = true;
                matches = regexp(pipelineText{j}, '<Name>"([^"]+)"', 'tokens');
                if ~isempty(matches)
                    viewNames{end + 1} = matches{1}{1};
                end
            end
        end
        
        % If no name is found, use the type as the name
        if ~viewHasName(i)
            viewNames{end + 1} = viewTypes{i};
        end
    end 

    % Create struct of components and views
    elementStart = sort([componentStart, viewStart]);
    elementEnd   = sort([componentEnd,   viewEnd]);
    for i = 1:length(elementStart)
        elements{i} = pipelineText(elementStart(i):elementEnd(i));
    end

end

%% Function to get names from elements structure
function elementNames = getElementNames(elements)

    elementNames = {''};
    
    % sort through elements to find name. If there is no name, use the
    % element type as name
    for i = 1:length(elements)
        for j = 1:length(elements{i})
            if contains(elements{i}{j},'<Name>')
                matches = regexp(elements{i}{j}, '<Name>"([^"]+)"', 'tokens');
                if ~isempty(matches)
                    elementNames{i} = matches{1}{1};
                end
            else
                if contains(elements{i}{j},'<Component Type=')
                    matches = regexp(elements{i}{j}, '<Component Type="([^"]+)"', 'tokens');
                    if ~isempty(matches)
                        elementNames{i} = matches{1}{1};
                    end
                elseif contains(elements{i}{j},'<View Type=')
                    matches = regexp(elements{i}{j}, '<View Type="([^"]+)"', 'tokens');
                    if ~isempty(matches)
                        elementNames{i} = matches{1}{1};
                    end
                end
            end
        end
    end

end

%% Function to get element types
function elementTypes = getElementTypes(elements)

    elementTypes = {''};
    
    % sort through elements to find type
    for i = 1:length(elements)
        for j = 1:length(elements{i})
            if contains(elements{i}{j},'<Component Type=')
                matches = regexp(elements{i}{j}, '<Component Type="([^"]+)"', 'tokens');
                if ~isempty(matches)
                    elementTypes{i} = matches{1}{1};
                end
            elseif contains(elements{i}{j},'<View Type=')
                matches = regexp(elements{i}{j}, '<View Type="([^"]+)"', 'tokens');
                if ~isempty(matches)
                    elementTypes{i} = matches{1}{1};
                end
            end
        end
    end

end

%% Function to inspect the properties of a component or view selected in the pipeline
function viewElementOfPipeline(textArea,pipelineListBox,helpTextArea,helpHyperlink)

    textArea.Value = pipelineListBox.Value;

    % show help of selected element
    % Need element type to show help
    elementType = getElementTypes({pipelineListBox.Value});
    [dependencies, optionalDependencies] = getDependencies(elementType{1});
    showHelp(helpTextArea,helpHyperlink,elementType{1},dependencies,optionalDependencies);
    
end

%% Function to modify current pipeline when modifying pipeline element text area
function modifyCurrentPipelineElement(fig,pipelineElementTextArea,pipelineListBox)

    % Testing functionality to check element formatting
    [isValid, errormsg] = testHTMLFormat(pipelineElementTextArea.Value);
    if ~isValid
        uialert(fig,[errormsg, ' Stored anyway, but be cautious.'], 'Warning')
    end

    % Find currently selected item in ItemsData
    for i = 1:length(pipelineListBox.ItemsData)
        if isequaln(pipelineListBox.ItemsData{i},pipelineListBox.Value)
            index = i;
        end
    end

    % Check if name has been changed to be a duplicate
    elementName  = getElementNames({pipelineElementTextArea.Value});

    pipelineListBox.Items{index} = char(floor(26*rand(1, 20)) + 65);

    isDuplicated = checkforDuplicateNames(pipelineListBox.Items,elementName);

    pipelineListBox.ItemsData{index} = pipelineElementTextArea.Value;
    pipelineListBox.Value            = pipelineListBox.ItemsData{index}; 
    pipelineListBox.Items            = getElementNames(pipelineListBox.ItemsData);
    
    if isDuplicated
        uialert(fig, 'Error: Duplicate Names. Elements cannot have the same name.', 'Duplicate Names');
        
        % set item to unavailable name
        pipelineListBox.Items{index}     = [elementName{1}, ' - Cannot have duplicate name!'];
    end
end

%% Function to move element up in listbox and in pipeline text
function MoveElementUp(pipelineListBox,pipelineElementTextArea)

    % Find currently selected item in ItemsData
    for i = 1:length(pipelineListBox.ItemsData)
        if isequaln(pipelineListBox.ItemsData{i},pipelineListBox.Value)
            index = i;
        end
    end

    if size(pipelineListBox.Items,2) > 1
        newOrder = 1:length(pipelineListBox.Items);
        if index ~= 1
            idx1 = index;
            idx2 = index-1;
        else
            idx1 = index;
            idx2 = index;
        end
        
        % Perform the swap
        temp = newOrder(idx1);
        newOrder(idx1) = newOrder(idx2);
        newOrder(idx2) = temp;
        

        pipelineListBox.Items     = pipelineListBox.Items(newOrder);
        pipelineListBox.ItemsData = pipelineListBox.ItemsData(newOrder);

    end

    pipelineElementTextArea.Value = pipelineListBox.Value;

end

%% Function to move element down in listbox and in pipeline text
function MoveElementDown(pipelineListBox,pipelineElementTextArea)

    % Find currently selected item in ItemsData
    for i = 1:length(pipelineListBox.ItemsData)
        if isequaln(pipelineListBox.ItemsData{i},pipelineListBox.Value)
            index = i;
        end
    end

    if size(pipelineListBox.Items,2) > 1
        newOrder = 1:length(pipelineListBox.Items);
        if index ~= length(pipelineListBox.Items)
            idx1 = index;
            idx2 = index+1;
        else
            idx1 = index;
            idx2 = index;
        end
        
        % Perform the swap
        temp = newOrder(idx1);
        newOrder(idx1) = newOrder(idx2);
        newOrder(idx2) = temp;
        
        pipelineListBox.Items     = pipelineListBox.Items(newOrder);
        pipelineListBox.ItemsData = pipelineListBox.ItemsData(newOrder);

    end

    pipelineElementTextArea.Value = pipelineListBox.Value;
end

%% Function to remove an element from the listbox and pipeline text
function DeleteElement(pipelineListBox,pipelineElementTextArea)

    % Find currently selected item in ItemsData
    for i = 1:length(pipelineListBox.ItemsData)
        if isequaln(pipelineListBox.ItemsData{i},pipelineListBox.Value)
            index = i;
        end
    end

    if size(pipelineListBox.Items,2) > 1
        pipelineListBox.Items(index)     = [];
        pipelineListBox.ItemsData(index) = [];
        if index > 1
            pipelineListBox.Value = pipelineListBox.ItemsData{index-1};
        else
            pipelineListBox.Value = pipelineListBox.ItemsData{index};
        end
    else
        pipelineListBox.Items     = {''};
        pipelineListBox.ItemsData = {};
    end

    pipelineElementTextArea.Value = pipelineListBox.Value;
end

%% Function to inspect the properties of a component selected in the listbox
function viewComponent(textArea,helpArea,helpHyperlink,parentClass,currentComponent)
    [~,componentName] = fileparts(currentComponent);
    component = eval(componentName);

    % Get the component type
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

    % Remove dependent properties as both cannot be used in the component
    % e.g. MRIIdentifer and CoregistrationIdentifier in Coregistration.m
    mc = metaclass(component);
    remDependentIDX = [];
    iter = 1;
    for i = 1:length(mc.PropertyList)
        prop = mc.PropertyList(i);
        if prop.Dependent && any(ismember(uniqueComponentProperties,prop.Name)) &&...
                (strcmp(prop.GetAccess, 'public') || strcmp(prop.SetAccess, 'public'))
            remDependentIDX(iter) = i;
            iter = iter + 1;
        end
    end
    uniqueComponentProperties(ismember(uniqueComponentProperties,props(remDependentIDX))) = [];

    % Start building the XML string
    textArea.Value      = {''};
    textArea.Value{1,1} = [sprintf('<Component Type="%s">', componentType)];

    % Loop through the properties and add them to the XML string
    for i = 1:length(uniqueComponentProperties)
        % Get the property value
        propValue = component.(uniqueComponentProperties{i});

        % Convert the property value to a string if it's not already
        if ischar(propValue) && isempty(propValue)
            propValue = '""';

        elseif isnumeric(propValue) && isempty(propValue)
            propValue = '[]';

        elseif iscell(propValue) && isempty(propValue)
            propValue = '[""]';

        elseif ischar(propValue) || isstring(propValue)
            propValue = sprintf('"%s"', propValue);

        elseif isnumeric(propValue) && length(propValue) > 1
            
            % build a bracketed vector
            propValue_holder = '[';
            for j = 1:length(propValue)
                propValue_holder = [propValue_holder, sprintf('%g', propValue(j)), ',']; 
            end
            propValue_holder(end) = []; % remove trailing comma
            propValue_holder      = [propValue_holder,']'];

            propValue = propValue_holder;

        elseif isnumeric(propValue)
            propValue = sprintf('%g', propValue);

        elseif islogical(propValue)
            propValue = sprintf('"%s"', mat2str(propValue));

        elseif iscell(propValue) && length(propValue) > 1

            % build a bracketed array if more than 1 element
            propValue_holder = '[';
            for j = 1:length(propValue)
                propValue_holder = [propValue_holder, sprintf('"%s"', propValue{j}), ',']; 
            end
            propValue_holder(end) = []; % remove trailing comma
            propValue_holder      = [propValue_holder,']'];

            propValue = propValue_holder;

        elseif iscell(propValue)
            propValue = sprintf('"%s"', propValue{1}); 

        else
            propValue = '""';  % For unsupported or complex types
        end

        % Add property to XML (with the property name as the tag)
        textArea.Value{i+1,1} = [sprintf('    <%s>%s</%s>', uniqueComponentProperties{i}, propValue, uniqueComponentProperties{i})];
    end

    % Close the component and XML structure
    textArea.Value{end+1,1} = '</Component>';

    % show help of selected component
    [dependencies, optionalDependencies] = getDependencies(componentName);
    showHelp(helpArea,helpHyperlink,currentComponent,dependencies,optionalDependencies);
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

    % Remove dependent properties as both cannot be used in the component
    % e.g. MRIIdentifer and CoregistrationIdentifier in Coregistration.m
    mc = metaclass(view);
    remDependentIDX = [];
    iter = 1;
    for i = 1:length(mc.PropertyList)
        prop = mc.PropertyList(i);
        if prop.Dependent && any(ismember(uniqueViewProperties,prop.Name)) &&...
                (strcmp(prop.GetAccess, 'public') || strcmp(prop.SetAccess, 'public'))
            remDependentIDX(iter) = i;
            iter = iter + 1;
        end
    end
    uniqueViewProperties(ismember(uniqueViewProperties,props(remDependentIDX))) = [];

    % Start building the XML string
    textArea.Value      = {''};
    textArea.Value{1,1} = [sprintf('<View Type="%s">', viewType)];

    % Loop through the properties and add them to the XML string
    for i = 1:length(uniqueViewProperties)
        % Get the property value
        propValue = view.(uniqueViewProperties{i});

        % Convert the property value to a string if it's not already
        if isempty(propValue)
            propValue = '""';

        elseif ischar(propValue) || isstring(propValue)
            propValue = sprintf('"%s"', propValue);

        elseif isnumeric(propValue) && length(propValue) > 1
            
            % build a bracketed vector
            propValue_holder = '[';
            for j = 1:length(propValue)
                propValue_holder = [propValue_holder, sprintf('%g', propValue(j)), ',']; 
            end
            propValue_holder(end) = []; % remove trailing comma
            propValue_holder      = [propValue_holder,']'];

            propValue = propValue_holder;

        elseif isnumeric(propValue)
            propValue = sprintf('%g', propValue);

        elseif islogical(propValue)
            propValue = sprintf('"%s"', mat2str(propValue));

        elseif iscell(propValue) && length(propValue) > 1

            % build a bracketed array if more than 1 element
            propValue_holder = '[';
            for j = 1:length(propValue)
                propValue_holder = [propValue_holder, sprintf('"%s"', propValue{j}), ',']; 
            end
            propValue_holder(end) = []; % remove trailing comma
            propValue_holder      = [propValue_holder,']'];

            propValue = propValue_holder;

        elseif iscell(propValue)
            propValue = sprintf('"%s"', propValue{1}); 

        else
            propValue = '""';  % For unsupported or complex types
        end

        % Add property to XML (with the property name as the tag)
        textArea.Value{i+1,1} = [sprintf('    <%s>%s</%s>', uniqueViewProperties{i}, propValue, uniqueViewProperties{i})];
    end

    % Close the view and XML structure
    textArea.Value{end+1,1} = '</View>';

    % show help of selected view
    [dependencies, optionalDependencies] = getDependencies(viewName);
    showHelp(helpArea,helpHyperlink,currentView,dependencies,optionalDependencies);

end

%% Help function to display help text
function showHelp(helpTextArea,helpHyperlink,element,dependencies,optionalDependencies)
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

    % add dependencies to help text
    helpText = [helpText, newline, 'Dependencies: ', newline];
    if ~isempty(dependencies)
        dependenciesFormatted = [];
        for i = 1:length(dependencies)
            dependenciesFormatted = [dependenciesFormatted, dependencies{i}, newline];
        end
        helpText = [helpText, dependenciesFormatted];
    else
        helpText = [helpText, 'none', newline];
    end

    % add optional dependencies to help text
    helpText = [helpText, newline, 'Optional Dependencies: ', newline];
    if ~isempty(optionalDependencies)
        optDependenciesFormatted = [];
        for i = 1:length(optionalDependencies)
            optDependenciesFormatted = [optDependenciesFormatted, optionalDependencies{i}, newline];
        end
        helpText = [helpText, optDependenciesFormatted];
    else
        helpText = [helpText, 'none'];
    end

    % write help text to helpTextArea
    helpTextArea.Value = helpText;

    helpHyperlink.Text    = element;
    helpHyperlink.URL     = ['https://github.com/neurotechcenter/VERA/wiki/', element];
    helpHyperlink.Tooltip = helpHyperlink.URL;

end

%% Function to move component or view to pipeline
function AddElement(fig,pipelineListBox,elementText,pipelineElementTextArea)

    elementNames       = getElementNames(pipelineListBox.ItemsData);
    currentElementName = getElementNames({pipelineListBox.Value});
    elementToAddName   = getElementNames({elementText.Value});

    % Throw an error if there are duplicated elements
    isDuplicated = checkforDuplicateNames(elementNames,elementToAddName{1});
    if isDuplicated
        uialert(fig, 'Error: Duplicate Names. Elements cannot have the same name.', 'Duplicate Names');
    else
        % Testing functionality to check element formatting
        [isValid, errormsg] = testHTMLFormat(elementText.Value);
        if ~isValid
            uialert(fig,[errormsg, ' Added anyway, but be cautious.'], 'Warning')
        end

        % Get index of currently selected element in pipeline ListBox
        currentIDX = find(strcmp(elementNames,currentElementName),1);
        
        % Update Items in listbox
        pipelineListBox.Items = [
                                 pipelineListBox.Items{1:currentIDX},...
                                 elementToAddName,...
                                 pipelineListBox.Items{currentIDX+1:length(pipelineListBox.Items)}
                                 ];

        % Update data associated with items
        if size(pipelineListBox.Items,2) > 1
            pipelineListBox.ItemsData = {
                                         pipelineListBox.ItemsData{1:currentIDX},...
                                         elementText.Value,...
                                         pipelineListBox.ItemsData{currentIDX+1:length(pipelineListBox.ItemsData)}
                                         };

            % Update value so added component is selected in listbox
            pipelineListBox.Value = pipelineListBox.ItemsData{currentIDX+1};
        else
            pipelineListBox.ItemsData = {elementText.Value};

            % Update value so added component is selected in listbox
            pipelineListBox.Value = pipelineListBox.ItemsData{currentIDX};
        end

        % Update working component text area
        pipelineElementTextArea.Value = elementText.Value;
    
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

% Function to extract inputs and outputs of a component
function [inputs, outputs] = extractInputsOutputs(className)
    % A better approach will be to look at
    % classInfo.PropertyList

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
    inputs  = parseMatchedString(inputsMatch);
    outputs = parseMatchedString(outputsMatch);

    optionalInputs  = parseMatchedString(optionalInputsMatch);
    optionalOutputs = parseMatchedString(optionalOutputsMatch);

    inputs  = [inputs,  optionalInputs];
    outputs = [outputs, optionalOutputs];
end

%% This function gets the dependencies necessary to run a component
function [dependencies, optionalDependencies] = getDependencies(className)
% This function extracts the necessary dependencies of a component

% Check if the class exists
    if ~exist('className', 'var') || ~ischar(className)
        error('Class name must be a valid string');
    end
    
    dependencies         = {};
    optionalDependencies = {};
    
    % Get the class definition
    classInfo = meta.class.fromName(className);
    
    % Iterate through the class methods
    for i = 1:length(classInfo.MethodList)
        methodName = classInfo.MethodList(i).Name;
        
        % Check for GetDependency calls
        if strcmp(methodName, 'Initialize')
            % Look at the GetDependency method to get inputs and outputs
            [dependencies, optionalDependencies] = extractDependencies(className);
        end
        
    end

end

% Function to extract dependencies of a component
function [dependencies, optionalDependencies] = extractDependencies(className)
    % Check for calls to GetDependency in the method body
    filePath   = which([className '.m']);
    methodCode = fileread(filePath);
    
    % Regular expression to find GetDependency calls
    getDependencyPattern = 'obj.GetDependency\((.*?)\);';
    reqDependencyPattern = 'obj.RequestDependency\((.*?)\);';
    optDependencyPattern = 'obj.GetOptionalDependency\((.*?)\);';

    % Extract dependencies
    getDependenciesMatch = regexp(methodCode, getDependencyPattern, 'match');
    reqDependenciesMatch = regexp(methodCode, reqDependencyPattern, 'match');
    optDependenciesMatch = regexp(methodCode, optDependencyPattern, 'match');
    
    % Parse the matched results
    dependencies_get = parseMatchedString(getDependenciesMatch);
    dependencies_req = parseMatchedString(reqDependenciesMatch);
    dependencies_opt = parseMatchedString(optDependenciesMatch);

    % This is needed because I am not actually searching the GetDependency
    % Method, but the entire component code
    dependencies = [dependencies_get, dependencies_req];
    dependencies = unique(dependencies);

    optionalDependencies = unique(dependencies_opt);

    % add a note that UbuntuSubsystemPath is a dependency on Windows only
    dependencies(strcmp(dependencies,'''UbuntuSubsystemPath'''))                 = {'''UbuntuSubsystemPath (Windows)'''};
    optionalDependencies(strcmp(optionalDependencies,'''UbuntuSubsystemPath''')) = {'''UbuntuSubsystemPath (Windows)'''};

    % TempPath should always be available, so it is not really an external dependency
    dependencies(strcmp(dependencies,'''TempPath'''))                 = [];
    optionalDependencies(strcmp(optionalDependencies,'''TempPath''')) = [];

end

%% Function to parse the component for the matched string
function result = parseMatchedString(matches)
    % Parse the AddInput/Output calls into structured results
    result = {};
    
    for i = 1:length(matches)
        match      = matches{i};
        parts      = strsplit(match, '(');
        object     = strsplit(parts{2},',');
        object     = strsplit(object{1},')');
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

%% Function to ensure there are no duplicate names of components or views
function isDuplicated = checkforDuplicateNames(elementList,currentElement)
    isDuplicated = 0;
    for i = 1:size(elementList,2)
        if strcmp(elementList{i},currentElement)
            isDuplicated = 1;
        end
    end
end

%% Functions to test if component text is formatted correctly
function [isValid,msg] = testHTMLFormat(inputStr)
    % Initialize the output to true (assuming valid)
    isValid = true;
    msg     = [];
    
    % Clean up input string (remove unnecessary newlines and excess spaces)
    inputStr = strtrim(inputStr);  % Trim any leading/trailing spaces
    
    % Check for matching opening and closing tags
    isValid = checkTagStructure(inputStr);
    if ~isValid
        msg = 'Error: Mismatched or missing attribute names.';
        % disp(msg);
        return;
    end
    
    % Check for properly quoted attributes (handles multiline attributes)
    isValid = checkAttributeQuotes(inputStr);
    if ~isValid
        msg = 'Error: Missing or mismatched quotation marks or brackets around attribute values.';
        % disp(msg);
        return;
    end
    
end

function isValid = checkTagStructure(inputStr)
    % This function checks that opening and closing tags are properly paired and nested
    isValid = true;
    tagStack = {};  % Stack to keep track of opening tags
    
    % Regular expression to match all tags (including multi-line tags)
    tagPattern = '<\s*(\/?\s*\w+)\s*[^>]*>';
    
    % Extract all matched tags (opening and closing tags)
    tags = regexp(inputStr, tagPattern, 'tokens');
    
    for i = 1:length(tags)
        for j = 1:length(tags{i})
            tag = tags{i}{j};
            
            if contains(tag, '/')  % Closing tag
                if isempty(tagStack)
                    isValid = false;
                    return;
                end
                lastTag = tagStack{end};
                if ~strcmp(tag{1}(2:end), lastTag{1})
                    isValid = false;
                    return;
                end
                tagStack(end) = [];  % Pop the last tag
            else  % Opening tag
                tagStack{end+1} = tag;  % Push the tag onto the stack
            end
        end
    end
    
    % If the stack is not empty, there are unmatched opening tags
    if ~isempty(tagStack)
        isValid = false;
    end
end

function isValid = checkAttributeQuotes(inputStr)
    % This function checks that attribute values are properly quoted ("" or
    % '') and bracketed ([ ])
    isValid = true;

    attrPattern = '(?<=[=])\s*([^<>\s]+)(?=>)|(?<=>)\s*([^<>\s]+)(?=<)';
    
    % Extract all matched attributes
    attrs = regexp(inputStr, attrPattern, 'tokens');
    
    % Loop over all matched attributes and ensure correct quoting
    for i = 1:length(attrs)
        if ~isempty(attrs{i})
            attr = attrs{i}{1}{1};

            % if it starts with a quote it needs to end with a quote
            if strcmp(attr(1),'"') && ~strcmp(attr(end),'"')
                isValid = false;
                return;
            end

            % if it ends with a quote it needs to start with a quote
            if strcmp(attr(end),'"') && ~strcmp(attr(1),'"')
                isValid = false;
                return;
            end

            % if it starts with a bracket it needs to end with a bracket
            if strcmp(attr(1),'[') && ~strcmp(attr(end),']')
                isValid = false;
                return;
            end
            % if it ends with a bracket it needs to start with a bracket
            if strcmp(attr(end),']') && ~strcmp(attr(1),'[')
                isValid = false;
                return;
            end

            % if line starts and ends with bracket, investigate sub attributes
            if strcmp(attr(1), '[') && strcmp(attr(end), ']')
                
                attrSubPattern = '(?<=\[|,)([^,]+)(?=\]|,)';
                attrSubStrings = regexp(attr, attrSubPattern, 'match');

                for j = 1:length(attrSubStrings)
                    % if it starts with a quote it needs to end with a quote
                    if strcmp(attrSubStrings{j}(1),'"') && ~strcmp(attrSubStrings{j}(end),'"')
                        isValid = false;
                        return;
                    end
        
                    % if it ends with a quote it needs to start with a quote
                    if strcmp(attrSubStrings{j}(end),'"') && ~strcmp(attrSubStrings{j}(1),'"')
                        isValid = false;
                        return;
                    end
                end

            end

            if isempty(attr)
                isValid = false;
                return;
            end
        end
    end
end

