function PipelineDesigner(varargin)
    % The pipeline designer is a tool to load, modify, and save VERA pipelines
    mfilePath = fileparts(mfilename('fullpath'));

    if ~isdeployed
        addpath(genpath(fullfile(mfilePath,'..')));
        % The line above sweeps in the whole repo root, including
        % StandaloneBuild/build/ - a compiled app's Contents/Resources/
        % *_mcr cache mirrors the original source tree's folder names
        % (e.g. classes/GUI/waitbar.m) but those files are p-coded/
        % encrypted, not real text. If which('waitbar','-all') picks one
        % of those up as its 2nd (non-VERA-shadow) match, classes/GUI/
        % waitbar.m's non-deployed fallback tries to load it as source
        % and fails with "Invalid text character" - confirmed via a real
        % user report reproducing exactly this. Strip it back out here
        % rather than removing the broad genpath above, in case something
        % else at the repo root is actually relied upon.
        standaloneBuildDir = fullfile(mfilePath,'..','StandaloneBuild');
        if exist(standaloneBuildDir,'dir')
            rmpath(genpath(standaloneBuildDir));
        end
        addpath(genpath(fullfile(mfilePath,'..','classes')));
        addpath(genpath(fullfile(mfilePath,'..','Components')));
        addpath(genpath(fullfile(mfilePath,'..','Dependencies')));
    end

    % %java stuff to make sure that the GUI works as expected
    warning off
    if ~isdeployed
        javaaddpath(fullfile(mfilePath,'..','Dependencies/Widgets Toolbox/resource/MathWorksConsultingWidgets.jar'));
    end
    import uiextras.jTree.*;
    warning on

    % Build-time-only mode: MATLAB Compiler bundles every .m file as
    % encrypted p-code, so fileread() on a component's own source (used
    % throughout this file to discover components/views and extract
    % their inputs/outputs/dependencies/help text via regex) returns
    % garbage in the deployed app. This mode runs in normal MATLAB before
    % compiling, while source is still readable, and precomputes
    % everything into a manifest file that the deployed app loads instead
    % of scanning source at runtime. See loadManifestOnce/getAvailableElements/
    % getDependencies/getInputsOutputs/showHelp for the deployed-mode side.
    if ~isempty(varargin) && ischar(varargin{1}) && strcmp(varargin{1},'BuildManifest')
        buildPipelineDesignerManifest(mfilePath, varargin{2});
        return;
    end

    if ~isempty(varargin)
        startupPipelineFile = varargin{1};
    else
        startupPipelineFile = [];
    end

    % MainGUI's "Open Pipeline Designer" menu launches the standalone app
    % via "open -a" (needed for the GUI/rendering engine to initialize
    % correctly when spawned from another already-running deployed app -
    % see MainGUI's openPipelineDesigner) - but "open --args" does not
    % reliably deliver argv to varargin here, so fall back to a small
    % handoff file MainGUI writes right before calling "open".
    if isempty(startupPipelineFile)
        handoffFile = fullfile(tempdir, 'VERA_PipelineDesigner_startup.txt');
        if exist(handoffFile, 'file')
            try
                handoffContent = strtrim(fileread(handoffFile));
                delete(handoffFile);
                if ~isempty(handoffContent) && exist(handoffContent, 'file')
                    startupPipelineFile = handoffContent;
                end
            catch he
                VERAErrorLog('PipelineDesigner', he);
            end
        end
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
        'HELP_AREA_HEIGHT', 235, ...
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
        'HELP_TEXT',       535, ...
        'HELP_LINK',       465, ...
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
            'Y',      500, ...
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
    % Deliberately a classic figure(), not uifigure - the uifigure family
    % (and uilabel/uilistbox/uibutton/uitextarea/uihyperlink/uialert/
    % uiprogressdlg below) depend on MATLAB's CEF-based rendering engine
    % (MATLABWindow/matlabwindowhelper), confirmed via a real crash report
    % (EXC_BREAKPOINT/SIGTRAP inside Chromium Embedded Framework's
    % CrRendererMain, responsibleProc "PipelineDesigner") to be broken in
    % at least one real deployment environment (a VM using Apple's
    % Virtualization framework). This whole window is rebuilt on classic
    % figure/uicontrol (Java Swing, no CEF dependency) instead - see
    % ClassicListboxAdapter.m/ClassicTextAreaAdapter.m/
    % ClassicHyperlinkAdapter.m for the widgets uicontrol has no native
    % equivalent for. Classic uicontrol Position uses the same
    % [left bottom width height], Y-up-from-parent-bottom convention as
    % uifigure's child components, so the UI.X/UI.Y pixel layout constants
    % below are unchanged from the original uifigure version.
    fig = figure('Position', [UI.WINDOW.START_X, UI.WINDOW.START_Y, ...
                               UI.WINDOW.WIDTH, UI.WINDOW.HEIGHT], ...
                   'Name', 'Pipeline Designer', ...
                   'MenuBar', 'none', 'ToolBar', 'none', 'NumberTitle', 'off');

    % Create a menu bar
    filemenu = uimenu(fig, 'Text', 'File');
    VERAmenu = uimenu(fig, 'Text', 'VERA Tools');
    helpmenu = uimenu(fig, 'Text', 'Help');

    %% Create the ListBox for writing pipeline code
     uicontrol(fig, 'Style', 'text', ...
        'Position', [UI.X.LEFT_PANEL, UI.Y.TOP, UI.COMMON.LABEL_WIDTH, UI.COMMON.LABEL_HEIGHT], ...
        'String', 'Pipeline', ...
        'HorizontalAlignment', 'left', ...
        'FontName', UI.FONT.REGULAR.NAME, ...
        'FontSize', UI.FONT.REGULAR.SIZE);

    pipelineListBox = ClassicListboxAdapter(fig, ...
        'Position',  [UI.X.LEFT_PANEL, UI.Y.OUTPUT_LIST, UI.COMMON.PIPELINE_WIDTH, UI.COMMON.PIPELINE_HEIGHT], ...
        'Items',     {''}, ...
        'ItemsData', {}, ...
        'FontName',  UI.FONT.CODE.NAME, ...
        'FontSize',  UI.FONT.CODE.SIZE);

    %% Create the TextArea for modifying component code
    uicontrol(fig, 'Style', 'text', ...
        'Position', [UI.X.LEFT_PANEL, UI.Y.COMPONENT_LABEL, UI.COMMON.LABEL_WIDTH, UI.COMMON.LABEL_HEIGHT], ...
        'String', 'Current Component in Pipeline', ...
        'HorizontalAlignment', 'left', ...
        'FontName', UI.FONT.REGULAR.NAME, ...
        'FontSize', UI.FONT.REGULAR.SIZE);

    pipelineElementTextArea = ClassicTextAreaAdapter(fig, ...
        'Position', [UI.X.LEFT_PANEL, UI.Y.BOTTOM, UI.COMMON.PIPELINE_WIDTH, UI.COMMON.TEXTAREA_HEIGHT], ...
        'Value', '', ...
        'FontName', UI.FONT.CODE.NAME, ...
        'FontSize', UI.FONT.CODE.SIZE, ...
        'Editable', 'on');

    %% Listbox of Input components
    uicontrol(fig, 'Style', 'text', ...
        'Position', [UI.X.MIDDLE_PANEL, UI.Y.TOP, UI.COMMON.LABEL_WIDTH, UI.COMMON.LABEL_HEIGHT], ...
        'String', 'Input Components', ...
        'HorizontalAlignment', 'left', ...
        'FontName', UI.FONT.REGULAR.NAME, ...
        'FontSize', UI.FONT.REGULAR.SIZE);

    availableInputComponentsListBox = ClassicListboxAdapter(fig, ...
        'Position', [UI.X.MIDDLE_PANEL, UI.Y.INPUT_LIST, UI.COMMON.LISTBOX_WIDTH, UI.COMMON.LISTBOX_HEIGHT], ...
        'Items', {''}, ...
        'FontName', UI.FONT.CODE.NAME, ...
        'FontSize', UI.FONT.CODE.SIZE);

    %% Listbox of Processing components
    uicontrol(fig, 'Style', 'text', ...
        'Position', [UI.X.MIDDLE_PANEL, UI.Y.PROCESSING_LIST + UI.COMMON.LISTBOX_HEIGHT + UI.COMMON.SPACING, UI.COMMON.LABEL_WIDTH, UI.COMMON.LABEL_HEIGHT], ...
        'String', 'Processing Components', ...
        'HorizontalAlignment', 'left', ...
        'FontName', UI.FONT.REGULAR.NAME, ...
        'FontSize', UI.FONT.REGULAR.SIZE);

    availableProcessingComponentsListBox = ClassicListboxAdapter(fig, ...
        'Position', [UI.X.MIDDLE_PANEL, UI.Y.PROCESSING_LIST, UI.COMMON.LISTBOX_WIDTH, UI.COMMON.LISTBOX_HEIGHT], ...
        'Items', {''}, ...
        'FontName', UI.FONT.CODE.NAME, ...
        'FontSize', UI.FONT.CODE.SIZE);

    %% Listbox of Output components
    uicontrol(fig, 'Style', 'text', ...
        'Position', [UI.X.MIDDLE_PANEL, UI.Y.OUTPUT_LIST + UI.COMMON.LISTBOX_HEIGHT + UI.COMMON.SPACING, UI.COMMON.LABEL_WIDTH, UI.COMMON.LABEL_HEIGHT], ...
        'String', 'Output Components', ...
        'HorizontalAlignment', 'left', ...
        'FontName', UI.FONT.REGULAR.NAME, ...
        'FontSize', UI.FONT.REGULAR.SIZE);

    availableOutputComponentsListBox = ClassicListboxAdapter(fig, ...
        'Position', [UI.X.MIDDLE_PANEL, UI.Y.OUTPUT_LIST, UI.COMMON.LISTBOX_WIDTH, UI.COMMON.LISTBOX_HEIGHT], ...
        'Items', {''}, ...
        'FontName', UI.FONT.CODE.NAME, ...
        'FontSize', UI.FONT.CODE.SIZE);

    %% Create the TextArea for modifying component code
    uicontrol(fig, 'Style', 'text', ...
        'Position', [UI.X.MIDDLE_PANEL, UI.Y.COMPONENT_LABEL, UI.COMMON.LABEL_WIDTH, UI.COMMON.LABEL_HEIGHT], ...
        'String', 'Current Component', ...
        'HorizontalAlignment', 'left', ...
        'FontName', UI.FONT.REGULAR.NAME, ...
        'FontSize', UI.FONT.REGULAR.SIZE);

    componentTextArea = ClassicTextAreaAdapter(fig, ...
        'Position', [UI.X.MIDDLE_PANEL, UI.Y.BOTTOM, UI.COMMON.LISTBOX_WIDTH, UI.COMMON.TEXTAREA_HEIGHT], ...
        'Value', '', ...
        'FontName', UI.FONT.CODE.NAME, ...
        'FontSize', UI.FONT.CODE.SIZE, ...
        'Editable', 'on');

    %% Listbox of possible views
    uicontrol(fig, 'Style', 'text', ...
        'Position', [UI.X.RIGHT_PANEL, UI.Y.OUTPUT_LIST + UI.COMMON.LISTBOX_HEIGHT + UI.COMMON.SPACING, UI.COMMON.LABEL_WIDTH, UI.COMMON.LABEL_HEIGHT], ...
        'String', 'Views', ...
        'HorizontalAlignment', 'left', ...
        'FontName', UI.FONT.REGULAR.NAME, ...
        'FontSize', UI.FONT.REGULAR.SIZE);

    availableViewsListBox = ClassicListboxAdapter(fig, ...
        'Position', [UI.X.RIGHT_PANEL, UI.Y.OUTPUT_LIST, UI.COMMON.LISTBOX_WIDTH, UI.COMMON.LISTBOX_HEIGHT], ...
        'Items', {''}, ...
        'FontName', UI.FONT.CODE.NAME, ...
        'FontSize', UI.FONT.CODE.SIZE);

    %% Create the TextArea for modifying view code
    uicontrol(fig, 'Style', 'text', ...
        'Position', [UI.X.RIGHT_PANEL, UI.Y.COMPONENT_LABEL, UI.COMMON.LABEL_WIDTH, UI.COMMON.LABEL_HEIGHT], ...
        'String', 'Current View', ...
        'HorizontalAlignment', 'left', ...
        'FontName', UI.FONT.REGULAR.NAME, ...
        'FontSize', UI.FONT.REGULAR.SIZE);

    viewTextArea = ClassicTextAreaAdapter(fig, ...
        'Position', [UI.X.RIGHT_PANEL, UI.Y.BOTTOM, UI.COMMON.LISTBOX_WIDTH, UI.COMMON.TEXTAREA_HEIGHT], ...
        'Value', '', ...
        'FontName', UI.FONT.CODE.NAME, ...
        'FontSize', UI.FONT.CODE.SIZE, ...
        'Editable', 'on');

    %% Create the TextArea for showing component/view help
    uicontrol(fig, 'Style', 'text', ...
        'Position', [UI.X.RIGHT_PANEL, UI.Y.TOP, UI.COMMON.LABEL_WIDTH, UI.COMMON.LABEL_HEIGHT], ...
        'String', 'Help', ...
        'HorizontalAlignment', 'left', ...
        'FontName', UI.FONT.REGULAR.NAME, ...
        'FontSize', UI.FONT.REGULAR.SIZE);

    helpTextArea = ClassicTextAreaAdapter(fig, ...
        'Position', [UI.X.RIGHT_PANEL, UI.Y.HELP_TEXT, UI.COMMON.LISTBOX_WIDTH, UI.COMMON.HELP_AREA_HEIGHT], ...
        'Value', '', ...
        'FontName', UI.FONT.CODE.NAME, ...
        'FontSize', UI.FONT.CODE.SIZE, ...
        'Editable', 'off');

    helpHyperlink = ClassicHyperlinkAdapter(fig, ...
        'Position', [UI.X.RIGHT_PANEL, UI.Y.HELP_LINK, UI.COMMON.LISTBOX_WIDTH, UI.BUTTON.EDITOR_OPEN.HEIGHT], ...
        'MaxWidth', UI.COMMON.LISTBOX_WIDTH, ...
        'FontSize', UI.FONT.REGULAR.SIZE);

    helpHyperlink.Text    = 'Help';
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
    uicontrol(fig, 'Style', 'pushbutton', 'String', 'Add Component', ...
        'Position', [UI.BUTTON.ADD_COMPONENT.X, UI.BUTTON.ADD_COMPONENT.Y, ...
                    UI.BUTTON.ADD_COMPONENT.WIDTH, UI.BUTTON.ADD_COMPONENT.HEIGHT], ...
        'FontSize', UI.FONT.REGULAR.SIZE, ...
        'Callback', @(btn, event) AddElement(fig, pipelineListBox, componentTextArea, pipelineElementTextArea));

    %% Create an Add View button to move current view to the bottom of the pipeline text area
    uicontrol(fig, 'Style', 'pushbutton', 'String', 'Add View', ...
        'Position', [UI.BUTTON.ADD_VIEW.X, UI.BUTTON.ADD_VIEW.Y, ...
                    UI.BUTTON.ADD_VIEW.WIDTH, UI.BUTTON.ADD_VIEW.HEIGHT], ...
        'FontSize', UI.FONT.REGULAR.SIZE, ...
        'Callback', @(btn, event) AddElement(fig, pipelineListBox, viewTextArea, pipelineElementTextArea));

    %% Create a Move Element Up button
    uicontrol(fig, 'Style', 'pushbutton', 'String', '^', ...
        'Position', [UI.BUTTON.MOVE_ELEMENT_UP.X, UI.BUTTON.MOVE_ELEMENT_UP.Y, ...
                    UI.BUTTON.MOVE_ELEMENT_UP.WIDTH, UI.BUTTON.MOVE_ELEMENT_UP.HEIGHT], ...
        'FontSize', UI.FONT.REGULAR.SIZE, ...
        'Callback', @(btn, event) MoveElementUp(pipelineListBox,pipelineElementTextArea));

    %% Create a Move Element Down button
    uicontrol(fig, 'Style', 'pushbutton', 'String', 'v', ...
        'Position', [UI.BUTTON.MOVE_ELEMENT_DOWN.X, UI.BUTTON.MOVE_ELEMENT_DOWN.Y, ...
                    UI.BUTTON.MOVE_ELEMENT_DOWN.WIDTH, UI.BUTTON.MOVE_ELEMENT_DOWN.HEIGHT], ...
        'FontSize', UI.FONT.REGULAR.SIZE, ...
        'Callback', @(btn, event) MoveElementDown(pipelineListBox,pipelineElementTextArea));

    %% Create a Delete Element button
    uicontrol(fig, 'Style', 'pushbutton', 'String', 'x', ...
        'Position', [UI.BUTTON.DELETE_ELEMENT.X, UI.BUTTON.DELETE_ELEMENT.Y, ...
                    UI.BUTTON.DELETE_ELEMENT.WIDTH, UI.BUTTON.DELETE_ELEMENT.HEIGHT], ...
        'FontSize', UI.FONT.REGULAR.SIZE, ...
        'Callback', @(btn, event) DeleteElement(pipelineListBox,pipelineElementTextArea));
    
    %% On startup either display empty pipeline or pipeline of current VERA project
    if ~isempty(startupPipelineFile)
        loadPipeline(fig,pipelineListBox,pipelineElementTextArea,helpTextArea,helpHyperlink,startupPipelineFile);
    else
        clearPipeline(pipelineListBox,pipelineElementTextArea);
    end

    %% Get all components
    componentParentClasses = {'AComponent','AFSSubsegmentation'};
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

    uicontrol(fig, 'Style', 'pushbutton', 'String', 'Open in Editor', ...
        'Position', [UI.BUTTON.EDITOR_OPEN.X, UI.BUTTON.EDITOR_OPEN.Y, ...
                    UI.BUTTON.EDITOR_OPEN.WIDTH, UI.BUTTON.EDITOR_OPEN.HEIGHT], ...
        'FontSize', UI.FONT.REGULAR.SIZE, ...
        'Callback', @(btn, event) OpenInEditor(fig));

    % Function to open the most recent file (active in help text area) in the matlab editor
    function OpenInEditor(fig,~)
        if isdeployed
            % edit() opens the MATLAB source editor, which doesn't exist
            % in a deployed app (and edit.m is itself on MATLAB
            % Compiler's non-deployable exclusion list)
            classicAlert(fig, 'Opening source in the MATLAB editor is not available in the standalone app.', 'Not Available');
        elseif exist(selectedElement, 'file') == 2
            edit(selectedElement);
        else
            % Display a warning if the file does not exist
            classicAlert(fig, ['File "', selectedElement, '" does not exist.'], 'File Not Found');
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
        classicAlert(fig, 'Error reading the file.', 'File Error');
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

        % get save path. Only toggle the main window's visibility around
        % the uiputfile dialog itself (not unconditionally) - a deployed
        % standalone app terminates the instant zero figures are visible,
        % and toggling Visible off with nothing else visible yet (as
        % happens when called with a pre-supplied inputFilePath, e.g.
        % from checkPipeline) risked hitting that window count race.
        if ~isempty(inputFilePath)
            [path, file, ext] = fileparts(inputFilePath);
            file = [file, ext];
        else
            fig.Visible = 'off'; % Hide the main window
            if ~isempty(startupPipelineFile)
                [file, path] = uiputfile(startupPipelineFile, 'Save pipeline file');
            else
                [file, path] = uiputfile(fullfile(defaultSavePath,'*.pwf'), 'Save pipeline file');
            end
            fig.Visible = 'on'; % Show the main window
        end

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
                classicAlert(fig, 'Error saving the file.', 'File Error');
            end

            if ~calledFromCheckPipeline
                classicAlert(fig, 'Pipeline saved!', 'Save Success');
            end
        else
            classicAlert(fig, 'Pipeline not saved! No file name selected', 'Save Failure');
        end

    else
        classicAlert(fig, 'Pipeline cannot be saved because pipeline check failed! See error/warning messages!', 'Save Failure');
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
    VERAfig           = [];

    % Classic waitbar in place of uiprogressdlg (see the note near fig's
    % construction above for why) - the dialog's Value is never updated
    % below (this is used purely as a "please wait" indicator until
    % close(checkingPipelineDlg) at the end of this function), so the lack
    % of an Indeterminate/spinning mode in classic waitbar has no visible
    % effect here. Cancelable isn't acted on anywhere in this function
    % either (no CancelRequested check), so dropping it is a no-op too.
    checkingPipelineDlg = waitbar(0, 'Checking Pipeline...', 'Name', 'Checking Pipeline');

    % Save working pipeline to be loaded into VERA and checked
    tempProjPath = setupTempProject();

    tempPipelinePath = fullfile(tempProjPath,'tempPipeline.pwf');
    pipelinePath     = savePipeline(fig,pipelineListBox,[],tempPipelinePath);

    % Create dialog boxes when there are warnings or errors. Everything
    % from here on (including constructing MainGUI) is inside this try -
    % previously MainGUI(...) below ran unprotected, so a crash there
    % would silently kill the check with no dialog and no way to see why.
    try
        % start VERA (would like to change this so pipelines can be checked
        % without running VERA...)
        VERAvisiblity = 'off';
        VERAhandle    = MainGUI(VERAvisiblity);

        % In the compiled app, PipelineDesigner.app and VERA.app are
        % separate mcc-compiled binaries, each with their own fully
        % separate embedded copy of MainGUI.m - so the MainGUI constructor
        % just above loaded ITS OWN bundled settings.xml, which
        % BuildStandaloneVERAApp.m always ships blank (so no build
        % machine's paths leak to an end user). PipelineDesigner has no
        % Settings UI of its own to populate that from, so real
        % dependency config only ever happens through the separately-
        % running VERA.app - load its settings.xml here on top of
        % whatever (blank) state MainGUI's own constructor just set up.
        % LoadDependencyFile only adds entries, it doesn't clear existing
        % ones first, so this is safe even though MainGUI() above already
        % called it once for the (empty) bundled file.
        if isdeployed
            try
                % Must agree with MainGUI.resolveSettingsPath() on where
                % VERA.app actually saves settings.xml, rather than
                % independently rediscovering (and getting wrong) its own
                % guess at the path.
                settingsPath = MainGUI.resolveSettingsPath();
                if exist(settingsPath,'file')
                    DependencyHandler.Instance.LoadDependencyFile(settingsPath);
                end
            catch
                % Fall through with whatever (blank) dependencies
                % MainGUI's own constructor already loaded -
                % checkResolvedDependencies below reports unresolved
                % deps same as before this fix existed, not a new
                % failure mode.
            end
        end

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

        % create VERA project to see if the pipeline is viable
        lastwarn('');
        createNewProject(VERAhandle,tempProjPath,pipelinePath);

        warnMsg_create = formatWarning();

        if ~isempty(warnMsg_create)
            % Not shown via warndlg: createNewProject already displayed its
            % own (more useful, deployed-safe) dialog for this - warnMsg_create
            % is only needed here as a signal to stop before configureAll runs
            % on a project that failed to create.

            % no need to continue testing if we find an issue
            % close VERA
            close(VERAfig);
        
            % delete temporary folder
            cleanupTempProject(tempProjPath);

            classicAlert(fig, 'Pipeline check failed!','Pipeline Check Results')
            pipelineStatus = 0;

            return;
        end

        % configure all components to see if any inputs or outputs are missing
        lastwarn('');
        configureAll(VERAhandle);

        warnMsg_configure = formatWarning();

        if ~isempty(warnMsg_configure)
            % Not shown via warndlg - same reasoning as warnMsg_create above:
            % whatever component threw already showed its own dialog
            % (configureComponent's scrollableErrordlg), this is just the
            % stop-here signal.

            % no need to continue testing if we find an issue
            % close VERA
            close(VERAfig);
        
            % delete temporary folder
            cleanupTempProject(tempProjPath);

            classicAlert(fig, 'Pipeline check failed!','Pipeline Check Results')
            pipelineStatus = 0;

            return;
        end
    catch me
        errormessage = me.message;
        VERAErrorLog('PipelineDesigner checkPipeline', me);
        errordlg(sprintf('%s\n\n(Full details logged to %s in your home folder.)', ...
            errormessage, 'VERA_error_log.txt'));
    end

    % Pipeline check results
    if isempty(warnMsg_create) && isempty(warnMsg_configure) && isempty(errormessage)
        pipelineStatus = 1;
        classicAlert(fig, 'Pipeline check passed!','Pipeline Check Results')
    else
        classicAlert(fig, 'Pipeline check failed!','Pipeline Check Results')
        pipelineStatus = 0;
    end

    % close VERA (may never have been created if MainGUI(...) itself threw)
    if ~isempty(VERAfig) && isvalid(VERAfig)
        close(VERAfig);
    end

    % delete temporary folder
    cleanupTempProject(tempProjPath);

    close(checkingPipelineDlg);
end

% reformat matlab warning for nicer display in warn dialog box
function warnMsg = formatWarning()
    warnMsg = lastwarn;

    if isempty(warnMsg)
        return;
    end

    % Warnings only contain '<a href="matlab:...">...</a>'-style
    % hyperlink markup when hotlinks are enabled (an interactive desktop
    % session) - a deployed app has no Command Window, so hyperlinks are
    % off and this markup is simply absent. Handle both cases explicitly
    % rather than assuming the hyperlinked form, which previously left
    % warnMsg as a cell array (from strsplit) instead of char whenever
    % hyperlinks were off, crashing the next line (isspace on a cell).
    try
        if contains(warnMsg, '</a>')
            [parts, matches] = strsplit(warnMsg,{'Error','</a>'});

            % Find the name of the element causing the error
            elementNameStart = find(contains(parts,'errorDocCallback'),1,'first');
            regexpString =  "(?<=\(')([^']+)(?='\))";
            elementName = regexp(parts(elementNameStart),regexpString,'match');

            start = find(contains(matches,'</a>'),1,'first') + 1;
            if ~isempty(start) && start <= numel(parts)
                warnMsg = parts{start};
            else
                warnMsg = strjoin(parts, ' ');
            end
        else
            elementName = {};
        end

        % remove return lines in warning
        warnMsg = regexprep(warnMsg,'[\n\r]+',' ');

        % remove leading space
        if ~isempty(warnMsg) && isspace(warnMsg(1))
            warnMsg(1) = [];
        end

        if exist('elementName','var') && ~isempty(elementName) && ~isempty(elementName{1})
            warnMsg = [elementName{1}{1}, ': ', warnMsg];
        end
    catch
        % Formatting is best-effort - fall back to the raw warning rather
        % than losing the whole pipeline-check result to a parsing bug
        warnMsg = lastwarn;
    end
end

%% Function to view the pipeline graph
function viewPipelineGraphInDesigner(fig, pipelineListBox)
    
    % check pipeline
    pipelineStatus = checkPipeline(fig,pipelineListBox);

    if pipelineStatus
        % Save working pipeline to be loaded into VERA and checked
        tempProjPath = setupTempProject();

        tempPipelinePath = fullfile(tempProjPath,'tempPipeline.pwf');
        pipelinePath     = savePipeline(fig,pipelineListBox,[],tempPipelinePath);

        VERAfig = [];
        try
            % start VERA (would like to change this so pipelines can be checked
            % without running VERA...)
            VERAvisiblity    = 'off';
            VERAhandle       = MainGUI(VERAvisiblity);

            % Find MainGUI's own window by Name, not by assuming it's
            % allFigureHandles(end) - findall's ordering isn't guaranteed
            % to put the just-created figure last, and picking the wrong
            % one here previously closed PipelineDesigner's own visible
            % window instead, which terminates the whole deployed app
            % (MATLAB Compiler standalone apps exit once zero figures are
            % visible). Same lookup checkPipeline already uses below.
            allFigureHandles = findall(groot,'Type','figure');
            figNames = cell(1,numel(allFigureHandles));
            for i = 1:numel(allFigureHandles)
                figNames{i} = allFigureHandles(i).Name;
            end
            veraFigIdx = find(strcmp(figNames,'VERA'),1,'last');
            if ~isempty(veraFigIdx)
                VERAfig = allFigureHandles(veraFigIdx);
            end

            % Create a VERA project so we can view the pipeline graph. In
            % theory this could be done without creating a project, but I don't
            % know how
            createNewProject(VERAhandle,tempProjPath,pipelinePath);

            % Create the pipeline graph
            viewPipelineGraph(VERAhandle);
        catch me
            VERAErrorLog('PipelineDesigner viewPipelineGraphInDesigner', me);
            errordlg(sprintf('%s\n\n(Full details logged to %s in your home folder.)', ...
                me.message, 'VERA_error_log.txt'));
        end

        % close the VERA figure window (hidden), if it got created
        if ~isempty(VERAfig) && isvalid(VERAfig)
            close(VERAfig);
        end

        % delete temporary folder
        cleanupTempProject(tempProjPath);
    end
end

%% Function to get all components/views in a given directory
function [Names, componentTypes] = getAvailableElements(dirPath,parentClasses,compOrView)

    % Scanning every .m file under dirPath (and, per component, re-reading
    % its source again in getComponentType) is expensive and dirPath is
    % scanned fresh every time the designer is opened. Cache per session,
    % keyed on the call arguments.
    persistent elementCache
    if isempty(elementCache)
        elementCache = containers.Map();
    end

    % Deliberately excludes dirPath from the key: dirPath is an absolute
    % path that differs between build time and the deployed app's
    % extracted CTF location, but each (parentClasses,compOrView)
    % combination only ever maps to one dirPath in this app anyway.
    cacheKey = strjoin({strjoin(parentClasses,','), compOrView}, '|');
    if isKey(elementCache, cacheKey)
        cached          = elementCache(cacheKey);
        Names           = cached.Names;
        componentTypes  = cached.componentTypes;
        return;
    end

    % Deployed apps can't fileread() their own bundled .m source (MATLAB
    % Compiler ships it as encrypted p-code) - the scan below would find
    % nothing. Load the manifest precomputed at compile time instead.
    if isdeployed
        m = loadManifestOnce();
        if strcmp(compOrView,'component')
            Names          = m.compNames;
            componentTypes = m.compTypes;
        else
            Names          = m.viewNames;
            componentTypes = {};
        end
        cached.Names          = Names;
        cached.componentTypes = componentTypes;
        elementCache(cacheKey) = cached;
        return;
    end

    Names          = {};
    componentTypes = {};

    % set up parentClasses to be used in regular expression
    parentClassesString = strjoin(parentClasses, '|');

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

                % Look for a class definition and check for inheritance from
                % parentClass. Restricted to the classdef header line only
                % (no crossing a newline) so it can't wander into a doc
                % comment or method body and match a parent class name
                % mentioned in prose; tolerant of the "classdef (Attribute)
                % Name < Parent" attribute syntax (e.g. "(Abstract)"), which
                % the previous pattern couldn't match at all; and requires a
                % word boundary around the parent class name so e.g.
                % "NotAComponentWrapper" can't match "AComponent" as a
                % substring.
                classDefPattern = ['classdef\s+(?:\([^\n)]*\)\s+)?(\w+)\s*(?:<[^\n>]*)?(?<!\w)(', parentClassesString, ')(?!\w)'];

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

    cached.Names          = Names;
    cached.componentTypes = componentTypes;
    elementCache(cacheKey) = cached;

end

%% Function to get component names/types for the current pipeline
function [compNames, viewNames, elements] = getCurrentComponents(pipelineText)
    % Locate the line ranges of each Component/View block. Boundary
    % detection stays line-based (rather than a full-document XML parse)
    % so that each block's exact original text is preserved verbatim for
    % round-tripping through the editable text areas.
    componentStart = [];
    componentEnd   = [];
    viewStart      = [];
    viewEnd        = [];

    for i = 1:size(pipelineText, 1)
        line = pipelineText{i};

        % Match the start of an opening <Component ...>/<Component> tag
        % regardless of attribute order or spacing, rather than requiring
        % the literal substring '<Component Type="' - which breaks if
        % Type isn't written as the first attribute. The (\s|>) after
        % 'Component' also keeps this from matching an unrelated tag that
        % merely starts with the same word, e.g. '<ComponentFoo ...>'.
        if ~isempty(regexp(line, '<Component(\s|>)', 'once'))
            componentStart(end + 1) = i;
            if contains(line,'/>')
                componentEnd(end + 1) = i;
            end
        elseif contains(line, '</Component>')
            componentEnd(end + 1) = i;
        end

        if ~isempty(regexp(line, '<View(\s|>)', 'once'))
            viewStart(end + 1) = i;
            if contains(line,'/>')
                viewEnd(end + 1) = i;
            end
        elseif contains(line, '</View>')
            viewEnd(end + 1) = i;
        end
    end

    % Extract each component/view's raw text block
    elementStart = sort([componentStart, viewStart]);
    elementEnd   = sort([componentEnd,   viewEnd]);
    elements     = {};
    for i = 1:length(elementStart)
        elements{i} = pipelineText(elementStart(i):elementEnd(i));
    end

    % Derive names via real XML parsing of each block (see getElementNames),
    % then split back out by whether each block was a Component or a View
    elementNames = getElementNames(elements);
    isComponent  = ismember(elementStart, componentStart);

    compNames = elementNames(isComponent);
    viewNames = elementNames(~isComponent);
end

%% Function to get names from elements structure
function elementNames = getElementNames(elements)
    elementNames = {''};

    % sort through elements to find name. If there is no name, use the
    % element type as name
    for i = 1:length(elements)
        [name, ~] = parseElementNameAndType(elements{i});
        elementNames{i} = name;
    end
end

%% Function to get element types
function elementTypes = getElementTypes(elements)
    elementTypes = {''};

    % sort through elements to find type
    for i = 1:length(elements)
        [~, type] = parseElementNameAndType(elements{i});
        elementTypes{i} = type;
    end
end

%% Function to extract the Name and Type of a Component/View XML block
function [name, type] = parseElementNameAndType(elementLines)
    name = '';
    type = '';

    % Guard against empty/blank blocks (e.g. an empty pipelineListBox
    % selection) before attempting a real XML parse - an empty document
    % is not valid XML and the JVM's default XML error handler prints
    % straight to stderr ("Premature end of file"), which try/catch does
    % not silence even though the error itself is caught
    if isempty(strtrim(strjoin(cellstr(elementLines), '')))
        return;
    end

    try
        doc  = parseXMLString(elementLines);
        root = doc.getDocumentElement();

        type = char(root.getAttribute('Type'));

        nameNodes = root.getElementsByTagName('Name');
        if nameNodes.getLength() > 0
            name = stripValueQuotes(char(nameNodes.item(0).getTextContent()));
        end
    catch
        % Malformed block - leave name/type empty, caller falls back to type
    end

    if isempty(name)
        name = type;
    end
end

%% Function to parse a Component/View XML fragment in memory (no file I/O)
function doc = parseXMLString(xmlLines)
    xmlText = strjoin(cellstr(xmlLines), newline);

    factory  = javax.xml.parsers.DocumentBuilderFactory.newInstance();
    builder  = factory.newDocumentBuilder();
    inSource = org.xml.sax.InputSource(java.io.StringReader(xmlText));
    doc      = builder.parse(inSource);
end

%% Function to strip the literal quote characters VERA stores around string values
function s = stripValueQuotes(s)
    if length(s) >= 2 && s(1) == '"' && s(end) == '"'
        s = s(2:end-1);
    end
end

%% Function to inspect the properties of a component or view selected in the pipeline
function viewElementOfPipeline(textArea,pipelineListBox,helpTextArea,helpHyperlink)

    textArea.Value = pipelineListBox.Value;

    % show help of selected element
    % Need element type to show help
    elementType = getElementTypes({pipelineListBox.Value});

    % No pipeline/project loaded (or otherwise a blank selection) means
    % there's nothing valid to look up - parseElementNameAndType already
    % returns '' for an empty block. showHelp's own downstream lookups
    % (getInputsOutputs -> fileread(''), etc.) aren't guarded against an
    % empty element name, so skip the whole help/dependency lookup here
    % rather than patching every function in that chain individually.
    if isempty(elementType{1})
        return;
    end

    [dependencies, optionalDependencies] = getDependencies(elementType{1});
    showHelp(helpTextArea,helpHyperlink,elementType{1},dependencies,optionalDependencies);

end

%% Function to modify current pipeline when modifying pipeline element text area
function modifyCurrentPipelineElement(fig,pipelineElementTextArea,pipelineListBox)

    % Testing functionality to check element formatting
    [isValid, errormsg] = testHTMLFormat(pipelineElementTextArea.Value);
    if ~isValid
        classicAlert(fig,[errormsg, ' Stored anyway, but be cautious.'], 'Warning')
    end

    % Find currently selected item in ItemsData
    index = findSelectedIndex(pipelineListBox);

    % Check if name has been changed to be a duplicate
    elementName  = getElementNames({pipelineElementTextArea.Value});

    pipelineListBox.Items{index} = char(floor(26*rand(1, 20)) + 65);

    isDuplicated = checkforDuplicateNames(pipelineListBox.Items,elementName);

    pipelineListBox.ItemsData{index} = pipelineElementTextArea.Value;
    pipelineListBox.Value            = pipelineListBox.ItemsData{index}; 
    pipelineListBox.Items            = getElementNames(pipelineListBox.ItemsData);
    
    if isDuplicated
        classicAlert(fig, 'Error: Duplicate Names. Elements cannot have the same name.', 'Duplicate Names');
        
        % set item to unavailable name
        pipelineListBox.Items{index}     = [elementName{1}, ' - Cannot have duplicate name!'];
    end
end

%% Function to move element up in listbox and in pipeline text
function MoveElementUp(pipelineListBox,pipelineElementTextArea)

    % Find currently selected item in ItemsData
    index = findSelectedIndex(pipelineListBox);

    if numel(pipelineListBox.Items) > 1
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

        % Reordering above only moves the underlying Items/ItemsData -
        % the listbox's own raw selection index isn't touched by that,
        % so without this the highlighted row silently stays put while
        % a *different* element ends up under it (the one that got
        % displaced), instead of following the element that just moved.
        pipelineListBox.Value = pipelineListBox.ItemsData{idx2};

    end

    pipelineElementTextArea.Value = pipelineListBox.Value;

end

%% Function to move element down in listbox and in pipeline text
function MoveElementDown(pipelineListBox,pipelineElementTextArea)

    % Find currently selected item in ItemsData
    index = findSelectedIndex(pipelineListBox);

    if numel(pipelineListBox.Items) > 1
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

        % See the matching comment in MoveElementUp - keep the selection
        % on the element that just moved, not on whatever row it left
        % behind.
        pipelineListBox.Value = pipelineListBox.ItemsData{idx2};

    end

    pipelineElementTextArea.Value = pipelineListBox.Value;
end

%% Function to remove an element from the listbox and pipeline text
function DeleteElement(pipelineListBox,pipelineElementTextArea)

    % Find currently selected item in ItemsData
    index = findSelectedIndex(pipelineListBox);

    if numel(pipelineListBox.Items) > 1
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
    component = feval(componentName);

    % Only worry about properties from AComponent, ignoring any other input
    % parent classes
    parentClassProps = meta.class.fromName(parentClass{1});
    parentClassNames = {parentClassProps.PropertyList.Name}';

    textArea.Value = serializeElementToText(component, 'Component', parentClassNames);

    % show help of selected component
    [dependencies, optionalDependencies] = getDependencies(componentName);
    showHelp(helpArea,helpHyperlink,currentComponent,dependencies,optionalDependencies);
end

%% Function to inspect the properties of a view selected in the listbox
function viewView(textArea,helpArea,helpHyperlink,parentClass,currentView)
    [~,viewName] = fileparts(currentView);
    view = feval(viewName);

    % Get the properties of all parent class(es)
    parentClassNames = {};
    for i = 1:length(parentClass)
        parentClassProps = meta.class.fromName(parentClass{i});
        parentClassNames = [parentClassNames; {parentClassProps.PropertyList.Name}'];
    end

    textArea.Value = serializeElementToText(view, 'View', parentClassNames);

    % show help of selected view
    [dependencies, optionalDependencies] = getDependencies(viewName);
    showHelp(helpArea,helpHyperlink,currentView,dependencies,optionalDependencies);
end

%% Function to serialize a component/view's properties into the pipeline's XML-like text format
function lines = serializeElementToText(obj, tagName, parentClassNames)
    props = properties(obj);

    % Trying to exclude parent properties that are not set in the
    % element. This causes problems when using inherited class properties
    uniqueProperties = setdiff(props,parentClassNames,'stable');
    uniqueProperties = [uniqueProperties; 'Name']; % add back Name

    % Remove dependent properties as both cannot be used in the element
    % e.g. MRIIdentifer and CoregistrationIdentifier in Coregistration.m
    mc = metaclass(obj);
    remDependentIDX = [];
    iter = 1;
    for i = 1:length(mc.PropertyList)
        prop = mc.PropertyList(i);
        if prop.Dependent && any(ismember(uniqueProperties,prop.Name)) &&...
                (strcmp(prop.GetAccess, 'public') || strcmp(prop.SetAccess, 'public'))
            remDependentIDX(iter) = i;
            iter = iter + 1;
        end
    end
    uniqueProperties(ismember(uniqueProperties,props(remDependentIDX))) = [];

    % Start building the XML string
    lines      = {''};
    lines{1,1} = sprintf('<%s Type="%s">', tagName, class(obj));

    % Loop through the properties and add them to the XML string
    for i = 1:length(uniqueProperties)
        propValue    = obj.(uniqueProperties{i});
        propValueStr = serializePropertyValue(propValue);

        % Add property to XML (with the property name as the tag)
        lines{i+1,1} = sprintf('    <%s>%s</%s>', uniqueProperties{i}, propValueStr, uniqueProperties{i});
    end

    % Close the element and XML structure
    lines{end+1,1} = sprintf('</%s>', tagName);
end

%% Function to convert a single property value to its pipeline text representation
function propValueStr = serializePropertyValue(propValue)
    if ischar(propValue) && isempty(propValue)
        propValueStr = '""';

    elseif isnumeric(propValue) && isempty(propValue)
        propValueStr = '[]';

    elseif iscell(propValue) && isempty(propValue)
        propValueStr = '[""]';

    elseif ischar(propValue) || isstring(propValue)
        propValueStr = escapeXMLText(jsonencode(char(propValue)));

    elseif isnumeric(propValue) && length(propValue) > 1
        % build a bracketed vector
        propValueStr = ['[', strjoin(arrayfun(@(v) sprintf('%g',v), propValue, 'UniformOutput', false), ','), ']'];

    elseif isnumeric(propValue)
        propValueStr = sprintf('%g', propValue);

    elseif islogical(propValue)
        propValueStr = sprintf('"%s"', mat2str(propValue));

    elseif iscell(propValue) && length(propValue) > 1
        % build a bracketed array if more than 1 element
        propValueStr = ['[', strjoin(cellfun(@(v) escapeXMLText(jsonencode(char(v))), propValue, 'UniformOutput', false), ','), ']'];

    elseif iscell(propValue)
        propValueStr = escapeXMLText(jsonencode(char(propValue{1})));

    else
        propValueStr = '""';  % For unsupported or complex types
    end
end

%% Function to escape XML-reserved characters in element text content, so a
%% property value containing '&', '<', or '>' still produces well-formed
%% XML. The runtime pipeline loader (classes/engine/Serializable.m
%% Deserialize, via Dependencies/xml2struct's real xmlread-based DOM
%% parser) auto-unescapes these on read, and jsondecode's own string
%% escaping (backslashes, embedded quotes - handled by jsonencode above)
%% is a separate, independent layer from XML's - both are required for a
%% value to round-trip correctly. Verified against the real runtime
%% deserialization path with matlab -batch, including confirming the
%% previous unescaped form throws a SAXParseException on an ampersand.
function s = escapeXMLText(s)
    s = strrep(s, '&', '&amp;');   % must run first - other entities contain '&'
    s = strrep(s, '<', '&lt;');
    s = strrep(s, '>', '&gt;');
end

%% Help function to display help text
function showHelp(helpTextArea,helpHyperlink,element,dependencies,optionalDependencies)
    % help() itself is on MATLAB Compiler's non-deployable exclusion list
    % (it reads doc comments from source, same limitation as fileread()
    % elsewhere in this file) - use the text captured at compile time
    % instead, via the same help() call, while source was still readable.
    if isdeployed
        m = loadManifestOnce();
        [~,elementClassNameForHelp] = fileparts(element);
        if isKey(m.elementInfo, elementClassNameForHelp) && isfield(m.elementInfo(elementClassNameForHelp),'helpText')
            helpText = m.elementInfo(elementClassNameForHelp).helpText;
        else
            helpText = '';
        end
    else
        helpText = help(element);
    end

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

    % add inputs/outputs, derived from AddInput/AddOutput calls in source,
    % the same way dependencies are derived below
    [~,elementClassName] = fileparts(element);
    [inputs, outputs]    = getInputsOutputs(elementClassName);

    helpText = [helpText, formatHelpListSection('Inputs',  inputs)];
    helpText = [helpText, formatHelpListSection('Outputs', outputs)];

    % add dependencies to help text
    helpText = [helpText, formatHelpListSection('Dependencies', dependencies)];
    helpText = [helpText, formatHelpListSection('Optional Dependencies', optionalDependencies)];

    % write help text to helpTextArea
    helpTextArea.Value = helpText;

    helpHyperlink.Text    = [elementClassName, ' Wiki Help'];
    helpHyperlink.URL     = ['https://github.com/neurotechcenter/VERA/wiki/', element];
    helpHyperlink.Tooltip = helpHyperlink.URL;

end

%% Function to format a labeled list section (e.g. Inputs, Dependencies) for the help text
function section = formatHelpListSection(sectionTitle, items)
    section = [newline, sectionTitle, ': ', newline];
    if ~isempty(items)
        for i = 1:length(items)
            section = [section, items{i}, newline];
        end
    else
        section = [section, 'none', newline];
    end
end

%% Function to get the Inputs/Outputs identifiers a component declares (via AddInput/AddOutput)
function [inputs, outputs] = getInputsOutputs(className)
    % Views (and any element with no AddInput/AddOutput calls) simply
    % yield empty lists here - there is nothing to inherently distinguish
    % them from a Component with zero declared inputs/outputs.
    persistent inputsOutputsCache
    if isempty(inputsOutputsCache)
        inputsOutputsCache = containers.Map();
    end

    if isKey(inputsOutputsCache, className)
        cached  = inputsOutputsCache(className);
        inputs  = cached.inputs;
        outputs = cached.outputs;
        return;
    end

    % Deployed apps can't fileread() their own bundled .m source - use
    % the manifest precomputed at compile time instead. See
    % getAvailableElements for why.
    if isdeployed
        m = loadManifestOnce();
        if isKey(m.elementInfo, className)
            info    = m.elementInfo(className);
            inputs  = info.inputs;
            outputs = info.outputs;
        else
            inputs  = {};
            outputs = {};
        end
        cached.inputs = inputs; cached.outputs = outputs;
        inputsOutputsCache(className) = cached;
        return;
    end

    [inputs, outputs] = extractInputsOutputs(className, []);

    cached.inputs          = inputs;
    cached.outputs         = outputs;
    inputsOutputsCache(className) = cached;
end

%% Function to move component or view to pipeline
function AddElement(fig,pipelineListBox,elementText,pipelineElementTextArea)

    elementNames       = getElementNames(pipelineListBox.ItemsData);
    currentElementName = getElementNames({pipelineListBox.Value});
    elementToAddName   = getElementNames({elementText.Value});

    % Throw an error if there are duplicated elements
    isDuplicated = checkforDuplicateNames(elementNames,elementToAddName{1});
    if isDuplicated
        classicAlert(fig, 'Error: Duplicate Names. Elements cannot have the same name.', 'Duplicate Names');
    else
        % Testing functionality to check element formatting
        [isValid, errormsg] = testHTMLFormat(elementText.Value);
        if ~isValid
            classicAlert(fig,[errormsg, ' Added anyway, but be cautious.'], 'Warning')
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
        if numel(pipelineListBox.Items) > 1
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
    inputs  = {};
    outputs = {};

    % Get the class definition
    classInfo = meta.class.fromName(className);
    superclassInfo = classInfo.SuperclassList;
    superclassName = superclassInfo.Name;

    % Iterate through the class methods
    for i = 1:length(classInfo.MethodList)
        methodName = classInfo.MethodList(i).Name;
        
        % Check for AddInput and AddOutput methods
        if strcmp(methodName, 'Publish')
            % Look at the Publish method to get inputs and outputs
            [inputs, outputs] = extractInputsOutputs(className,classInfo);

            if isempty(inputs) && isempty(outputs)
                % Check the super class in case of inheritance (this is clunky)
                [inputs, outputs] = extractInputsOutputs(superclassName,superclassInfo);
            end
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
function [inputs, outputs] = extractInputsOutputs(className,classInfo)
    % A better approach might be to look at
    % {classInfo.PropertyList.Name}'

    % Check for calls to AddInput and AddOutput in the method body
    filePath   = which([className '.m']);
    methodCode = fileread(filePath);
    
    % Regular expression to find AddInput and AddOutput calls. The
    % closing paren must be followed by ';', a newline, or end-of-file
    % (rather than requiring a literal ');') because MATLAB statements
    % don't require a trailing semicolon - e.g. TalairachProjection.m
    % declares obj.AddInput(...) with no ';' on some lines, which a bare
    % '\);' requirement silently fails to match, dropping that input from
    % the help panel and componentType detection with no error.
    inputPattern  = 'obj\.AddInput\(([\s\S]*?)\)[ \t]*(?:;|\r?\n|$)';
    outputPattern = 'obj\.AddOutput\(([\s\S]*?)\)[ \t]*(?:;|\r?\n|$)';

    optionalInputPattern  = 'obj\.AddOptionalInput\(([\s\S]*?)\)[ \t]*(?:;|\r?\n|$)';
    optionalOutputPattern = 'obj\.AddOptionalOutput\(([\s\S]*?)\)[ \t]*(?:;|\r?\n|$)';

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

    % Nothing to look up - happens when the pipeline listbox is clicked
    % with no project/pipeline loaded (or an otherwise blank selection):
    % parseElementNameAndType already returns '' for an empty block, and
    % meta.class.fromName('') returns an empty meta.class array rather
    % than erroring, which then makes classInfo.MethodList below produce
    % a zero-element comma-separated list - length() called with that as
    % its "argument" is really called with none, throwing "Not enough
    % input arguments" instead of a clear message. Bail out early instead.
    if isempty(className)
        dependencies         = {};
        optionalDependencies = {};
        return;
    end

    % Dependency extraction requires re-reading and regex-scanning the
    % component's source file, and the same className is looked up
    % repeatedly (e.g. every time it's selected in a listbox). Cache the
    % result per MATLAB session so repeat lookups are free.
    persistent dependencyCache
    if isempty(dependencyCache)
        dependencyCache = containers.Map();
    end

    if isKey(dependencyCache, className)
        cached                = dependencyCache(className);
        dependencies          = cached.dependencies;
        optionalDependencies  = cached.optionalDependencies;
        return;
    end

    % Deployed apps can't fileread() their own bundled .m source - use
    % the manifest precomputed at compile time instead. See
    % getAvailableElements for why.
    if isdeployed
        m = loadManifestOnce();
        if isKey(m.elementInfo, className)
            info = m.elementInfo(className);
            dependencies         = info.dependencies;
            optionalDependencies = info.optionalDependencies;
        else
            dependencies         = {};
            optionalDependencies = {};
        end
        cached.dependencies         = dependencies;
        cached.optionalDependencies = optionalDependencies;
        dependencyCache(className)  = cached;
        return;
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

    cached.dependencies         = dependencies;
    cached.optionalDependencies = optionalDependencies;
    dependencyCache(className)  = cached;

end

% Function to extract dependencies of a component
function [dependencies, optionalDependencies] = extractDependencies(className)
    % Check for calls to GetDependency in the method body
    filePath   = which([className '.m']);
    methodCode = fileread(filePath);
    
    % Regular expression to find GetDependency calls. See extractInputsOutputs
    % above for why the closing paren isn't required to be followed by a
    % literal ';'.
    getDependencyPattern = 'obj\.GetDependency\(([\s\S]*?)\)[ \t]*(?:;|\r?\n|$)';
    reqDependencyPattern = 'obj\.RequestDependency\(([\s\S]*?)\)[ \t]*(?:;|\r?\n|$)';
    optDependencyPattern = 'obj\.GetOptionalDependency\(([\s\S]*?)\)[ \t]*(?:;|\r?\n|$)';

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

%% Classic equivalent of uialert(fig, message, title) - see the note near
%% fig's construction above for why uialert (uifigure-only) is avoided.
%% Every uialert(...) call site converted to this in this file omitted the
%% Icon argument, meaning they all relied on uialert's default Icon of
%% 'error' - errordlg matches that uniformly.
function classicAlert(fig, message, title) %#ok<INUSD> fig kept for call-site compatibility with uialert's signature, unused by errordlg
    errordlg(message, title);
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

%% Function to create a fresh temporary project folder for pipeline checking
function tempProjPath = setupTempProject()
    if isdeployed
        % Same read-only-bundle issue as MainGUI.resolveSettingsPath() -
        % mkdir here failed silently since callers check pipeline status
        % before their own try/catch starts. Use the OS temp folder instead.
        currentPath = tempdir;
    else
        currentPath = fileparts(mfilename('fullpath'));
    end
    tempProjPath = fullfile(currentPath,'temp/tempProj');

    if exist(tempProjPath,'dir')
        cleanupTempProject(tempProjPath);
    end
    mkdir(tempProjPath);
end

%% Function to remove the temporary project folder used for pipeline checking
function cleanupTempProject(tempProjPath)
    warning off;
    rmdir(fullfile(tempProjPath,'..'),'s');
    warning on;
end

%% Function to find the index of the currently selected pipeline element
function index = findSelectedIndex(pipelineListBox)
    index = [];
    for i = 1:length(pipelineListBox.ItemsData)
        if isequaln(pipelineListBox.ItemsData{i},pipelineListBox.Value)
            index = i;
        end
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

%% Function to test if component/view text is well-formed XML
function [isValid,msg] = testHTMLFormat(inputStr)
    isValid = true;
    msg     = [];

    if isempty(strtrim(strjoin(cellstr(inputStr), '')))
        return;
    end

    try
        parseXMLString(inputStr);
    catch parseErr
        isValid = false;
        msg     = ['Error: Invalid XML - ', parseErr.message];
    end
end

%% Build-time only: precompute everything the deployed app needs, while
%% source is still readable as plain text (see the isdeployed branches in
%% getAvailableElements/getDependencies/getInputsOutputs/showHelp).
%% Invoked as PipelineDesigner('BuildManifest', outputMatPath) from a
%% normal (non-deployed) MATLAB session before compiling.
function buildPipelineDesignerManifest(mfilePath, outputPath)
    componentParentClasses = {'AComponent','AFSSubsegmentation'};
    componentPath          = GetFullPath(fullfile(mfilePath,'..','Components'));
    viewParentClasses      = {'uix.Grid','AView','IComponentView','SliceViewerXYZ'};
    viewPath               = GetFullPath(fullfile(mfilePath,'..','classes','GUI','Views'));

    [compNames, compTypes] = getAvailableElements(componentPath, componentParentClasses, 'component');
    viewNames               = getAvailableElements(viewPath, viewParentClasses, 'view');

    manifest.compNames   = compNames;
    manifest.compTypes   = compTypes;
    manifest.viewNames   = viewNames;
    manifest.elementInfo = containers.Map();

    allNames = [compNames(:); viewNames(:)];
    for i = 1:numel(allNames)
        name               = allNames{i};
        [deps, optDeps]    = getDependencies(name);
        [inputs, outputs]  = getInputsOutputs(name);
        try
            helpText = help(name);
        catch
            helpText = '';
        end
        info.dependencies         = deps;
        info.optionalDependencies = optDeps;
        info.inputs                = inputs;
        info.outputs                = outputs;
        info.helpText               = helpText;
        manifest.elementInfo(name) = info;
    end

    save(outputPath, 'manifest');
    fprintf('PipelineDesigner manifest saved: %d components, %d views -> %s\n', ...
        numel(compNames), numel(viewNames), outputPath);
end

%% Deployed-mode only: load (once per session, then cached) the manifest
%% precomputed at compile time by buildPipelineDesignerManifest. The
%% manifest file ships alongside PipelineDesigner.m itself in the bundle.
function manifest = loadManifestOnce()
    persistent cachedManifest
    if isempty(cachedManifest)
        manifestPath   = fullfile(fileparts(mfilename('fullpath')), 'PipelineDesignerManifest.mat');
        loaded          = load(manifestPath, 'manifest');
        cachedManifest  = loaded.manifest;
    end
    manifest = cachedManifest;
end

