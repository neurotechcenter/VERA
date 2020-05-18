classdef SettingsGUI < uix.Panel
    %SETTINGSGUI Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (Access = protected)
        table
        noUpdate
    end
    
    methods
        function obj = SettingsGUI(varargin)
            %SETTINGSGUI Construct an instance of this class
            %   Detailed explanation goes here
            obj.noUpdate=false;
            if(isempty(varargin) || ~strcmp(varargin,'parent'))
                obj.Parent=figure( ...
            'NumberTitle', 'off', ...
            'MenuBar', 'none', ...
            'Toolbar', 'none', ...
            'HandleVisibility', 'off' );
            end
             obj.table=uitable (obj,'ColumnName',{'Dependency','Value',''},'ColumnEditable',[false,true,false]);
             try
              uix.set( obj, varargin{:} )
             catch e
              delete( obj )
              e.throwAsCaller()
             end
             obj.table.CellSelectionCallback=@obj.cellSelected;
             obj.table.CellEditCallback=@obj.cellEdited;
             obj.refreshTable();
        end
    end
    
    methods (Access = protected)
        
        function cellEdited(obj,tbl,event)
            if(isempty(event.Indices) || obj.noUpdate)
                return;
            end
            idx=event.Indices(1);
            depName=tbl.Data{idx,1};
            entry=tbl.Data{idx,2};
            DependencyHandler.Instance.SetDependency(depName,entry)
        end
        
        function cellSelected(obj,tbl,event)
            if(isempty(event.Indices))
                return;
            end
            obj.noUpdate=true;
            if(event.Indices(2) == 3) %make sure ... is selected
               idx=event.Indices(1);
               depName=tbl.Data{idx,1};
               entry=[];
               switch(DependencyHandler.Instance.RequestLibrary(depName))
                   case 'file'
                       entry=uigetfile('*.*',depName);
                   case 'folder'
                       entry=uigetdir([],depName);
                   case 'internal'
                       warning('variable cannot be changed');
               end
               if(~isempty(entry) && ~isequal(entry,0))
                   DependencyHandler.Instance.SetDependency(depName,entry);
               end
               obj.refreshTable();
            end
            obj.noUpdate=false;
            
        end
        
        function newDependencyRequested(obj,~,~)
            obj.refreshTable();
        end
        
        function refreshTable(obj)

            dependencyName=keys(DependencyHandler.Instance.RequestLibrary);
            rmvK=[];
            for i=1:length(dependencyName)
                if(strcmp(DependencyHandler.Instance.RequestLibrary(dependencyName{i}),'internal'))
                    rmvK(end+1)=i;
                end
            end
            dependencyName(rmvK)=[];
            d=cell(length(dependencyName),3);
            for i=1:length(dependencyName)
                d{i,1}=dependencyName{i};
                if(isKey(DependencyHandler.Instance.ResolvedLibrary,dependencyName{i}))
                    d{i,2}=DependencyHandler.Instance.ResolvedLibrary(dependencyName{i});
                end
                d{i,3}='...'; %place holder for file/folder open
            end
            obj.table.Data=d;
               
        end
        
    end
end

