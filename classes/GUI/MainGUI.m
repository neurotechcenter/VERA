classdef MainGUI < handle
    %MainGUI VERA main GUI
    
    properties (Access = public)
        ProjectRunner Runner
        Views ViewMap
        
    end
    
    properties (Access = private)
        window
        hBox
        treeNodes
        pipelineTree
        mainView
        fileMenu
        configMenu
        multiSubjectMenu
        fileMenuContent
        configMenuContent
        multiSubjectMenuContent
        viewTabs containers.Map
        componentNodes containers.Map
        componentMenu
        ProgressBarTool
        checkPipelineContent

    end
    
    methods
        function obj = MainGUI(varargin)
            if nargin > 0
                figVisibility = varargin{1};
            else
                figVisibility = 'on';
            end

            obj.checkPipelineContent = 'on';

            DependencyHandler.Purge();
            obj.componentNodes = containers.Map();
            warning off;
            obj.window = figure('Name','VERA', ...
            'NumberTitle', 'off', ...
            'MenuBar', 'none', ...
            'Toolbar', 'none', ...
            'Visible', figVisibility, ...
            'HandleVisibility', 'on','CloseRequestFcn',@obj.onClose);
            cameratoolbar(obj.window,'NoReset');

            settingsPath = MainGUI.resolveSettingsPath();
            if exist(settingsPath,'file')
                DependencyHandler.Instance.LoadDependencyFile(settingsPath);
            end

            % Register the VERA_SuperModel companion tool (a standalone
            % multi-subject viewer, not part of the pipeline itself) as a
            % configurable dependency so its install location shows up
            % under Configuration > Settings even before it has ever been
            % set. See also launchSuperModelViewer. SettingsGUI's table
            % leaves an unresolved dependency's Value cell blank, so give
            % it a visible placeholder ('.') rather than nothing - '.' is
            % treated as "not actually configured" by
            % refreshSuperModelAvailability, not a real install path.
            DependencyHandler.Instance.PostDepencenyRequest('VERA_SuperModel','folder');
            if ~DependencyHandler.Instance.IsDependency('VERA_SuperModel')
                DependencyHandler.Instance.SetDependency('VERA_SuperModel','.');
            end

            obj.viewTabs     = containers.Map();
            obj.hBox         = uix.HBoxFlex('Parent',    obj.window);
            obj.pipelineTree = uiw.widget.Tree('Parent', obj.hBox,'MouseClickedCallback',@obj.treeClick);
            obj.mainView     = uitabgroup('Parent',      obj.hBox);
            obj.hBox.Widths  = [200 -1];
            % empty views

            obj.fileMenu                             = uimenu(obj.window,'Label','File');
            obj.fileMenuContent.OpenPipelineDesigner = uimenu(obj.fileMenu,'Label','Open Pipeline Designer', 'MenuSelectedFcn',@(~,~,~) obj.openPipelineDesigner);
            obj.fileMenuContent.NewProject           = uimenu(obj.fileMenu,'Label','New Project',            'MenuSelectedFcn',@(~,~,~)obj.createNewProject);
            obj.fileMenuContent.OpenProject          = uimenu(obj.fileMenu,'Label','Open Project',           'MenuSelectedFcn',@obj.openProject);
            obj.fileMenuContent.ReopenProject        = uimenu(obj.fileMenu,'Label','Reopen Project',         'MenuSelectedFcn',@obj.reopenProject);
            obj.fileMenuContent.CloseProject         = uimenu(obj.fileMenu,'Label','Close Project',          'Enable','off','MenuSelectedFcn',@(~,~,~)obj.closeProject);

            obj.configMenu                             = uimenu(obj.window,'Label','Configuration');
            obj.configMenuContent.Settings             = uimenu(obj.configMenu,'Label','Settings',                 'MenuSelectedFcn',@(~,~,~) obj.openSettings());
            obj.configMenuContent.ConfigAll            = uimenu(obj.configMenu,'Label','Configure all Components', 'MenuSelectedFcn',@(~,~,~) obj.configureAll());
            obj.configMenuContent.RunAll               = uimenu(obj.configMenu,'Label','Run all Components',       'MenuSelectedFcn',@(~,~,~) obj.runAll());
            obj.configMenuContent.ReloadAll            = uimenu(obj.configMenu,'Label','Reload all Components',    'MenuSelectedFcn',@(~,~,~) obj.reloadAll());
            obj.configMenuContent.ViewPipeline         = uimenu(obj.configMenu,'Label','View Pipeline Graph',      'MenuSelectedFcn',@(~,~,~) obj.viewPipelineGraph());
            obj.configMenuContent.pipelineContentCheck = uimenu(obj.configMenu,'Label','Pipeline Content Check','Checked','on','MenuSelectedFcn',@(~,~,~)obj.pipelineContentCheck());

            obj.multiSubjectMenu                          = uimenu(obj.window,'Label','Multi Subject');
            obj.multiSubjectMenuContent.LaunchSuperModel  = uimenu(obj.multiSubjectMenu,'Label','Launch Multi-Subject Viewer...', 'Enable','off','MenuSelectedFcn',@(~,~,~) obj.launchSuperModelViewer);
            obj.multiSubjectMenuContent.PrepareSuperModel = uimenu(obj.multiSubjectMenu,'Label','Prepare Project for Multi-Subject Viewer...', 'Enable','off','MenuSelectedFcn',@(~,~,~)obj.prepareForSuperModelViewer());
            obj.refreshSuperModelAvailability();

            obj.pipelineTree.Root.Name = 'Project';
            obj.treeNodes.Input        = uiw.widget.TreeNode('Name','Input',      'Parent',obj.pipelineTree.Root); % ,'UserData',0
            obj.treeNodes.Processing   = uiw.widget.TreeNode('Name','Processing', 'Parent',obj.pipelineTree.Root);
            obj.treeNodes.Output       = uiw.widget.TreeNode('Name','Output',     'Parent',obj.pipelineTree.Root);
            
            warning on;

            obj.ProgressBarTool = UnifiedProgressBar(obj.window);

        end

    end

    methods (Access = public)
        function openProject(obj,~,~,varargin)
            %openProject - callback from openProject menu button
            if ~isempty(varargin)
                folder=varargin{1};
            else
                folder=uigetdir(obj.getProjectDefaultPath(),'Select Project Folder');
            end
            
            obj.ProgressBarTool.suspendGUIWithMessage('Opening Project...');
            try
                if(folder ~= 0)
                    obj.setProjectDefaultPath(folder);
                    obj.closeProject();

                    [prj,pplFile]=Project.OpenProjectFromPath(folder);
                    obj.ProjectRunner=Runner.CreateFromProject(prj);
                    obj.createTreeView();
                    obj.createViews(pplFile,prj);
                    obj.configureAll();
                    %obj.updateTreeView();
                    %obj.Views.UpdateViews(obj.ProjectRunner.CurrentPipelineData);
                    obj.fileMenuContent.CloseProject.Enable='on';
                    if ~isdeployed
                        obj.multiSubjectMenuContent.PrepareSuperModel.Enable='on';
                    end
                    obj.ProgressBarTool.resumeGUI();
                end

            catch e
                logPath = VERAErrorLog('openProject', e);
                warning(getReport(e,'extended'));
                scrollableErrordlg(sprintf('Could not open project: %s%s', e.message, errorLogSuffix(logPath)));
            end
            delete(obj.componentMenu);
            obj.componentMenu=[];
            obj.ProgressBarTool.resumeGUI();
        end

        function reopenProject(obj,~,~)
            if isprop(obj.ProjectRunner,'Project')
                folder = obj.ProjectRunner.Project.Path;

                obj.ProgressBarTool.suspendGUIWithMessage('Opening Project...');
                try
                    if(folder ~= 0)
                        obj.setProjectDefaultPath(folder);
                        obj.closeProject();
                        
                        [prj,pplFile]=Project.OpenProjectFromPath(folder);
                        obj.ProjectRunner=Runner.CreateFromProject(prj);
                        obj.createTreeView();
                        obj.createViews(pplFile,prj);
                        obj.configureAll();
                        %obj.updateTreeView();
                        %obj.Views.UpdateViews(obj.ProjectRunner.CurrentPipelineData);
                        obj.fileMenuContent.CloseProject.Enable='on';
                        if ~isdeployed
                            obj.multiSubjectMenuContent.PrepareSuperModel.Enable='on';
                        end
                        obj.ProgressBarTool.resumeGUI();
                    end

                catch e
                    logPath = VERAErrorLog('reopenProject', e);
                    warning(getReport(e,'extended'));
                    scrollableErrordlg(sprintf('Could not reopen project: %s%s', e.message, errorLogSuffix(logPath)));
                end
                delete(obj.componentMenu);
                obj.componentMenu=[];
                obj.ProgressBarTool.resumeGUI();
            else
                error('Cannot reopen project! No project is currently open!')
            end
        end

        function runAll(obj)
            %runAll button callback
            %run through all components and check which one to best run next
            k=obj.ProjectRunner.GetNextReadyComponent();
            while(~isempty(k))
                obj.runComponent(k,false); %update view if last component
                obj.ProgressBarTool.resumeGUI();
            	obj.updateTreeView();

                k2=obj.ProjectRunner.GetNextReadyComponent();
                if(isempty(k2))
                    obj.Views.UpdateViews(obj.ProjectRunner.CurrentPipelineData);
                    drawnow;
                end
                k=k2;
            end
        end

        function reloadAll(obj)
            %reloadAll button callback
            %reload all components
            k=obj.ProjectRunner.GetNextReadyComponent();
            while(~isempty(k))
                obj.ProgressBarTool.suspendGUIWithMessage(['Reloading ' k]);
                obj.ProjectRunner.ReloadResults(k);
                obj.ProgressBarTool.resumeGUI();
            	obj.updateTreeView();

                k2 = obj.ProjectRunner.GetNextReadyComponent();
                if strcmp(k,k2)
                    break;
                end
                
                if(isempty(k2))
                    obj.Views.UpdateViews(obj.ProjectRunner.CurrentPipelineData);
                    drawnow; 
                end
                k = k2;
            end
        end

        function createNewProject(obj,varargin)
            % allow for input folder name to create new project
            if nargin > 1
                folder = varargin{1};
            else
                %createNewProject callback from createNewProject menu path
                folder=uigetdir(obj.getProjectDefaultPath(),'Select Project Folder');
            end
            obj.ProgressBarTool.suspendGUIWithMessage('Creating Project...');
    
            obj.ProgressBarTool.ShowProgressBar(0);
            try
            if(folder ~= 0)
                obj.setProjectDefaultPath(folder);
                if nargin > 2
                    pplineFile = varargin{2};
                else
                    rootpath = GetFullPath(fullfile(fileparts(mfilename('fullpath')),'..','..'));
                    avail_pipelFiles=dir(fullfile(rootpath,'PipelineDefinitions/*.pwf'));
                    if(length(avail_pipelFiles) == 1)
                        pplineFile=fullfile(avail_pipelFiles(1).folder,avail_pipelFiles(1).name);
                    else
                        %select pipeline
                        [idx,tf]=listdlg('PromptString','Select Pipeline','SelectionMode','single','ListString',{avail_pipelFiles.name});
                        if(tf ~= 0)
                            pplineFile=fullfile(avail_pipelFiles(idx).folder,avail_pipelFiles(idx).name);
                        else
                            obj.ProgressBarTool.resumeGUI();
                            return;
                        end
                    end
                end
                copyfile(pplineFile,fullfile(folder,'pipeline.pwf'));
                prj=Project.CreateProjectOnPath(folder,pplineFile);
                obj.ProjectRunner=Runner.CreateFromProject(prj);
                obj.createTreeView();
                obj.createViews(pplineFile,prj);
                obj.updateTreeView();
                if ~exist(fullfile(folder,'temp'),'dir')
                    mkdir(fullfile(folder,'temp'));
                end
                
                obj.fileMenuContent.CloseProject.Enable='on';
                if ~isdeployed
                    obj.multiSubjectMenuContent.PrepareSuperModel.Enable='on';
                end
            end
            catch e
                logPath = VERAErrorLog('createNewProject', e);
                warning(getReport(e));
                scrollableErrordlg(sprintf('Could not create project: %s%s', e.message, errorLogSuffix(logPath)));
            end
            delete(obj.componentMenu);
            obj.componentMenu=[];
            obj.ProgressBarTool.resumeGUI();
             
        end
        
        function configureAll(obj)
            %configureAll - configure all button callback
            % configures all 
            obj.ProgressBarTool.ShowProgressBar(0,'Configuring... ');
            if(obj.checkResolvedDependencies())
                for ic=1:length(obj.ProjectRunner.Components)
                        obj.configureComponent(obj.ProjectRunner.Components{ic},length(obj.ProjectRunner.Components) == ic);
                        obj.ProgressBarTool.ShowProgressBar(ic/length(obj.ProjectRunner.Components),'Configuring... ');
                end
                obj.updateTreeView();
                obj.ProgressBarTool.resumeGUI();
            end
        end

        function onClose(obj,hob,~)
            %onClose - close project callback
            obj.removeTempPath();

            DependencyHandler.Instance.SaveDependencyFile(MainGUI.resolveSettingsPath());

            delete(obj.Views);
            delete(obj.ProjectRunner);
            delete(hob);
            if DependencyHandler.Instance.IsDependency('ProjectPath')
                DependencyHandler.Instance.RemoveDependency('ProjectPath');
            end
            
        end

        function viewPipelineGraph(obj)
            if(~isempty(obj.ProjectRunner))
                figure;
                graph=obj.ProjectRunner.Project.Pipeline.GetDependencyGraph();
                plot(graph,'Layout','layered','Sources',obj.ProjectRunner.Project.Pipeline.GetInputComponentNames(),...
                    'Sinks',obj.ProjectRunner.Project.Pipeline.GetOutputComponentNames(),'EdgeLabel',graph.Edges.Name,'LineWidth',2,...
                'EdgeFontSize',12,'EdgeFontAngle','normal','NodeFontSize',16,'NodeFontAngle','normal', 'Interpreter', 'none',...
                'ArrowSize',12);
            end
        end

        function pipelineContentCheck(obj,~)
            if strcmp(obj.checkPipelineContent,'on')
                obj.checkPipelineContent = 'off';
                obj.configMenuContent.pipelineContentCheck.Checked = 'off';
            else
                obj.checkPipelineContent = 'on';
                obj.configMenuContent.pipelineContentCheck.Checked = 'on';
            end
        end

        function openPipelineDesigner(obj)
            if isprop(obj.ProjectRunner, 'Project')
                pipelinePath = fullfile(obj.ProjectRunner.Project.Path,'pipeline.pwf');
            else
                pipelinePath = [];

            end

            if isdeployed
                % Calling PipelineDesigner(...) in-process here hangs and
                % consumes runaway memory in the deployed app - appears to
                % be MATLAB Compiler's lazy p-code resolution for a
                % first-time call into a different top-level bundled
                % folder from deep inside an already-large, already-running
                % app, never completing. Launch the standalone
                % PipelineDesigner app (shipped as a sibling to this app)
                % as its own OS process instead - it inherits this
                % process's already-working runtime environment
                % (DYLD_LIBRARY_PATH etc.) since system() child processes
                % inherit the parent's environment.
                try
                    if ispc
                        % Unlike macOS's fixed, well-known
                        % .app/Contents/Resources nesting, how deep
                        % ctfroot() sits relative to the .exe on Windows
                        % isn't one documented constant across MATLAB
                        % Compiler versions/packaging options - NOT YET
                        % VALIDATED against a real Windows deployed build.
                        % Search upward from ctfroot() for a
                        % VERAPipelineDesigner.exe sibling instead of
                        % hardcoding a level count, so this keeps working
                        % (or fails with a clear message) even if the
                        % actual extraction depth differs from this guess.
                        pdAppPath = '';
                        searchDir = ctfroot;
                        for i = 1:5
                            candidate = fullfile(fileparts(searchDir), 'VERAPipelineDesigner.exe');
                            if exist(candidate, 'file')
                                pdAppPath = candidate;
                                break;
                            end
                            searchDir = fileparts(searchDir);
                        end
                        if isempty(pdAppPath)
                            error('VERAPipelineDesigner.exe not found near this app (searched upward from %s)', ctfroot);
                        end
                        if ~isempty(pipelinePath)
                            handoffFile = fullfile(tempdir, 'VERA_PipelineDesigner_startup.txt');
                            hfid = fopen(handoffFile, 'w');
                            fprintf(hfid, '%s', pipelinePath);
                            fclose(hfid);
                        end
                        % "start" launches detached (not blocking this
                        % process) - the empty "" is the required
                        % window-title placeholder when the target path
                        % itself is quoted.
                        system(sprintf('start "" "%s"', pdAppPath));
                    else
                        appBundle = fileparts(fileparts(fileparts(ctfroot))); % .../VERA.app
                        appsDir   = fileparts(appBundle);                     % shared build output dir
                        pdAppPath = fullfile(appsDir,'VERAPipelineDesigner.app');
                        if ~exist(pdAppPath,'dir')
                            error('VERAPipelineDesigner.app not found next to this app (expected at %s)', pdAppPath);
                        end
                        % Launch via macOS's "open" rather than exec'ing
                        % the bundled binary directly with a manually-built
                        % DYLD_LIBRARY_PATH: system() invokes commands
                        % through /bin/sh -c, and macOS strips/ignores
                        % DYLD_* env vars across that exec boundary for
                        % these binaries (a restricted-binary/SIP
                        % behavior), so the direct-exec form reliably
                        % failed to find its own runtime libraries when
                        % launched this way. "open" resolves everything
                        % through the app bundle itself and doesn't depend
                        % on inherited DYLD_LIBRARY_PATH at all.
                        %
                        % "open --args" does not reliably deliver argv to
                        % this app's varargin (confirmed empty even with
                        % "open -n" forcing a fresh process) - use a small
                        % handoff file instead, which PipelineDesigner
                        % checks for at startup (see
                        % loadStartupPipelineFromHandoff in PipelineDesigner.m).
                        if ~isempty(pipelinePath)
                            handoffFile = fullfile(tempdir, 'VERA_PipelineDesigner_startup.txt');
                            hfid = fopen(handoffFile, 'w');
                            fprintf(hfid, '%s', pipelinePath);
                            fclose(hfid);
                        end
                        cmd = sprintf('open -a "%s"', pdAppPath);
                        system(cmd);
                    end
                catch e
                    logPath = VERAErrorLog('openPipelineDesigner', e);
                    scrollableErrordlg(sprintf('Could not launch Pipeline Designer: %s%s', e.message, errorLogSuffix(logPath)));
                end
                return;
            end

            f = waitbar(0.3,'Opening Pipeline Designer...');

            try
                PipelineDesigner(pipelinePath);
            catch e
                logPath = VERAErrorLog('openPipelineDesigner', e);
                scrollableErrordlg(sprintf('Could not open Pipeline Designer: %s%s', e.message, errorLogSuffix(logPath)));
            end

            waitbar(1,f);
            close(f);
        end

        function openSettings(obj)
            %openSettings - "Settings" menu callback. Opens SettingsGUI
            %and, once that window is closed, persists any Dependency
            %changes to settings.xml and refreshes dependency-gated menu
            %items (e.g. the Multi-Subject Viewer launcher), since
            %Dependency values can change while it's open.
            settingsGUI = SettingsGUI();
            addlistener(settingsGUI.Parent, 'ObjectBeingDestroyed', @(~,~) obj.onSettingsClosed());
        end

        function onSettingsClosed(obj)
            %onSettingsClosed - SettingsGUI's table only updates the
            %in-memory DependencyHandler.Instance singleton
            %(SetDependency) on edit - it never writes settings.xml
            %itself. Previously that only happened in onClose/
            %closeProject, so Dependencies configured here were invisible
            %to anything that can't see this process's memory - notably
            %the deployed Pipeline Designer, which launches as its own OS
            %process (see openPipelineDesigner) and reads Dependencies
            %solely from settings.xml on disk. Save immediately when this
            %dialog closes so a freshly-configured Dependency is visible
            %there without requiring the project or VERA itself to be
            %closed first.
            DependencyHandler.Instance.SaveDependencyFile(MainGUI.resolveSettingsPath());
            obj.refreshSuperModelAvailability();
        end

        function refreshSuperModelAvailability(obj)
            %refreshSuperModelAvailability - Gray out the entire "Multi
            %Subject" dropdown when the optional VERA_SuperModel
            %Dependency isn't actually configured/found, since none of
            %its menu items (Launch or Prepare) are useful without it.
            %VERA_SuperModel is a standalone companion tool, not required
            %for any part of the pipeline - everything else in VERA works
            %normally whether or not it is set. '.' is the unresolved
            %placeholder value (see constructor) - never treated as
            %configured, even though it technically is an existing dir.
            %
            %Also gray out the whole dropdown (not just Launch) whenever
            %isdeployed, regardless of whether VERA_SuperModel is
            %configured - see launchSuperModelViewer for why Launch can
            %never work there (VERA_SuperModel has no compiled build, only
            %raw .m source, which a deployed app's MCR cannot execute).
            %Prepare Project is itself just a file copy and would work
            %fine deployed, but the whole feature is useless without
            %Launch, so keep the entire dropdown's on/off state simple
            %and consistent rather than enabling one option deployed users
            %still can't do anything with.
            available = DependencyHandler.Instance.IsDependency('VERA_SuperModel') && ...
                ~strcmp(DependencyHandler.Instance.GetDependency('VERA_SuperModel'),'.') && ...
                exist(DependencyHandler.Instance.GetDependency('VERA_SuperModel'),'dir');
            if isdeployed
                obj.multiSubjectMenu.Enable = 'off';
                tooltipText = ['The Multi-Subject Viewer (VERA_SuperModel) is not available in this ' ...
                    'standalone/deployed VERA app - it only ships as raw MATLAB source, which this app ' ...
                    'cannot execute. Run VERA from MATLAB directly to use this feature.'];
            elseif available
                obj.multiSubjectMenu.Enable = 'on';
                tooltipText = '';
            else
                obj.multiSubjectMenu.Enable = 'off';
                tooltipText = ['VERA_SuperModel is not configured. Get it from ' ...
                    'https://github.com/gtzook/VERA_SuperModel and set its install folder under Configuration > Settings.'];
            end
            % LaunchSuperModel's own Enable is independent of whether a
            % project is open, so it can mirror the dropdown's state
            % directly here. PrepareSuperModel still needs a project open
            % first - leave its Enable state to openProject/closeProject
            % (also guarded there by isdeployed, so it never flips back on
            % in a deployed app even once a project is opened).
            obj.multiSubjectMenuContent.LaunchSuperModel.Enable = obj.multiSubjectMenu.Enable;
            % uimenu's Tooltip property is only supported under a
            % uifigure - obj.window is a legacy figure() window, so this
            % throws there. Not worth the whole MainGUI constructor
            % failing over a hover tooltip - skip it if unsupported.
            try
                obj.multiSubjectMenu.Tooltip = tooltipText;
                obj.multiSubjectMenuContent.LaunchSuperModel.Tooltip = tooltipText;
            catch
            end
        end

        function launchSuperModelViewer(obj)
            %launchSuperModelViewer - "Launch Multi-Subject Viewer..."
            %menu callback. Launches VERA_SuperModel, a standalone
            %companion tool (separate repo) for viewing electrodes from
            %several already-processed VERA projects together on one
            %shared brain surface. Not part of VERA's own pipeline - its
            %install location is resolved as a 'folder' Dependency,
            %configurable under Configuration > Settings.
            if ~DependencyHandler.Instance.IsDependency('VERA_SuperModel') || ...
                    strcmp(DependencyHandler.Instance.GetDependency('VERA_SuperModel'),'.')
                % '.' is the unresolved placeholder value set in the
                % constructor - see refreshSuperModelAvailability.
                warndlg('VERA_SuperModel is not configured yet. Set its install folder under Configuration > Settings, then try again.', ...
                    'Launch Multi-Subject Viewer');
                return;
            end

            superModelPath = DependencyHandler.Instance.GetDependency('VERA_SuperModel');
            if ~exist(superModelPath,'dir')
                warndlg(sprintf('The configured VERA_SuperModel folder does not exist:\n%s', superModelPath), ...
                    'Launch Multi-Subject Viewer');
                return;
            end
            if ~exist(fullfile(superModelPath,'launch_viewer.m'),'file')
                warndlg(sprintf('launch_viewer.m was not found in the configured VERA_SuperModel folder:\n%s', superModelPath), ...
                    'Launch Multi-Subject Viewer');
                return;
            end

            % Unlike PipelineDesigner (see openPipelineDesigner), VERA_SuperModel
            % has no compiled/standalone build of its own - it only ever ships as
            % raw launch_viewer.m source in a user-configured folder. A deployed
            % VERA app runs inside the MATLAB Compiler Runtime, which can only
            % execute code baked into its own CTF archive at compile time - it
            % cannot parse/run arbitrary loose .m source discovered on disk at
            % runtime, no matter what gets addpath'ed. Calling launch_viewer()
            % below in that case previously failed silently (uncaught error in
            % a menu callback - MATLAB just beeps, there's no console window in
            % a deployed app to show the message), which is what "click the
            % menu item, hear a beep, nothing happens" was actually caused by.
            % Tell the user explicitly instead of attempting it.
            if isdeployed
                warndlg(['The Multi-Subject Viewer (VERA_SuperModel) cannot be launched from this ' ...
                    'standalone/deployed VERA app - it only exists as raw MATLAB source, and this ' ...
                    'app cannot execute unbundled .m files at runtime. Please run VERA from MATLAB ' ...
                    'directly to use this feature.'], 'Launch Multi-Subject Viewer');
                return;
            end

            % launch_viewer.m uses paths relative to its own folder (e.g.
            % addpath(genpath('FileFunctions')), a relative javaaddpath),
            % so it needs to run with that folder as the working
            % directory - restore the caller's directory afterward.
            currentDir = pwd;
            cleanupObj = onCleanup(@() cd(currentDir)); %#ok<NASGU>
            cd(superModelPath);
            addpath(superModelPath);

            % VERA_SuperModel's own folder picker (selectProjectFolders.m)
            % calls a raw Swing JFileChooser method synchronously, which
            % MATLAB auto-delegates to the AWT Event Dispatch Thread and
            % reports with a harmless but noisy warning - suppress just
            % for this call rather than editing that file.
            warnState = warning('off','all');
            cleanupWarn = onCleanup(@() warning(warnState)); %#ok<NASGU>
            try
                launch_viewer();
            catch e
                logPath = VERAErrorLog('launchSuperModelViewer', e);
                scrollableErrordlg(sprintf('Could not launch the Multi-Subject Viewer: %s%s', e.message, errorLogSuffix(logPath)));
            end
        end

        function prepareForSuperModelViewer(obj)
            %prepareForSuperModelViewer - "Prepare Project for
            %Multi-Subject Viewer..." menu callback.
            %
            %VERA_SuperModel (see launchSuperModelViewer) always looks
            %for a fixed file name - DataOutput/MNIbrain.mat - inside
            %each project folder it's pointed at. VERA itself lets output
            %component names (and therefore their saved .mat file names,
            %see MatOutput.m) be customized per pipeline, so there is no
            %way to guarantee that fixed name is used directly. Rather
            %than changing VERA_SuperModel to match VERA's naming, this
            %copies whichever DataOutput .mat file the user picks to that
            %fixed name, so VERA_SuperModel's own unmodified file
            %selection logic finds what it expects. No changes to
            %VERA_SuperModel are required.
            if ~isprop(obj.ProjectRunner,'Project') || isempty(obj.ProjectRunner.Project)
                warndlg('No project is currently open.', 'Prepare Project for Multi-Subject Viewer');
                return;
            end

            dataOutputDir = fullfile(obj.ProjectRunner.Project.Path,'DataOutput');
            if ~exist(dataOutputDir,'dir')
                warndlg(sprintf('No DataOutput folder found for this project:\n%s', dataOutputDir), ...
                    'Prepare Project for Multi-Subject Viewer');
                return;
            end

            [file,path] = uigetfile(fullfile(dataOutputDir,'*.mat'), ...
                'Select the output .mat file to use for the Multi-Subject Viewer (e.g. a Brain/MNI Cortex output)');
            if isequal(file,0)
                return;
            end
            sourceFile = fullfile(path,file);

            varNames = {whos('-file',sourceFile).name};
            if ~any(strcmp(varNames,'surfaceModel'))
                warndlg(sprintf('"%s" does not contain a surfaceModel variable - select a Brain/MNI Cortex (or similar) output file.', file), ...
                    'Prepare Project for Multi-Subject Viewer');
                return;
            end
            if ~any(strcmp(varNames,'electrodes'))
                % VERA_SuperModel's loadSubj() unconditionally does
                % elDef.Definition = electrodes.Definition right after
                % load(data,'electrodes') - since load() silently warns
                % rather than erroring when a variable isn't in the file,
                % a surface-only .mat here would make the viewer crash
                % with "Unrecognized variable 'electrodes'" once this
                % subject is loaded, not just show the surface. Refuse
                % rather than copy a file that is guaranteed to break it.
                warndlg(sprintf(['"%s" has no electrodes variable, so the Multi-Subject Viewer would fail to load it.\n\n' ...
                    'Add an Electrode Definition/Location input to this output component in the pipeline (so it saves electrodes alongside surfaceModel), then try again.'], file), ...
                    'Prepare Project for Multi-Subject Viewer');
                return;
            end

            destFile = fullfile(dataOutputDir,'MNIbrain.mat');
            if exist(destFile,'file')
                answer = questdlg('MNIbrain.mat already exists in this project''s DataOutput folder. Overwrite it?', ...
                    'Prepare Project for Multi-Subject Viewer','Overwrite','Cancel','Cancel');
                if ~strcmp(answer,'Overwrite')
                    return;
                end
            end

            copyfile(sourceFile, destFile);
            msgbox(sprintf('Copied to:\n%s\n\nThis project is now ready to be selected in the Multi-Subject Viewer.', destFile), ...
                'Prepare Project for Multi-Subject Viewer');
        end
    end
    
    methods (Access = protected)
        function closeProject(obj)
            %closeProject close project call delete all references save
            %everything cleanup
            delete(obj.Views);
            delete(obj.ProjectRunner);
            delete(obj.treeNodes.Input.Children);
            delete(obj.treeNodes.Processing.Children);
            delete(obj.treeNodes.Output.Children);
            
            for v=values(obj.componentNodes)
                delete(v{1});
            end

            %obj.ProgressBarTool.ShowProgressBar(obj,30);
            obj.componentNodes = containers.Map();
            for v = values(obj.viewTabs)
                delete(v{1});
            end

            DependencyHandler.Instance.SaveDependencyFile(MainGUI.resolveSettingsPath());

            obj.viewTabs = containers.Map();
            obj.fileMenuContent.CloseProject.Enable = 'off';
            obj.multiSubjectMenuContent.PrepareSuperModel.Enable = 'off';
            obj.removeTempPath();
            obj.pipelineTree.Root.Name = 'Project';
            delete(obj.componentMenu);
            obj.componentMenu = [];

        end
        
        function start_dir=getProjectDefaultPath(~)
            %getProjectDefaultPath - get the default directory path, either
            %if no default specified, create one
            if(DependencyHandler.Instance.IsDependency('ProjectDefaultPath'))
                start_dir=DependencyHandler.Instance.GetDependency('ProjectDefaultPath');
            else
                start_dir='./';
            end
        end
        
        function setProjectDefaultPath(~,path)
            if(~DependencyHandler.Instance.IsDependency('ProjectDefaultPath'))
                DependencyHandler.Instance.CreateAndSetDependency('ProjectDefaultPath',fileparts(path),'folder');
            end
        end

        function updateTreeView(obj)
            %updateTreeView - updates the Component pipeline view
            obj.ProgressBarTool.ShowProgressBar(0,'Updating Views');
            for v=values(obj.componentNodes)
                obj.ProgressBarTool.IncreaseProgressBar(1/length(obj.componentNodes));
                cName=v{1}.UserData;
                rootpath = GetFullPath(fullfile(fileparts(mfilename('fullpath')),'..','..'));
                switch (obj.ProjectRunner.GetComponentStatus(cName))
                    case 'Invalid'
                        setIcon(v{1},fullfile(rootpath,'/Icons/error.png'));
                    case 'Configured'
                        setIcon(v{1},fullfile(rootpath,'/Icons/configured1.png'));
                    case 'Ready'
                        setIcon(v{1},fullfile(rootpath,'/Icons/ready_1.png'));
                    case 'Completed'
                        setIcon(v{1},fullfile(rootpath,'/Icons/success.png'));
                end
            end
            drawnow();
            obj.ProgressBarTool.HideProgressBar();
        end
        
        function removeTempPath(obj)
            %removeTempPath - removing the temp path from the dependency
            %handler and delete the temp folder with all its contents
            if(any(strcmp(keys(DependencyHandler.Instance.ResolvedLibrary),'TempPath')))
                tdir=DependencyHandler.Instance.GetDependency('TempPath');
                if(isempty(tdir))
                    return;
                end
                try
                     rmdir(tdir,'s');
                catch e
                    VERAErrorLog('removeTempPath', e);
                    warning(e.message);
                end
                DependencyHandler.Instance.RemoveDependency('TempPath');
            end
            
        end
        
        function success=runTo(obj,component)
            %callback for rightclick - run to
            %determines the required components for a 
            comps_to_run=obj.ProjectRunner.GetProcessingSequence(component);
            success=1;
            obj.ProgressBarTool.ShowProgressBar(0,['Running ' component ' Dependents']);
            for i=1:length(comps_to_run)
                obj.ProgressBarTool.ShowProgressBar(i/length(comps_to_run),['Running ' component ' Dependents']);
                other_run_success=obj.runTo(comps_to_run{i});
                if(strcmp(obj.ProjectRunner.GetComponentStatus(comps_to_run{i}),'Ready'))
                    success=obj.runComponent(comps_to_run{i});
                    if(success == 0)
                        obj.updateTreeView();
                        obj.Views.UpdateViews(obj.ProjectRunner.CurrentPipelineData);
                        break;
                    end
                end
            end
            if(success == 1)
                if(strcmp(obj.ProjectRunner.GetComponentStatus(component),'Ready'))
                    obj.runComponent(component,true);
                end
            end
        end
        
        function createTreeView(obj)
            %createTreeView - delete the Treeview and create a new Tree
            delete(obj.componentMenu);
            if(~isempty(obj.ProjectRunner))
                obj.ProgressBarTool.ShowProgressBar(0.1,'Initializing Tree');
                delete(obj.treeNodes.Input.Children);
                delete(obj.treeNodes.Processing.Children);
                delete(obj.treeNodes.Output.Children);
                
                for v=values(obj.componentNodes)
                    delete(v{1});
                end
                obj.componentNodes=containers.Map();
                obj.pipelineTree.Root.Name=obj.ProjectRunner.Project.ProjectName;
                for k=obj.ProjectRunner.GetInputComponentNames()
                    v=uiw.widget.TreeNode('Name',k{1},'Parent',obj.treeNodes.Input,'UserData',k{1},'UIContextMenu',obj.buildContextMenu(k{1}));
                    obj.componentNodes(k{1})=v;
                end
                 obj.ProgressBarTool.ShowProgressBar(0.30);
                for k=obj.ProjectRunner.GetProcessingComponentNames()
                    v=uiw.widget.TreeNode('Name',k{1},'Parent',obj.treeNodes.Processing,'UserData',k{1},'UIContextMenu',obj.buildContextMenu(k{1}));
                    obj.componentNodes(k{1})=v;
                end
                obj.ProgressBarTool.ShowProgressBar(0.70);
                for k=obj.ProjectRunner.GetOutputComponentNames()
                    v=uiw.widget.TreeNode('Name',k{1},'Parent',obj.treeNodes.Output,'UserData',k{1},'UIContextMenu',obj.buildContextMenu(k{1}));
                    obj.componentNodes(k{1})=v;
                end
                obj.ProgressBarTool.ShowProgressBar(1);
            end

        end
        
        function cm=buildContextMenu(obj,compName)
                cm = uicontextmenu(obj.window);
                obj.addContextEntries(cm,compName);

                
        end
        
        function addContextEntries(obj,cm,compName)
                uimenu(cm,'Text','Configure','Callback', @(~,~) obj.configureComponent(compName,true));
                uimenu(cm,'Text','Run','Callback',@(~,~) obj.runComponent(compName,true));
                uimenu(cm,'Text','Run to here','Callback',@(~,~) obj.runTo(compName));
                uimenu(cm,'Text','Reset','Callback',@(~,~) obj.resetComponent(compName));
                uimenu(cm,'Text','Reload Results','Callback',@(~,~) obj.reloadResults(compName));

                uimenu(cm,'Text','Show Help','Callback',@(~,~) showDocumentation(obj.ProjectRunner.Project.Pipeline.GetComponent(compName)));
        end
        
        function reloadResults(obj,compName)
            obj.ProgressBarTool.suspendGUIWithMessage(['Reloading ' compName]);
            obj.ProjectRunner.ReloadResults(compName);
            obj.updateTreeView();
            obj.Views.UpdateViews(obj.ProjectRunner.CurrentPipelineData);
            obj.ProgressBarTool.resumeGUI();
        end
        
        function resetComponent(obj,compName)
            obj.ProgressBarTool.suspendGUIWithMessage(['Resetting Component ' compName]);
            obj.ProjectRunner.ResetComponent(compName);
            %obj.updateTreeView();
            %obj.Views.UpdateViews(obj.ProjectRunner.CurrentPipelineData);
            obj.configureComponent(compName,true);
            obj.ProgressBarTool.resumeGUI();
            
        end

        function configureComponent(obj,compName,updateView)
            if(~exist('updateView','var'))
                updateView=false;
            end
            if(~obj.checkResolvedDependencies())
                return;
            end
            vo=obj.componentNodes(compName);
            try
                obj.ProgressBarTool.suspendGUIWithMessage({'Running configuration for ' compName});
                
                % This will fail in the case where something was populated in the pipeline, then was removed
                if strcmp(obj.checkPipelineContent,'on')
                    obj.ProjectRunner.checkComponentContents(compName);
                end

                obj.ProjectRunner.ConfigureComponent(compName);
                vo.TooltipString='';
            catch e
                 vo.TooltipString=e.message;
                VERAErrorLog(['configureComponent:' compName], e);
                scrollableErrordlg(['Could not be configured: ' e.message],'Configure Failed');
            end
            if(updateView)
                obj.updateTreeView();
                obj.Views.UpdateViews(obj.ProjectRunner.CurrentPipelineData);
                obj.ProgressBarTool.resumeGUI();
                drawnow; 
            end

        end

        function success=runComponent(obj,compName,updateView)
            if(~exist('updateView','var'))
                updateView=false;
            end
            success=1;
            if(~obj.checkResolvedDependencies())
                success=0;
                return;
            end
            vo=obj.componentNodes(compName);
            try
                obj.ProgressBarTool.suspendGUIWithMessage({'Running component ' compName});

                obj.ProjectRunner.RunComponent(compName);
                vo.TooltipString='';
            catch e
                vo.TooltipString=e.message;
                VERAErrorLog(['runComponent:' compName], e);
                scrollableErrordlg(e.message, ['Error running ' compName]);
                success=0;
            end
            if(updateView)
                obj.updateTreeView();
                obj.Views.UpdateViews(obj.ProjectRunner.CurrentPipelineData);
                drawnow; 
            end
            obj.ProgressBarTool.resumeGUI();
        end

        function treeClick(obj,a,b)
            if(isprop(b,'Nodes') && any(isprop(b.Nodes,'UserData')) && ~isempty(b.Nodes.UserData))
                switch b.SelectionType
                    case 'normal'
                        %context=b.Nodes.UIContextMenu;
                            delete(obj.componentMenu);
                            obj.componentMenu=[];
                            if(any(strcmp(b.Nodes.Name,keys(obj.componentNodes))))
                                obj.componentMenu=uimenu(obj.window,'Text',b.Nodes.Name);
                                obj.addContextEntries(obj.componentMenu,b.Nodes.Name);
                            end
                    case 'open'
                            delete(obj.componentMenu);
                            obj.componentMenu=[];
                            if(any(strcmp(b.Nodes.Name,keys(obj.componentNodes))))
                                obj.componentMenu=uimenu(obj.window,'Text',b.Nodes.Name);
                                obj.addContextEntries(obj.componentMenu,b.Nodes.Name);
                            end
                            obj.runComponent(b.Nodes.Name,true);

                    otherwise
                        return;

                end
            
%                 %update Views
%                 vs=keys(obj.viewTabs);
%                 for i=1:length(vs)
%                     [res,comp]=obj.Views.IsComponentView(vs{i});
%                     if(res)
%                         vobj=obj.viewTabs(vs{i});
%                         if(strcmp(comp,b.Nodes.UserData))
%                             vobj.Parent=obj.mainView;
%                         else
%                             vobj.Parent=[];
%                         end
%                     end
%                 end
  
            end
        end           
        
        function createViews(obj,pipeline,prj)
           obj.viewTabs=containers.Map();
           delete(obj.mainView.Children);
           obj.Views=ViewMap.LoadViewsFromPipelineFile(pipeline,prj);
           delete(obj.mainView.Children);
           obj.ProgressBarTool.ShowProgressBar(0,'Creating Views');
           for v=keys(obj.Views.Views)
                t=uitab(obj.mainView,'Title',v{1});
                set(obj.Views.Views(v{1}),'Parent',t);
                if(obj.Views.IsComponentView(v{1}))
                    t.Parent=[];
                else
                    set(obj.Views.Views(v{1}),'Parent',t);
                end
                obj.viewTabs(v{1})=t;
                obj.ProgressBarTool.IncreaseProgressBar(1/length(keys(obj.Views.Views)));
           end
        end
        
        function res=checkResolvedDependencies(obj)
            missingDep={};
           for k=keys(DependencyHandler.Instance.RequestLibrary)
               if(~DependencyHandler.Instance.ResolvedLibrary.isKey(k{1}) && ~strcmp(DependencyHandler.Instance.GetDependencyType(k{1}),'internal'))
                   missingDep{end+1}=k{1};
               end
           end
           if(~isempty(missingDep))
               res=false;
               errordlg('Unresolved Project dependencies! Go to Configuration->Settings to resolve Issues!','Unresolved Dependencies','replace');
           else
               res=true;
           end
        end

    end

    methods (Static, Access = private)
        function p = resolveSettingsPath()
            %resolveSettingsPath - Where to read/write settings.xml.
            %   Deployed apps can't use the old mfilename-based repo path -
            %   it resolves inside the app bundle's read-only Resources,
            %   which only worked by accident when run from a self-owned
            %   build folder. Use the per-user app-data folder instead.
            if ~isdeployed
                rootpath = GetFullPath(fullfile(fileparts(mfilename('fullpath')),'..','..'));
                p = fullfile(rootpath,'settings.xml');
                return
            end

            if ispc
                appDataDir = fullfile(getenv('APPDATA'), 'VERA');
            else
                % Covers mac and any other isdeployed unix fallback.
                appDataDir = fullfile(getenv('HOME'), 'Library', 'Application Support', 'VERA');
            end

            if ~exist(appDataDir, 'dir')
                mkdir(appDataDir);
            end
            p = fullfile(appDataDir, 'settings.xml');
        end
    end

end

function s = errorLogSuffix(logPath)
    %errorLogSuffix - "(Full details logged to <path>)" note for an
    %errordlg, or '' if VERAErrorLog couldn't write anywhere at all (its
    %candidate list includes MATLAB's temp folder, which is always
    %writable per OS guarantee, so this should be rare in practice).
    if isempty(logPath)
        s = '';
    else
        s = sprintf('\n\n(Full details logged to %s)', logPath);
    end
end