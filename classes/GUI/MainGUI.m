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
        fileMenuContent
        configMenuContent
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
            addToolbarExplorationButtons(obj.window);
            cameratoolbar(obj.window,'NoReset');
            if(exist('settings.xml','file'))
                rootpath = GetFullPath(fullfile(fileparts(mfilename('fullpath')),'..','..'));
                DependencyHandler.Instance.LoadDependencyFile(fullfile(rootpath,'settings.xml'));
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
            obj.configMenuContent.Settings             = uimenu(obj.configMenu,'Label','Settings',                 'MenuSelectedFcn',@(~,~,~) SettingsGUI());
            obj.configMenuContent.ConfigAll            = uimenu(obj.configMenu,'Label','Configure all Components', 'MenuSelectedFcn',@(~,~,~) obj.configureAll());
            obj.configMenuContent.RunAll               = uimenu(obj.configMenu,'Label','Run all Components',       'MenuSelectedFcn',@(~,~,~) obj.runAll());
            obj.configMenuContent.ReloadAll            = uimenu(obj.configMenu,'Label','Reload all Components',    'MenuSelectedFcn',@(~,~,~) obj.reloadAll());
            obj.configMenuContent.ViewPipeline         = uimenu(obj.configMenu,'Label','View Pipeline Graph',      'MenuSelectedFcn',@(~,~,~) obj.viewPipelineGraph());
            obj.configMenuContent.pipelineContentCheck = uimenu(obj.configMenu,'Label','Pipeline Content Check','Checked','on','MenuSelectedFcn',@(~,~,~)obj.pipelineContentCheck());
            
            obj.pipelineTree.Root.Name = 'Project';
            obj.treeNodes.Input        = uiw.widget.TreeNode('Name','Input',      'Parent',obj.pipelineTree.Root,'UserData',0);
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
                    obj.ProgressBarTool.resumeGUI();
                end

            catch e
                warning(getReport(e,'extended'));
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
                        obj.ProgressBarTool.resumeGUI();
                    end
    
                catch e
                    warning(getReport(e,'extended'));
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
            end
            catch e
                warning(getReport(e));
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

            if(exist('settings.xml','file'))
                rootpath = GetFullPath(fullfile(fileparts(mfilename('fullpath')),'..','..'));
                DependencyHandler.Instance.LoadDependencyFile(fullfile(rootpath,'settings.xml'));
            end
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
            
            f = waitbar(0.3,'Opening Pipeline Designer...');

            PipelineDesigner(pipelinePath);

            waitbar(1,f);
            close(f);
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

            if(exist('settings.xml','file'))
                rootpath = GetFullPath(fullfile(fileparts(mfilename('fullpath')),'..','..'));
                DependencyHandler.Instance.LoadDependencyFile(fullfile(rootpath,'settings.xml'));
            end

            obj.viewTabs = containers.Map();
            obj.fileMenuContent.CloseProject.Enable = 'off';
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
                errordlg(['Could not be configured: ' e.message],'Configure Failed','replace');
            end
            if(updateView)
                obj.updateTreeView();
                obj.Views.UpdateViews(obj.ProjectRunner.CurrentPipelineData);
                obj.ProgressBarTool.resumeGUI();
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
                errordlg(e.message);
                success=0;
            end
            if(updateView)
                obj.updateTreeView();
                obj.Views.UpdateViews(obj.ProjectRunner.CurrentPipelineData);
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
    
end