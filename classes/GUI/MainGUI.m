

classdef MainGUI < handle
    %MAINGUI Summary of this class goes here
    %   Detailed explanation goes here
    
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
        suspendAnnotation=[];
        suspendBox=[];
        suspensionParent=[];
        viewTabs containers.Map
        componentNodes containers.Map

    end
    
    methods
        function obj = MainGUI()
            DependencyHandler.Purge();

            import uiextras.jTree.*
            obj.window=figure( ...
            'NumberTitle', 'off', ...
            'MenuBar', 'none', ...
            'Toolbar', 'none', ...
            'HandleVisibility', 'off','CloseRequestFcn',@obj.onClose);
            cameratoolbar(obj.window,'NoReset');
            if(exist('settings.xml','file'))
                DependencyHandler.Instance.LoadDependencyFile('settings.xml');
            end
            obj.viewTabs=containers.Map();
            obj.hBox=uix.HBoxFlex('Parent',obj.window);
            obj.suspendBox=uix.HBox('Parent',obj.window,'Background','w','units','normalized','Position',[0.2 0.3 0.6 0.4],'Visible','off');
            obj.suspendAnnotation=annotation(obj.suspendBox,'TextBox','string','','BackgroundColor','none','FontSize',15,...
                'units','normalized','Position',[0 0 1 1],'HorizontalAlignment','Center','VerticalAlignment','middle','LineWidth',4);
            obj.pipelineTree=uiw.widget.Tree('Parent',obj.hBox,'MouseClickedCallback',@obj.treeClick);
            obj.mainView=uitabgroup('Parent',obj.hBox);
            obj.hBox.Widths=[200 -1];
            % empty views
            
            obj.fileMenu=uimenu(obj.window,'Label','File');
            obj.fileMenuContent.NewProject=uimenu(obj.fileMenu,'Label','New Project','MenuSelectedFcn',@(~,~,~)obj.createNewProject);
            obj.fileMenuContent.OpenProject=uimenu(obj.fileMenu,'Label','Open Project','MenuSelectedFcn',@obj.openProject);
           % obj.fileMenuContent.SaveProject=uimenu(obj.fileMenu,'Label','Save Project','Enable','off','MenuSelectedFcn',@obj.saveProject);
           % obj.fileMenuContent.SaveProjectAs=uimenu(obj.fileMenu,'Label','Save Project as','Enable','off');
            obj.fileMenuContent.CloseProject=uimenu(obj.fileMenu,'Label','Close Project','Enable','off','MenuSelectedFcn',@(~,~,~)obj.closeProject);
            
            obj.configMenu=uimenu(obj.window,'Label','Configuration');
            obj.configMenuContent.Settings=uimenu(obj.configMenu,'Label','Settings','MenuSelectedFcn',@(~,~,~) SettingsGUI());
            obj.configMenuContent.ConfigAll=uimenu(obj.configMenu,'Label','Configure all Components','MenuSelectedFcn',@(~,~,~) obj.configureAll());
            obj.configMenuContent.ConfigAll=uimenu(obj.configMenu,'Label','Run all Components','MenuSelectedFcn',@(~,~,~) obj.runAll());
    
            obj.pipelineTree.Root.Name='Project';
            obj.treeNodes.Input=uiw.widget.TreeNode('Name','Input','Parent',obj.pipelineTree.Root,'UserData',0);
            obj.treeNodes.Processing=uiw.widget.TreeNode('Name','Processing','Parent',obj.pipelineTree.Root);
            obj.treeNodes.Output=uiw.widget.TreeNode('Name','Output','Parent',obj.pipelineTree.Root);


        end
        
    end
    
    methods (Access = protected)
        function closeProject(obj)
            delete(obj.Views);
            delete(obj.ProjectRunner);
            delete(obj.treeNodes.Input.Children);
            delete(obj.treeNodes.Processing.Children);
            delete(obj.treeNodes.Output.Children);
            for v=values(obj.componentNodes)
                delete(v{1});
            end
            obj.componentNodes=containers.Map();
            for v=values(obj.viewTabs)
                delete(v{1});
            end
            obj.viewTabs=containers.Map();
            obj.fileMenuContent.CloseProject.Enable='off';
            obj.removeTempPath();
        end
        
        
        function createNewProject(obj)
            folder=uigetdir('./','Select Project Folder');
            obj.suspendGUIWithMessage(obj,'Creating Project...');
            try
            if(folder ~= 0)
                avail_pipelFiles=dir('PipelineDefinitions\*.pwf');
                if(length(avail_pipelFiles) == 1)
                    pplineFile=fullfile(avail_pipelFiles(1).folder,avail_pipelFiles(1).name);
                else
                    %select pipeline
                    [idx,tf]=listdlg('PromptString','Select Pipeline','SelectionMode','single','ListString',{avail_pipelFiles.name});
                    if(tf ~= 0)
                        pplineFile=fullfile(avail_pipelFiles(idx).folder,avail_pipelFiles(idx).name);
                    else
                        obj.resumeGUI(obj);
                        return;
                    end
                end
                copyfile(pplineFile,fullfile(folder,'pipeline.pwf'));
                DependencyHandler.Instance.CreateAndSetDependency('ProjectPath',folder,'internal');
                prj=Project.CreateProjectOnPath(folder,pplineFile);
                obj.ProjectRunner=Runner.CreateFromProject(prj);
                obj.createTreeView();
                obj.createViews(pplineFile,prj);
                obj.updateTreeView();
                mkdir(fullfile(folder,'temp'));
                DependencyHandler.Instance.CreateAndSetDependency('TempPath',fullfile(folder,'temp'),'internal');
                
                obj.fileMenuContent.CloseProject.Enable='on';
            end
            catch e
                warning(e.message);
            end
            obj.resumeGUI(obj);
             
        end
       % function saveProject(obj,~,~)
       

        %end
        function openProject(obj,~,~)
            folder=uigetdir('./','Select Project Folder');
            obj.suspendGUIWithMessage(obj,'Opening Project...');
            try
                if(folder ~= 0)
                    obj.closeProject();
                    DependencyHandler.Instance.CreateAndSetDependency('ProjectPath',folder,'internal');
                    [prj,pplFile]=Project.OpenProjectFromPath(folder);
                    obj.ProjectRunner=Runner.CreateFromProject(prj);
                    obj.createTreeView();
                    obj.createViews(pplFile,prj);
                    obj.updateTreeView();
                    mkdir(fullfile(folder,'temp'));
                    DependencyHandler.Instance.CreateAndSetDependency('TempPath',fullfile(folder,'temp'),'internal');
                    obj.Views.UpdateViews(obj.ProjectRunner.CurrentPipelineData);
                end
                 obj.fileMenuContent.CloseProject.Enable='on';
                 obj.configureAll();
                 obj.resumeGUI(obj);
            catch e
                warning(e.message);
            end
            obj.resumeGUI(obj);
        end
        
        function updateTreeView(obj)
            for v=values(obj.componentNodes)
                cName=v{1}.UserData;
                switch (obj.ProjectRunner.GetComponentStatus(cName))
                    case 'Invalid'
                        setIcon(v{1},'./Icons/error.png');
                    case 'Configured'
                        setIcon(v{1},'./Icons/configured1.png');
                    case 'Ready'
                        setIcon(v{1},'./Icons/ready_1.png');
                    case 'Completed'
                        setIcon(v{1},'./Icons/success.png');
                end
            end
            drawnow();
        end
        
        function removeTempPath(obj)
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
        
        function onClose(obj,hob,~)
            obj.removeTempPath();
            DependencyHandler.Instance.SaveDependencyFile('settings.xml');
            delete(obj.Views);
            delete(obj.ProjectRunner);
            delete(hob);
            DependencyHandler.Instance.RemoveDependency('ProjectPath');
            
        end
        
        function configureAll(obj)
            for ic=1:length(obj.ProjectRunner.Components)
                    obj.configureComponent(obj.ProjectRunner.Components{ic},length(obj.ProjectRunner.Components) == ic);
            end
            obj.updateTreeView();
            obj.resumeGUI(obj);
        end
        
        function runAll(obj)
            k=obj.ProjectRunner.GetNextReadyComponent();
            while(~isempty(k))
                obj.runComponent(k,false); %update view if last component
                k2=obj.ProjectRunner.GetNextReadyComponent();
                if(isempty(k2))
                	obj.updateTreeView();
                    obj.Views.UpdateViews(obj.ProjectRunner.CurrentPipelineData);
                end
                k=k2;
                
            end
        end
        

        
        function createTreeView(obj)
            if(~isempty(obj.ProjectRunner))

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
                for k=obj.ProjectRunner.GetProcessingComponentNames()
                    v=uiw.widget.TreeNode('Name',k{1},'Parent',obj.treeNodes.Processing,'UserData',k{1},'UIContextMenu',obj.buildContextMenu(k{1}));
                    obj.componentNodes(k{1})=v;
                end
                for k=obj.ProjectRunner.GetOutputComponentNames()
                    v=uiw.widget.TreeNode('Name',k{1},'Parent',obj.treeNodes.Output,'UserData',k{1},'UIContextMenu',obj.buildContextMenu(k{1}));
                    obj.componentNodes(k{1})=v;
                end
            end

        end
        
        
        
        function cm=buildContextMenu(obj,compName)
                cm = uicontextmenu(obj.window);
                uimenu(cm,'Text','Configure','Callback', @(~,~) obj.configureComponent(compName,true));
                uimenu(cm,'Text','Run','Callback',@(~,~) obj.runComponent(compName,true));
                uimenu(cm,'Text','Reset','Callback',@(~,~) obj.resetComponent(compName));

                
        end
        
        function resetComponent(obj,compName)
            obj.suspendGUIWithMessage(obj,['Resetting Component ' compName]);
            obj.ProjectRunner.ResetComponent(compName);
            obj.updateTreeView();
            obj.Views.UpdateViews(obj.ProjectRunner.CurrentPipelineData);
            obj.resumeGUI(obj);
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
                obj.suspendGUIWithMessage(obj,{'Running configuration for ' compName});
                obj.ProjectRunner.ConfigureComponent(compName);
                vo.TooltipString='';
            catch e
                 vo.TooltipString=e.message;
                errordlg(e.message);
            end
            if(updateView)
                obj.updateTreeView();
                obj.Views.UpdateViews(obj.ProjectRunner.CurrentPipelineData);
            end
            obj.resumeGUI(obj);
        end
        
        function runComponent(obj,compName,updateView)
            if(~exist('updateView','var'))
                updateView=false;
            end
            if(~obj.checkResolvedDependencies())
                return;
            end
            vo=obj.componentNodes(compName);
            try
                obj.suspendGUIWithMessage(obj,{'Running component ' compName});
                obj.ProjectRunner.RunComponent(compName);
                vo.TooltipString='';
            catch e
                vo.TooltipString=e.message;
                errordlg(e.message);
            end
            if(updateView)
                obj.updateTreeView();
                obj.Views.UpdateViews(obj.ProjectRunner.CurrentPipelineData);
            end
            obj.resumeGUI(obj);
        end
        
        function treeClick(obj,a,b)
            if(isprop(b,'Nodes') && any(isprop(b.Nodes,'UserData')) && ~isempty(b.Nodes.UserData) && b.SelectionType == 'normal')
                
                %update Views
                vs=keys(obj.viewTabs);
                for i=1:length(vs)
                    [res,comp]=obj.Views.IsComponentView(vs{i});
                    if(res)
                        vobj=obj.viewTabs(vs{i});
                        if(strcmp(comp,b.Nodes.UserData))
                            vobj.Parent=obj.mainView;
                        else
                            vobj.Parent=[];
                        end
                    end
                end
            end
        end           
        

        
        function createViews(obj,pipeline,prj)
           obj.viewTabs=containers.Map();
           delete(obj.mainView.Children);
           obj.Views=ViewMap.LoadViewsFromPipelineFile(pipeline,prj);
           delete(obj.mainView.Children);
           for v=keys(obj.Views.Views)
                t=uitab(obj.mainView,'Title',v{1});
                set(obj.Views.Views(v{1}),'Parent',t);
                if(obj.Views.IsComponentView(v{1}))
                    t.Parent=[];
                else
                    set(obj.Views.Views(v{1}),'Parent',t);
                end
                obj.viewTabs(v{1})=t;
           end
        end
        
        function res=checkResolvedDependencies(obj)
            missingDep={};
           for k=keys(DependencyHandler.Instance.RequestLibrary)
               if(~DependencyHandler.Instance.ResolvedLibrary.isKey(k{1}))
                   missingDep{end+1}=k{1};
               end
           end
           if(~isempty(missingDep))
               res=false;
               errordlg('Unresolved Project dependencies! Go to Configuration->Settings to resolve Issues!');
           else
               res=true;
           end
        end

    end
    
    methods (Access = public)
        
        function suspendGUIWithMessage(obj,parent,msg)
            if(~isempty(obj.suspendAnnotation) && (strcmp(obj.suspendBox.Visible,'off') || (obj.suspensionParent==parent)))
                obj.suspensionParent=parent;
                 obj.suspendAnnotation.String=msg;
                obj.suspendBox.Visible='on';
               % uistack(obj.suspendAnnotation,'top');
               % enableDisableFig(obj.window,'off');
            
               drawnow;
            end
                %figure('units','pixels','position',[obj.window.Position(1)-obj.window.Position(3)/2 obj.window.Position(2)+obj.window.Position(4)/2 400 100],'windowstyle','modal');
                %uicontrol('style','text','string',msg,'units','pixels','position',[50 10 200 50]);
             
        end
        
        function resumeGUI(obj,parent)
            if(~isempty(obj.suspendBox) && ~isempty(obj.suspensionParent) &&(obj.suspensionParent==parent))
                obj.suspensionParent=[];
                obj.suspendBox.Visible='off';
%                enableDisableFig(obj.window,'on');
            end
        end
    end
end

