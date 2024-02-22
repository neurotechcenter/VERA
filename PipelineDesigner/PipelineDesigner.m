classdef PipelineDesigner < handle
    %PipelineDesigner VERA Pipeline Designer GUI
    
    properties (Access = public)
        ProjectRunner Runner
        Views %ViewMap
        pipeline
        viewComponent
        treeNodes
        pipelineTree
        pipelineName
        componentNodes containers.Map
        viewTabs containers.Map
        componentMenu
    end
    
    properties (Access = private)
        window
        hBox
        mainView
        fileMenu
        configMenu
        fileMenuContent
        configMenuContent
        ProgressBarTool

    end
    
    methods
        function obj = PipelineDesigner()
            
            DependencyHandler.Purge();
            obj.componentNodes = containers.Map();
            warning off;
            obj.window = figure('Name','VERA Pipeline Designer', ...
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
            obj.pipelineTree=uiw.widget.Tree('Parent',obj.hBox,'MouseClickedCallback',@obj.treeClick);
            obj.mainView=uitabgroup('Parent',obj.hBox);
            obj.hBox.Widths=[200 -1];
            % empty views
            
            obj.fileMenu=uimenu(obj.window,'Label','File');
            obj.fileMenuContent.NewPipeline   = uimenu(obj.fileMenu,'Label','New Pipeline','MenuSelectedFcn',@(~,~,~)obj.createNewPipeline);
            obj.fileMenuContent.OpenPipeline  = uimenu(obj.fileMenu,'Label','Open Pipeline','MenuSelectedFcn',@obj.openPipeline);
            obj.fileMenuContent.SavePipeline  = uimenu(obj.fileMenu,'Label','Save Pipeline','MenuSelectedFcn',@obj.savePipeline);
            obj.fileMenuContent.ClosePipeline = uimenu(obj.fileMenu,'Label','Close Pipeline','Enable','off','MenuSelectedFcn',@(~,~,~)obj.closePipeline);
            
            obj.configMenu=uimenu(obj.window,'Label','Configuration');
            obj.configMenuContent.Settings     = uimenu(obj.configMenu,'Label','Settings','MenuSelectedFcn',@(~,~,~) SettingsGUI());
            obj.configMenuContent.ViewPipeline = uimenu(obj.configMenu,'Label','View Pipeline Graph','MenuSelectedFcn',@(~,~,~) obj.viewPipelineGraph());
            
            obj.pipelineTree.Root.Name = 'Pipeline';
            obj.treeNodes.Input        = uiw.widget.TreeNode('Name','Input','Parent',obj.pipelineTree.Root,'UserData',0);
            obj.treeNodes.Processing   = uiw.widget.TreeNode('Name','Processing','Parent',obj.pipelineTree.Root);
            obj.treeNodes.Output       = uiw.widget.TreeNode('Name','Output','Parent',obj.pipelineTree.Root);
            obj.treeNodes.Views        = uiw.widget.TreeNode('Name','Views','Parent',obj.pipelineTree.Root);
            warning on;
            obj.ProgressBarTool=UnifiedProgressBar(obj.window);


        end
        
    end
    
    methods (Access = protected)
        function closePipeline(obj)
            %closeProject close project call delete all references save
            %everything cleanup
            % delete(obj.Views);
            delete(obj.ProjectRunner);
            delete(obj.treeNodes.Input.Children);
            delete(obj.treeNodes.Processing.Children);
            delete(obj.treeNodes.Output.Children);
            delete(obj.treeNodes.Views.Children);
            
            for v=values(obj.componentNodes)
                delete(v{1});
  
            end
            %obj.ProgressBarTool.ShowProgressBar(obj,30);
            obj.componentNodes=containers.Map();
            for v=values(obj.viewTabs)
                delete(v{1});
            end
            if ~isempty(obj.viewComponent)
                delete(obj.viewComponent);
            end
            obj.viewTabs=containers.Map();
            obj.fileMenuContent.CloseProject.Enable='off';
            obj.removeTempPath();
            obj.pipelineTree.Root.Name='Pipeline';
            delete(obj.componentMenu);
            obj.componentMenu=[];

        end
        
        function start_dir=getPipelineDefaultPath(~)
            %getProjectDefaultPath - get the default directory path, either
            %if no default specified, create one
            if(DependencyHandler.Instance.IsDependency('PipelineDefaultPath'))
                start_dir=DependencyHandler.Instance.GetDependency('PipelineDefaultPath');
            else
                start_dir='./';
            end
        end
        
        function setPipelineDefaultPath(~,path)
            if(~DependencyHandler.Instance.IsDependency('PipelineDefaultPath'))
                DependencyHandler.Instance.CreateAndSetDependency('PipelineDefaultPath',fileparts(path),'folder');
            end
        end
        
        function createNewPipeline(obj)
            %createNewProject callback from createNewProject menu path
            % not working

            % AddView exists

            folder=uigetdir(obj.getPipelineDefaultPath(),'Select Pipeline Folder');
            obj.ProgressBarTool.suspendGUIWithMessage('Creating Pipeline...');
    
            obj.ProgressBarTool.ShowProgressBar(0);
            try
            if(folder ~= 0)
                obj.setPipelineDefaultPath(folder);
                avail_pipelFiles=dir('PipelineDefinitions/*.pwf');
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
                copyfile(pplineFile,fullfile(folder,'pipeline.pwf'));
                prj=Project.CreateProjectOnPath(folder,pplineFile);
                obj.ProjectRunner=Runner.CreateFromProject(prj);
                obj.createTreeView();
                obj.createViews(pplineFile,prj);
                obj.updateTreeView();
                mkdir(fullfile(folder,'temp'));
                
                obj.fileMenuContent.CloseProject.Enable = 'on';
            end
            catch e
                warning(getReport(e));
            end
            delete(obj.componentMenu);
            obj.componentMenu = [];
            obj.ProgressBarTool.resumeGUI();
             
        end

        function openPipeline(obj,~,~)
            %openPipeline - callback from openPipeline menu button
            [file,folder]=uigetfile('*.pwf','Select Pipeline',obj.getPipelineDefaultPath());
            
            obj.ProgressBarTool.suspendGUIWithMessage('Opening Pipeline...');
            try
                if(folder ~= 0)
                    obj.setPipelineDefaultPath(folder);
                    obj.closePipeline();

                    % create pipeline
                    obj.pipeline     = Pipeline.CreateFromPipelineDefinition(fullfile(folder,file));
                    obj.pipelineName = file;

                    % create views
                    % prj          = Project.CreateProjectOnPath(folder,file);
                    % obj.Views    = ViewMap.LoadViewsFromPipelineFile(fullfile(folder,file),prj);

                    % if(isObjectTypeOf(pipeline,'Pipeline'))
                    %     ppline=pipeline;
                    % else
                    %     ppline=Pipeline.CreateFromPipelineDefinition(pipeline);
                    % end
            
                    % prj=Project.Project();
                    % prj.Path        = [];
                    % prj.ProjectName = 'pipeline';
                    % prj.Pipeline    = obj.pipeline;
                    % obj.Views       = ViewMap.LoadViewsFromPipelineFile(fullfile(folder,file),prj);

                    % gotta get views in a weird way
                    poss_p=xml2struct(fullfile(folder,file));

                    for i = 1:size(poss_p.PipelineDefinition{1}.View,2)
                        views{i}=ObjectFactory.CreateView(poss_p.PipelineDefinition{1}.View{i}.Attributes.Type,poss_p.PipelineDefinition{1}.View{i});
                    end
                    
                    obj.Views = views;

                    % obj.Views = obj.LoadViewsFromPipelineFile(fullfile(folder,file));


                    obj.viewTabs = containers.Map();

                    obj.createTreeView();

                    obj.fileMenuContent.CloseProject.Enable = 'on';
                    obj.ProgressBarTool.resumeGUI();
                end

            catch e
                warning(getReport(e,'extended'));
            end
            delete(obj.componentMenu);
            obj.componentMenu = [];
            obj.ProgressBarTool.resumeGUI();
        end
        
        function savePipeline(obj,~,~)
            %savePipeline - callback from savePipeline menu button
            [file,folder]=uiputfile('*.pwf','Select Pipeline Save Filename',obj.getPipelineDefaultPath());
            % folder = '/Users/jamesswift/Documents/git/VERA/PipelineDefinitions';
            % file   = '0_test.pwf';
            
            obj.ProgressBarTool.suspendGUIWithMessage('Saving Pipeline...');
            try
                if(folder ~= 0)
                    obj.setPipelineDefaultPath(folder);
                    % obj.closePipeline();

                    % components
                    compNames = obj.pipeline.Components;
                    for i = 1:size(compNames,2)
                        % Create matlab struct from class definition
                        currentComponent  = obj.pipeline.GetComponent(compNames{i});

                        warning off;
                        scurrentComponent = struct(currentComponent);
                        warning on;

                        % Get proper component type
                        currentComponentClassName = class(currentComponent);

                        inputStruct = [];
                        inputStruct.(currentComponentClassName) = scurrentComponent;

                        compprops = properties(currentComponent);
                        fnames    = fieldnames(scurrentComponent);

                        % if a property is not editable, remove it from the list
                        SetAccessProps = {};
                        for j = 1:length(compprops)
                            SetAccessProps{j} = findprop(currentComponent,compprops{j}).SetAccess;
                        end

                        fields2keep   = compprops(strcmp(SetAccessProps,'public'));
                        fields2remove = setdiff(fnames,fields2keep);

                        % also remove weird fields that were added when
                        % converting from classdef to struct
                        inputStruct.(currentComponentClassName) = rmfield(inputStruct.(currentComponentClassName),fields2remove);

                        % make sure empty cells are char
                        for j = 1:length(fields2keep)
                            if isempty(inputStruct.(currentComponentClassName).(fields2keep{j}))
                                inputStruct.(currentComponentClassName).(fields2keep{j}) = '';
                            end
                        end

                        % Generate xml code for individual components
                        Componentxml{i} = struct2xml(inputStruct);
                        Componentxml{i} = erase(Componentxml{i},'<?xml version="1.0" encoding="utf-8"?>');
                        Componentxml{i} = replace(Componentxml{i},['<',currentComponentClassName,'>'],['<Component Type="',currentComponentClassName,'">']);
                        Componentxml{i} = replace(Componentxml{i},['</',currentComponentClassName,'>'],'</Component>');
                    end


                    % Views
                    views = obj.Views;
                    for i = 1:size(views,2)
                        ViewList{i} = views{i}.Name;
                    end
                    for i = 1:length(views)
                        currentView = views{i};
                        warning off;
                        scurrentView = struct(currentView);
                        warning on;

                        % Get proper component type
                        currentViewClassName = class(currentView);

                        inputStruct = [];
                        inputStruct.(currentViewClassName) = scurrentView;

                        viewprops = properties(currentView);
                        uixprops  = properties(uix.Grid);
                        fnames    = fieldnames(scurrentView);

                        % if a property is not editable, remove it from the list
                        SetAccessProps = {};
                        DefiningClassProps = {};
                        for j = 1:length(viewprops)
                            SetAccessProps{j}     = findprop(currentView,viewprops{j}).SetAccess;
                            DefiningClassProps{j} = findprop(currentView,viewprops{j}).DefiningClass.Name;
                        end

                        % remove uix properties from list to avoid writing
                        % these to pipeline file
                        externalclass2remove = viewprops(logical(contains(DefiningClassProps,'AView') .* ~strcmp(viewprops,'Name')'));
                        externalclass2remove = [externalclass2remove; viewprops(contains(DefiningClassProps,'uix'))];
                        externalclass2remove = [externalclass2remove; viewprops(contains(DefiningClassProps,'matlab'))];

                        fields2keep   = viewprops(strcmp(SetAccessProps,'public'));
                        fields2remove = setdiff(fnames,fields2keep);
                        fields2remove = unique([externalclass2remove; fields2remove]);

                        % also remove weird fields that were added when
                        % converting from classdef to struct
                        inputStruct.(currentViewClassName) = rmfield(inputStruct.(currentViewClassName),fields2remove);

                        fieldsfinal = fieldnames(inputStruct.(currentViewClassName));

                        % make sure empty cells are char
                        for j = 1:length(fieldsfinal)
                            if isempty(inputStruct.(currentViewClassName).(fieldsfinal{j}))
                                inputStruct.(currentViewClassName).(fieldsfinal{j}) = '';
                            end
                        end

                        % Generate xml code for individual components
                        Viewxml{i} = struct2xml(inputStruct);
                        Viewxml{i} = erase(Viewxml{i},'<?xml version="1.0" encoding="utf-8"?>');
                        Viewxml{i} = replace(Viewxml{i},['<',currentViewClassName,'>'],['<View Type="',currentViewClassName,'">']);
                        Viewxml{i} = replace(Viewxml{i},['</',currentViewClassName,'>'],'</View>');
                    end

                    obj.pipelineName = file;

                    % Generate pipeline xml
                    pipelinexml = ['<?xml version="1.0" encoding="utf-8"?>', ...
                                    newline,...
                                    '<PipelineDefinition Name="',obj.pipelineName,'">'];
                    
                    for i = 1:length(Componentxml)
                        pipelinexml = [pipelinexml,...
                                        newline,...
                                        Componentxml{i}];
                    end

                    for i = 1:length(Viewxml)
                        pipelinexml = [pipelinexml,...
                                        newline,...
                                        Viewxml{i}];
                    end

                    % End pipeline file
                    pipelinexml = [pipelinexml,... 
                                    newline,...
                                    newline,...
                                    '</PipelineDefinition>'];

                    % Save pipeline xml file (pwf)
                    fid = fopen(fullfile(folder,file),'w'); % open file for writing (overwrite if necessary)
                    fprintf(fid,'%s',pipelinexml);          % Write the char array, interpret newline as new line
                    fclose(fid);     

                    obj.createTreeView();

                    obj.fileMenuContent.CloseProject.Enable='on';
                    obj.ProgressBarTool.resumeGUI();
                end

            catch e
                warning(getReport(e,'extended'));
            end
    
            % obj.updateTreeView();

            delete(obj.componentMenu);
            obj.componentMenu=[];
            obj.ProgressBarTool.resumeGUI();
        end

        function createTreeView(obj)
            %createTreeView - delete the Treeview and create a new Tree
            delete(obj.componentMenu);
            if(~isempty(obj.pipeline))
                obj.ProgressBarTool.ShowProgressBar(0.1,'Initializing Tree');
                delete(obj.treeNodes.Input.Children);
                delete(obj.treeNodes.Processing.Children);
                delete(obj.treeNodes.Output.Children);
                delete(obj.treeNodes.Views.Children);
                
                for v = values(obj.componentNodes)
                    delete(v{1});
                end
                for v = values(obj.viewTabs)
                    delete(v{1});
                end

                obj.componentNodes         = containers.Map();
                obj.viewTabs               = containers.Map();
                obj.pipelineTree.Root.Name = obj.pipelineName;
                % for k = obj.pipeline.GetInputComponentNames()
                %     compdef = class(obj.pipeline.GetComponent(k{1}));
                %     v       = uiw.widget.TreeNode('Name',compdef,'Parent',obj.treeNodes.Input,'UserData',compdef,'UIContextMenu',obj.buildContextMenu(compdef));
                %     obj.componentNodes(compdef) = v;
                % end
                %  obj.ProgressBarTool.ShowProgressBar(0.25);
                % for k = obj.pipeline.GetProcessingComponentNames()
                %     compdef = class(obj.pipeline.GetComponent(k{1}));
                %     v       = uiw.widget.TreeNode('Name',compdef,'Parent',obj.treeNodes.Processing,'UserData',compdef,'UIContextMenu',obj.buildContextMenu(compdef));
                %     obj.componentNodes(compdef) = v;
                % end
                % obj.ProgressBarTool.ShowProgressBar(0.50);
                % for k = obj.pipeline.GetOutputComponentNames()
                %     compdef = class(obj.pipeline.GetComponent(k{1}));
                %     v       = uiw.widget.TreeNode('Name',compdef,'Parent',obj.treeNodes.Output,'UserData',compdef,'UIContextMenu',obj.buildContextMenu(compdef));
                %     obj.componentNodes(compdef) = v;
                % end
                % obj.ProgressBarTool.ShowProgressBar(0.75);
                % for k = 1:size(obj.Views,2)
                %     viewname = class(obj.Views{k});
                %     v        = uiw.widget.TreeNode('Name',viewname,'Parent',obj.treeNodes.Views,'UserData',viewname,'UIContextMenu',obj.buildContextMenu(viewname));
                %     obj.viewTabs(viewname) = v;
                % end
                % obj.ProgressBarTool.ShowProgressBar(1);

                for k=obj.pipeline.GetInputComponentNames()
                    v=uiw.widget.TreeNode('Name',k{1},'Parent',obj.treeNodes.Input,'UserData',k{1},'UIContextMenu',obj.buildContextMenu(k{1}));
                    obj.componentNodes(k{1})=v;
                end
                 obj.ProgressBarTool.ShowProgressBar(0.25);
                for k=obj.pipeline.GetProcessingComponentNames()
                    v=uiw.widget.TreeNode('Name',k{1},'Parent',obj.treeNodes.Processing,'UserData',k{1},'UIContextMenu',obj.buildContextMenu(k{1}));
                    obj.componentNodes(k{1})=v;
                end
                obj.ProgressBarTool.ShowProgressBar(0.50);
                for k=obj.pipeline.GetOutputComponentNames()
                    v=uiw.widget.TreeNode('Name',k{1},'Parent',obj.treeNodes.Output,'UserData',k{1},'UIContextMenu',obj.buildContextMenu(k{1}));
                    obj.componentNodes(k{1})=v;
                end
                obj.ProgressBarTool.ShowProgressBar(0.75);
                for k = 1:size(obj.Views,2)
                    viewname = obj.Views{k}.Name;
                    v        = uiw.widget.TreeNode('Name',viewname,'Parent',obj.treeNodes.Views,'UserData',viewname,'UIContextMenu',obj.buildContextMenu(viewname));
                    obj.viewTabs(viewname) = v;
                end
                obj.ProgressBarTool.ShowProgressBar(1);
            end

        end

        function updateTreeView(obj)
            %updateTreeView - updates the Component pipeline view
            obj.ProgressBarTool.ShowProgressBar(0,'Updating Views');
            for v=values(obj.componentNodes)
                obj.ProgressBarTool.IncreaseProgressBar(1/length(obj.componentNodes));
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
        
        function onClose(obj,hob,~)
            %onClose - close project callback
            obj.removeTempPath();
            DependencyHandler.Instance.SaveDependencyFile('settings.xml');
            delete(obj.ProjectRunner);
            % delete(obj.Views);
            delete(hob);
            DependencyHandler.Instance.RemoveDependency('ProjectPath');
            
        end
       
        function cm=buildContextMenu(obj,compName)
            cm = uicontextmenu(obj.window);
            obj.addContextEntries(cm,compName);
        end
        
        function addContextEntries(obj,cm,compName)
            uimenu(cm,'Text','View Component','Callback', @(~,~) obj.ViewComponent(compName));
            uimenu(cm,'Text','Show Help','Callback',@(~,~) showDocumentation(obj.ProjectRunner.Project.Pipeline.GetComponent(compName)));
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

            % idx = 1;
            % for i = obj.pipeline.GetInputComponentNames()
            %     InputList{idx}      = class(obj.pipeline.GetComponent(i{1}));
            %     idx = idx + 1;
            % end
            % idx = 1;
            % for i = obj.pipeline.GetProcessingComponentNames()
            %     ProcessingList{idx} = class(obj.pipeline.GetComponent(i{1}));
            %     idx = idx + 1;
            % end
            % idx = 1;
            % for i = obj.pipeline.GetOutputComponentNames()
            %     OutputList{idx}     = class(obj.pipeline.GetComponent(i{1}));
            %     idx = idx + 1;
            % end
            % views = obj.Views;
            % for i = 1:size(views,2)
            %     ViewList{i} = class(views{i});
            % end

            InputList      = obj.pipeline.GetInputComponentNames();
            ProcessingList = obj.pipeline.GetProcessingComponentNames();
            OutputList     = obj.pipeline.GetOutputComponentNames();

            views = obj.Views;
            for i = 1:size(views,2)
                ViewList{i} = views{i}.Name;
            end
            

            if any(contains(InputList,compName)) || any(contains(ProcessingList,compName)) || any(contains(OutputList,compName))
                vo               = obj.componentNodes(compName);
                currentComponent = obj.pipeline.GetComponent(compName);
            elseif any(contains(ViewList,compName))
                vo               = obj.viewTabs(compName);
                viewidx          = strcmp(ViewList,compName);
                currentComponent = views{viewidx};
            end

            try
                obj.ProgressBarTool.suspendGUIWithMessage({'Running component ' compName});

                % [inputs, outputs, optInputs] = obj.pipeline.InterfaceInformation(compName);

                proplist = properties(currentComponent);

                % if a property is not editable, remove it from the list
                SetAccessProps = {};
                for j = 1:length(proplist)
                    SetAccessProps{j} = findprop(currentComponent,proplist{j}).SetAccess;
                end

                proplist = proplist(strcmp(SetAccessProps,'public'));

                DefiningClassProps = {};
                for j = 1:length(proplist)
                    DefiningClassProps{j} = findprop(currentComponent,proplist{j}).DefiningClass.Name;
                end

                % remove uix properties from list to avoid writing
                % these to pipeline file
                externalclass2remove = proplist(logical(contains(DefiningClassProps,'AView') .* ~strcmp(proplist,'Name')'));
                externalclass2remove = [externalclass2remove; proplist(contains(DefiningClassProps,'uix'))];
                externalclass2remove = [externalclass2remove; proplist(contains(DefiningClassProps,'matlab'))];

                proplist = setdiff(proplist,externalclass2remove);


                % make everything in the table char
                colformat = cell(size(proplist))';
                for i = 1:size(proplist,1)
                    colformat{i} = 'char';
                end

                % block editing of "inputs" for input components (only have outputs)
                coleditable = strcmp(SetAccessProps,'public');

                % Change cells to strings to be displayed in table
                tbl = cell(size(proplist));
                for i = 1:size(proplist,1)
                    tbl{i} = currentComponent.(proplist{i});
                    if iscell(tbl{i})
                        newentry = [];
                        for j = 1:size(tbl{i},2)
                            newentry = [newentry, char(tbl{i}{j}), '; '];
                        end
                        tbl{i} = newentry;
                    end
                end

                % Convert empty cells to char
                for i = 1:size(tbl,1)
                    if isempty(tbl{i,1})
                        tbl{i,1} = '';
                    end
                end

                tbl = tbl';

                % Create table to display component information
                if ~isempty(obj.viewComponent)
                    delete(obj.viewComponent);
                end

                obj.viewComponent=uitable('Parent',obj.window,...
                 'ColumnName',proplist',...
                 'ColumnFormat',colformat,...
                 'ColumnEditable',coleditable,...
                 'CellEditCallback',@(~,~)obj.compUpdate(compName,proplist,tbl));


                % Populate table
                obj.viewComponent.Data = tbl;

                % Position table (work in progress)
                window_size   = get(obj.window,   'outerposition');
                mainView_size = get(obj.mainView, 'outerposition');
                hBox_size     = get(obj.hBox,     'outerposition');

                obj.viewComponent.Units    = 'normalized';
                obj.viewComponent.Position = [1.05-mainView_size(3)/window_size(3) mainView_size(3)/window_size(3) 1.2*obj.viewComponent.Extent(3) 2*obj.viewComponent.Extent(4)];
                % obj.viewComponent.Position = [0.25 0.8 1.2*obj.viewComponent.Extent(3) 2*obj.viewComponent.Extent(4)];
                % obj.viewComponent.Position = [window_size(3)/mainView_size(3)-1.05 1.9-window_size(4)/mainView_size(4) 1.2*obj.viewComponent.Extent(3) 2*obj.viewComponent.Extent(4)];

                vo.TooltipString='';

                % obj.createTreeView();

            catch e
                vo.TooltipString=e.message;
                errordlg(e.message);
                success=0;
            end

            obj.ProgressBarTool.resumeGUI();
        end

        function compUpdate(obj,compName,proplist,tbl_orig)

            InputList      = obj.pipeline.GetInputComponentNames();
            ProcessingList = obj.pipeline.GetProcessingComponentNames();
            OutputList     = obj.pipeline.GetOutputComponentNames();
            for i = 1:size(obj.Views,2)
                ViewList{i} = obj.Views{i}.Name;
            end

            tbl_modified = obj.viewComponent.Data;

            % Compare original table to new table, only change things that changed
            compared = zeros(size(tbl_orig));
            for i = 1:size(tbl_orig,2)
                if ~strcmp(tbl_orig{i},tbl_modified{i})
                    compared(i) = 1;
                end
            end

            % update table
            for i = 1:size(compared,2)
                if compared(i) == 1
                    if any(strcmp(InputList,compName)) || any(strcmp(ProcessingList,compName)) || any(strcmp(OutputList,compName))
                        obj.pipeline.GetComponent(compName).(proplist{i}) = tbl_modified{i};
                    elseif any(strcmp(ViewList,compName))
                        obj.Views{strcmp(ViewList,compName)}.(proplist{i}) = tbl_modified{i};
                    end
                end
            end

            % orig_name      = tbl_orig{strcmp(proplist,'Name')};
            % new_name       = tbl_modified{strcmp(proplist,'Name')};
            % 
            % InputList      = obj.pipeline.GetInputComponentNames();
            % ProcessingList = obj.pipeline.GetProcessingComponentNames();
            % OutputList     = obj.pipeline.GetOutputComponentNames();
            
            % if any(strcmp(InputList,orig_name))
            %     InputList{strcmp(InputList,orig_name)}           = new_name;
            % end
            % if any(strcmp(ProcessingList,orig_name))
            %     ProcessingList{strcmp(ProcessingList,orig_name)} = new_name;
            % end
            % if any(strcmp(OutputList,orig_name))
            %     OutputList{strcmp(OutputList,orig_name)}         = new_name;
            % end

            % obj.pipeline.Components = [InputList, ProcessingList, OutputList];

            % obj.updateTreeView();
            obj.createTreeView();

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

