classdef EEGNamesView < uix.Grid & AView & IComponentView
    %EEGNamesView - View associated with the EEGElectrodeNames
    % see also AView, IComponentView
    
    properties (Access = public)
        History % history of changes made in the view
        EEGElectrodeNamesIdentifier
    end
    properties (Access = protected)
        EEGNamesTable
        buttonGrid
        deleteButton
        addButton
    end

    methods
        function obj = EEGNamesView(varargin)

            obj.EEGElectrodeNamesIdentifier = 'EEGNames';

            if nargin > 1 
                columnNames  = fieldnames(varargin{1,2})';
                columnFormat = repmat({'char'}, 1, length(columnNames));
                colEditable  = true(1,length(columnNames));
            else
                columnNames  = {'EEG Names','VERA Names','EEG Numbers','VERA Numbers'};
                columnFormat = {'char','char','char','char'};
                colEditable  = [true,true,true,true];
            end

            obj.EEGNamesTable = uitable('Parent', obj,...
                'ColumnName',       columnNames,...
                'ColumnFormat',     columnFormat,...
                'ColumnEditable',   colEditable,...
                'CellEditCallback', @(~,~)obj.compUpdate());

            obj.buttonGrid         = uix.Grid('Parent',obj);
            obj.deleteButton       = uicontrol('Parent',obj.buttonGrid,'Style','pushbutton','String','Delete','Callback',@obj.deleteButtonPressed);
            obj.addButton          = uicontrol('Parent',obj.buttonGrid,'Style','pushbutton','String','Add',   'Callback',@obj.addButtonPressed);
            obj.buttonGrid.Widths  = [-1,-1];
            obj.buttonGrid.Heights = [-1];
            addlistener(obj.EEGNamesTable,'Data','PostSet',@(~,~)obj.compUpdate);

            obj.Heights = [-1,20];
            obj.Widths  = [-1];

            obj.disableChanges();
            try
                if nargin > 1
                    uix.set(obj, 'Parent', varargin{1})
                end
            catch e
                delete(obj)
                e.throwAsCaller()
            end
        end

    end

    methods(Access = protected)
        function dataUpdate(obj)
            obj.componentChanged();
        end

        function enableChanges(obj)
            set(obj.EEGNamesTable,'Enable','on');
            set(obj.deleteButton,'Visible','on');
            set(obj.addButton,'Visible','on');
        end

        function disableChanges(obj)
            set(obj.EEGNamesTable,'Enable','inactive');
            set(obj.deleteButton,'Visible','off');
            set(obj.addButton,'Visible','off');
        end

        function componentChanged(obj,a,b)
            obj.enableChanges();
            
            comp = obj.GetComponent();
            tbl  = {};
            
            if ~isempty(comp)
                obj.enableChanges();
                elNames = comp.EEGNames;
            else
                obj.disableChanges();
                elNames = '';
                if(obj.AvailableData.isKey(obj.EEGElectrodeNamesIdentifier))
                    elNames = obj.AvailableData(obj.EEGElectrodeNamesIdentifier).Definition;
                end
            end

            if ~isempty(elNames)
                fn = fieldnames(elNames);
                for i = 1:length(fn)
                    for ie = 1:length(elNames)
                        tbl(ie,i) = {elNames(ie).(fn{i})};
                    end
                end
            end

            obj.EEGNamesTable.Data = tbl;
            if(isprop(comp,'History'))
                comp.History = {};
            end
        end

        function compUpdate(obj)
            comp = obj.GetComponent();

            if(~isempty(comp))
                tbl = obj.EEGNamesTable.Data;
                obj.History{end+1} = {'Update',tbl};
                if(isempty(tbl))
                    comp.EEGNames = [];
                else
                    fn = fieldnames(comp.EEGNames);
                    for i = 1:length(fn)
                        dt.(fn{i}) = {};
                    end
                    for i = 1:length(fn)
                        for j = 1:size(tbl,1)
                            dt(j).(fn{i}) = tbl{j,i};
                        end
                    end

                    comp.EEGNames = dt;
                end
            end
        end

        function addButtonPressed(obj,~,~)
            comp = obj.GetComponent();
            tbl  = obj.EEGNamesTable.Data;
            if(isempty(tbl))
                tbl      = cell(1,6);
                tbl{1,1} = false;
            else
                tbl(end+1,:) = {'',''};
            end
            obj.EEGNamesTable.Data = tbl;
            if(isprop(comp,'History'))
                comp.History{end+1} = {'Add',length(tbl)};
            end
        end

        function deleteButtonPressed(obj,~,~)
            comp = obj.GetComponent();
            tbl  = obj.EEGNamesTable.Data;
            if(~isempty(tbl))
                idx        = [tbl{:,1}];
                tbl(idx,:) = [];
            end
            obj.EEGNamesTable.Data = tbl;
            if(isprop(comp,'History'))
                comp.History{end+1} = {'Delete',find(idx)};
            end
        end

    end
end

