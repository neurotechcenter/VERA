classdef ElectrodeLocationTableView < AView & uix.Grid & IComponentView
    %ElectrodeLocationTableView Table to show electrode locations including
    %names and labels. Channel, Channel Name, and X/Y/Z are always
    %read-only. The Label column is only editable when this view is bound
    %to a running Component via SetComponent (e.g. the standalone window
    %opened by ManuallySetLabels) - when embedded in the main VERA GUI and
    %fed purely through AvailableData, the whole table is read-only.
    % Works both embedded in the main VERA GUI (fed via AvailableData) and
    % as a standalone window opened directly by a Component, e.g.
    % ElectrodeLocationTableView(h,obj.Labels); elView.SetComponent(obj);
    % - matching the pattern used by ElectrodeDefinitionView/EEGNamesView.
    % See also AView, ElectrodeDefinitionView, EEGNamesView, ManuallySetLabels

    properties
        ElectrodeLocationIdentifier %Identifier for the Electrode Location to be shown
        ElectrodeDefinitionIdentifier %Identifier for the (optional) Electrode Definition, used to display Channel Names
    end
    properties (Access = protected)
        gridDefinitionTable
        electrodeLocation %Handle to the ElectrodeLocation object currently bound to this view
    end

    methods
        function obj = ElectrodeLocationTableView(varargin)
            obj.ElectrodeLocationIdentifier   = 'ElectrodeLocation';
            obj.ElectrodeDefinitionIdentifier = 'ElectrodeDefinition';

            obj.gridDefinitionTable = uitable('Parent', obj,...
                'ColumnName',       {'Channel','Channel Name','X','Y','Z','Label'},...
                'ColumnFormat',     {'numeric','char','numeric','numeric','numeric','char'},...
                'ColumnEditable',   [false,false,false,false,false,true],...
                'CellEditCallback', @(~,~)obj.compUpdate());

            obj.Heights = -1;
            obj.Widths  = -1;

            obj.disableChanges();

             try
                if nargin > 1
                    uix.set(obj, 'Parent', varargin{1})
                end
             catch e
                delete( obj )
                e.throwAsCaller()
            end
        end

    end

   methods(Access = protected)
        function dataUpdate(obj)
            obj.componentChanged();
        end

        function componentChanged(obj,a,b)
            elLocs = [];
            eDef   = [];
            comp   = obj.GetComponent();

            if(~isempty(comp))
                % Bound to a running Component (e.g. ManuallySetLabels'
                % standalone window via SetComponent) - editing is allowed.
                obj.enableChanges();
                if(isprop(comp,'Labels') && isObjectTypeOf(comp.Labels,'ElectrodeLocation'))
                    elLocs = comp.Labels;
                elseif(isObjectTypeOf(comp,'ElectrodeLocation'))
                    elLocs = comp;
                end
                if(isprop(comp,'ElectrodeDefinition') && isObjectTypeOf(comp.ElectrodeDefinition,'ElectrodeDefinition'))
                    eDef = comp.ElectrodeDefinition;
                end
            else
                % Not bound to a Component - just passively browsing
                % pipeline data (e.g. embedded in the main VERA GUI) -
                % read-only.
                obj.disableChanges();
                if(isKey(obj.AvailableData,obj.ElectrodeLocationIdentifier))
                    candidate = obj.AvailableData(obj.ElectrodeLocationIdentifier);
                    if(isObjectTypeOf(candidate,'ElectrodeLocation'))
                        elLocs = candidate;
                    end
                end
                if(isKey(obj.AvailableData,obj.ElectrodeDefinitionIdentifier))
                    candidateDef = obj.AvailableData(obj.ElectrodeDefinitionIdentifier);
                    if(isObjectTypeOf(candidateDef,'ElectrodeDefinition'))
                        eDef = candidateDef;
                    end
                end
            end

            obj.electrodeLocation = elLocs;

            %create table for view
            tbl = {};
            if(~isempty(elLocs))
                for i=1:size(elLocs.Location,1)
                   tbl(i,:) = {i,obj.formatChannelName(elLocs,eDef,i),elLocs.Location(i,1),elLocs.Location(i,2),elLocs.Location(i,3),obj.formatLabel(elLocs.Label,i)};
                end
            end
            obj.gridDefinitionTable.Data=tbl;
        end

        function enableChanges(obj)
            set(obj.gridDefinitionTable,'Enable','on');
        end

        function disableChanges(obj)
            set(obj.gridDefinitionTable,'Enable','inactive');
        end

        function compUpdate(obj)
            if(isempty(obj.electrodeLocation) || isempty(obj.GetComponent()))
                return;
            end
            tbl         = obj.gridDefinitionTable.Data;
            labelColumn = size(tbl,2); % Label is always the last, editable column
            newLabels   = cell(size(tbl,1),1);
            for i = 1:size(tbl,1)
                newLabels{i} = obj.parseLabel(tbl{i,labelColumn});
            end
            obj.electrodeLocation.Label = newLabels;
        end
   end

   methods (Static, Access = protected)
        function name = formatChannelName(elLocs,eDef,idx)
            %formatChannelName - Definition name + within-definition
            %channel index (e.g. "LA1"). Returns '' if no
            %ElectrodeDefinition is available.
            name = '';
            if isempty(eDef)
                return;
            end
            try
                defId       = elLocs.DefinitionIdentifier(idx);
                defName     = eDef.Definition(defId).Name;
                sameDefIdxs = find(elLocs.DefinitionIdentifier == defId);
                chidx       = find(sameDefIdxs == idx);
                name        = [defName num2str(chidx)];
            catch
                name = '';
            end
        end

        function txt = formatLabel(labels,idx)
            %formatLabel - join a point's labels into a single display string
            txt = '';
            if idx > length(labels) || isempty(labels{idx})
                return;
            end
            entry = labels{idx};
            if ischar(entry)
                txt = entry;
            elseif iscell(entry)
                txt = strjoin(entry,', ');
            end
        end

        function labelCell = parseLabel(txt)
            %parseLabel - split a comma separated display string back
            %into the cell-of-strings structure expected by
            %PointSet.Label
            if isempty(txt)
                labelCell = {};
                return;
            end
            parts = strtrim(strsplit(txt,','));
            labelCell = parts(~cellfun(@isempty,parts));
        end
   end

end
