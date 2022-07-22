classdef UnifiedProgressBar < handle
    %UNIFIEDLOADINGBAR Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        suspendBox=[];
        suspendAnnotation=[];
        progressBar=[];
        progressAnnotation=[];
        dependencyProgress=[]; 
        barHeight=0.1;
        supercede
    end
    
    methods
        function obj=UnifiedProgressBar(handle,supercede)
            obj.supercede=false;
            obj.suspendBox=uix.HBox('Parent',handle,'Background','w','units','normalized','Position',[0.2 0.3 0.6 0.4],'Visible','off');
            obj.suspendAnnotation=annotation(obj.suspendBox,'TextBox','string','','BackgroundColor','none','FontSize',15,...
                'units','normalized','Position',[0 0 1 1],'HorizontalAlignment','Center','VerticalAlignment','middle','LineWidth',4,'Interpreter','none');

            obj.progressBar=uix.HBox('Parent',obj.suspendBox,'units','normalized','Position',[0 0 0 obj.barHeight],'Visible','off','Background',[0.4 0.4 1]);
            obj.progressAnnotation=annotation(obj.suspendBox,'TextBox','string','','BackgroundColor','none','FontSize',12,'LineStyle','none',...
                'units','normalized','Position',[0 obj.barHeight 1 obj.barHeight],'Interpreter','none','VerticalAlignment','middle','HorizontalAlignment','center');
            if(exist('supercede','var') && supercede)
                obj.supercede=true;
                if(DependencyHandler.Instance.IsDependency('unifiedProgressbar')) % if dependency already exists, store old value and restore on release, otherwise create
                    if(DependencyHandler.Instance.GetDependency('unifiedProgressbar') ~= obj)
                        obj.dependencyProgress=DependencyHandler.Instance.GetDependency('unifiedProgressbar');
                        DependencyHandler.Instance.SetDependency('unifiedProgressbar',obj);
                    end
                else
                    DependencyHandler.Instance.CreateAndSetDependency('unifiedProgressbar',obj,'internal');
                end
            end
            
        end

        function Detach(obj)
            if(~obj.supercede)
                error("Detaching is only valid for superceding Progressbars");
            end
            obj.resumeGUI();
             if(~isempty(obj.dependencyProgress))
                DependencyHandler.Instance.SetDependency('unifiedProgressbar',obj.dependencyProgress);
                obj.dependencyProgress=[];
            else
                if(DependencyHandler.Instance.IsDependency('unifiedProgressbar'))
                    DependencyHandler.Instance.RemoveDependency('unifiedProgressbar');
                end
            end
        end

        function b=IsSuspended(obj)
            b=strcmp(obj.suspendBox.Visible,'on');
        end

        function suspendGUIWithMessage(obj,msg)
            if(~obj.supercede)
                if(DependencyHandler.Instance.IsDependency('unifiedProgressbar')) % if dependency already exists, store old value and restore on release, otherwise create
                    if(DependencyHandler.Instance.GetDependency('unifiedProgressbar') ~= obj)
                        obj.dependencyProgress=DependencyHandler.Instance.GetDependency('unifiedProgressbar');
                        DependencyHandler.Instance.SetDependency('unifiedProgressbar',obj);
                    end
                else
                    DependencyHandler.Instance.CreateAndSetDependency('unifiedProgressbar',obj,'internal');
                end
            end
            if(~isempty(obj.suspendAnnotation) && (strcmp(obj.suspendBox.Visible,'off') || compareStrings(obj.suspendAnnotation.String,msg)))
                 obj.suspendAnnotation.String=msg;
                obj.suspendBox.Visible='on';
                drawnow;
               % uistack(obj.suspendAnnotation,'top');
               % enableDisableFig(obj.window,'off');

            end
                %figure('units','pixels','position',[obj.window.Position(1)-obj.window.Position(3)/2 obj.window.Position(2)+obj.window.Position(4)/2 400 100],'windowstyle','modal');
                %uicontrol('style','text','string',msg,'units','pixels','position',[50 10 200 50]);
             
        end

        function ShowProgressBar(obj,percent,name)
            if(obj.supercede)
                obj.suspendGUIWithMessage(name);
                name='';
            end
            if(~isempty(obj.progressBar))
                obj.progressBar.Units='normalized';
                obj.progressBar.Position=[0 0 min(percent,1) obj.barHeight];
                obj.progressBar.Visible='on';
                if(exist('name','var'))
                    obj.progressAnnotation.String=name;
                    obj.progressAnnotation.Visible='on';
                end
                drawnow;
            end
        end
        function IncreaseProgressBar(obj,increase,name)
            if(obj.supercede)
                obj.suspendGUIWithMessage(name);
                name='';
            end
            if(~isempty(obj.progressBar))
                obj.progressBar.Position=[0 0 min(obj.progressBar.Position(3)+increase,1) obj.barHeight];
                if(exist('name','var'))
                    obj.progressAnnotation.String=name;
                    obj.progressAnnotation.Visible='on';
                end
                drawnow;
            end
        end
        function HideProgressBar(obj)
            if(~isempty(obj.progressBar))
                obj.progressBar.Units='normalized';
                obj.progressBar.Position(3)= 0;
                obj.progressBar.Visible='off';
                obj.progressAnnotation.Visible='off';
                obj.progressAnnotation.String='';
            end

        end

        function resumeGUI(obj)
            if(isvalid(obj.suspendBox) && ~isempty(obj.suspendBox))
                obj.suspendBox.Visible='off';
                obj.HideProgressBar();
                %%restore other progressbar dependencies
                if(~obj.supercede)
                    if(~isempty(obj.dependencyProgress))
                        DependencyHandler.Instance.SetDependency('unifiedProgressbar',obj.dependencyProgress);
                        obj.dependencyProgress=[];
                    else
                        if(DependencyHandler.Instance.IsDependency('unifiedProgressbar'))
                            DependencyHandler.Instance.RemoveDependency('unifiedProgressbar');
                        end
                    end
                end
%                enableDisableFig(obj.window,'on');
            end
        end
    end
end

