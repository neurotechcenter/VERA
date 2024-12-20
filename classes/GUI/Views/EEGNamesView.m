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

            obj.EEGNamesTable = uitable('Parent', obj,...
                'ColumnName',       {'EEG Electrode Names','VERA Electrode Names'},...
                'ColumnFormat',     {'char','char'},...
                'ColumnEditable',   [true,true],...
                'CellEditCallback', @(~,~)obj.compUpdate());

            obj.buttonGrid         = uix.Grid('Parent',obj);
            obj.deleteButton       = uicontrol('Parent',obj.buttonGrid,'Style','pushbutton','String','Delete','Callback',@obj.deleteButtonPressed);
            obj.addButton          = uicontrol('Parent',obj.buttonGrid,'Style','pushbutton','String','Add',   'Callback',@obj.addButtonPressed);
            obj.buttonGrid.Widths  = [-1,-1];
            obj.buttonGrid.Heights = [-1];
            addlistener(obj.EEGNamesTable,'Data','PostSet',@(~,~)obj.compUpdate);

            obj.EEGElectrodeNamesIdentifier = 'EEGNames';
            obj.Heights = [-1,20];
            obj.Widths  = [-1];

            obj.disableChanges();
            try
                uix.set(obj, varargin{:})
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
            
            if(~isempty(comp))
                obj.enableChanges();
                elNames = comp.EEGNames;
            else
                obj.disableChanges();
                elNames = [];
                if(obj.AvailableData.isKey(obj.EEGElectrodeNamesIdentifier))
                    elNames = obj.AvailableData(obj.EEGElectrodeNamesIdentifier).Definition;
                end
            end

            for ie = 1:length(elNames)
                tbl(end+1,:) = {elNames(ie).EEGNames,elNames(ie).VERANames};
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
                    for i = 1:size(tbl,1)
                        dt(i) = struct('EEGNames',tbl{i,1},'VERANames',tbl{i,2});
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

