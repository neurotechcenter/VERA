classdef Table < uiw.abstract.JavaControl
    % Table - A rich table control
    %
    % Create a widget containing a rich table using JTable
    %
    % Syntax:
    %     w = uiw.widget.Table('Property','Value',...)
    %
    % Notes and Known Issues:
    %
    %   1. Setting most per-column properties like ColumnName, ColumnWidth,
    %   or Data will increase the number of columns as needed. To decrease
    %   columns in the table, set the ColumnName property.
    %
    %   2. The Data property is cached in a MATLAB variable. It updates the
    %   data in the JControl when the Data property is set or setCell is
    %   called. Edits to the table by the user should, in most cases, be
    %   passed back into the cached Data via a internal call to
    %   onTableModelChanged.
    %
    %   3. Features that are not implemented:
    %       - Row headers/names
    %       - Filtering
    %
    
    %   Copyright 2013-2019 The MathWorks, Inc.
    %
    % Auth/Revision:
    %   MathWorks Consulting
    %   $Author: rjackey $
    %   $Revision: 324 $
    %   $Date: 2019-04-23 08:05:17 -0400 (Tue, 23 Apr 2019) $
    % ---------------------------------------------------------------------
    
    
    %% Properties
    properties (AbortSet)
        CellEditCallback = '' %callback for edits to the cell
        CellSelectionCallback = '' %callback for change in selection
        ColumnEditable logical = false(0,1) %boolean array the same size as number of columns, indicating whether each column is editable or not
        ColumnFormatData cell = cell(0,1) %cell array the same size as ColumnFormat, and containing a cellstr list of choices for any column that has a popup list.
        Editable logical = true %controls whether the table text is editable
        MouseClickedCallback = '' %callback when the mouse is clicked on the table
        MouseDraggedCallback = '' %callback while the mouse is being dragged over the table
        MouseMotionFcn = '' %callback while the mouse is being moved over the table
        RowHeight = -1 %height of the rows in the table
        SelectionMode char = 'single' %can we select multiple: (['single'],'contiguous','discontiguous')
        SelectionType char = 'row' %type of selection area allowed: (['row'],'column','cell','none')
        SortCallback = '' %callback when sorted order of data has changed. May be triggered by clicking on column headers, or upon automatic resorting after changing the value in Data or DataTable.
    end
    
    properties (Dependent)
        Data %data in the table. Must be entered as a cell array. (Also see property DataTable for an alternative.)
        DataTable %data array as a MATLAB table. Setting a table to DataTable will update Data and ColumnName properties
    end
    
    properties (AbortSet, Dependent)
        ColumnFormat %cellstr array defining the data format for each column. For a list of formats, see uiw.enum.TableColumnFormat
        ColumnName %name of each column
        ColumnResizable %whether each column is resizable (true/false)
        ColumnResizePolicy %automatic resize policy for columns. ('off','next',['subsequent'],'last','all')
        ColumnWidth %width of each column (setting this changes ColumnResizePolicy to 'off')
        ColumnMaxWidth %maximum width of each column for auto sizing
        ColumnMinWidth %minimum width of each column for auto sizing
        ColumnPreferredWidth %preferred width of each column for auto sizing
        ColumnSortable %flag for whether each column may be sorted, when the table Sortable is true
        SelectedRows %table rows that are currently selected
        SelectedColumns %table columns that are currently selected
        Sortable %controls whether the columns are sortable. You may sort by clicking on column headers, and sort by multiple criteria by CTRL-click on additional column headers.
    end
    
    properties (SetAccess=private)
        ColumnFormatEnum uiw.enum.TableColumnFormat %Enumeration members for each column format, from uiw.enum.TableColumnFormat
    end
    
    properties (Dependent, SetAccess=private)
        ColumnIsSorted %indicator which column(s) have sorting controls set (read-only)
        ColumnSortDirection %indicates the sort direction of columns (read-only, 0:unsorted, -1:descending, 1:ascending)
        SelectedData %the currently selected data in the table (read-only)
    end
    
    
    %% Internal properties
    properties (Access=protected)
        JTableModel %Java table model
        JSelectionModel %Java table selection model
        JSortableTableModel %Java table model for sorting
        DataM %Cache of MATLAB data
        SelectedRows_ %Cache of row selection
        SelectedColumns_ %Cache of column selection
    end
    
    properties (Dependent, GetAccess=protected, SetAccess=private)
        CellEditor %Java cell editor
        CellRenderer %Java cell renderer
    end
    
    properties (Dependent, SetAccess=private)
        RowSortIndex %Indices of row sort, when sorting is used
    end
    
    properties (Constant, GetAccess=protected)
        DEFAULTCOLUMNWIDTH = 100 %Default width of columns
        ValidResizeModes = { %Valid modes for ColumnResizePolicy
            'off'
            'next'
            'subsequent'
            'last'
            'all'
            };
        ValidSelectionModes = { %Valid modes for SelectionMode
            'single'
            'contiguous'
            'discontiguous'
            };
        ValidSelectionTypes = { %Valid modes for SelectionType
            'row'
            'column'
            'cell'
            'none'
            };
    end
    
    
    
    %% Constructor / Destructor
    methods
        
        function obj = Table(varargin)
            % Construct the control
            
            % Create the base graphics
            obj.create();
            
            % Default sorting off
            obj.JControl.setSortingEnabled(false);
            
            % ColumnName must be handled first, if specified
            [splitArgs,remArgs] = obj.splitArgs({'ColumnName'},varargin{:});
            
            % Selection handled at the end
            [selRowsArgs,remArgs] = obj.splitArgs({'SelectedRows'},remArgs{:});
            [selColsArgs,remArgs] = obj.splitArgs({'SelectedColumns'},remArgs{:});
            
            % Set properties from P-V pairs
            obj.assignPVPairs(splitArgs{:},remArgs{:});
            
            % Assign the construction flag
            obj.IsConstructed = true;
            
            % Apply the selection changes
            obj.applySelectionModel();
            obj.assignPVPairs(selRowsArgs{:},selColsArgs{:});
            obj.applyColumnFormats();
            %obj.redrawJava_private();
            
            % Do the following only if the object is not a subclass
            if strcmp(class(obj), 'uiw.widget.Table') %#ok<STISA>
                
                % Redraw the widget
                obj.onResized();
                obj.onEnableChanged();
                obj.redraw();
                obj.onStyleChanged();
                
            end %if strcmp(class(obj),...
            
        end % constructor
        
        
        function delete(obj)
            
            % Explicitly delete handles to Java objects
            delete(obj.JControl);
            delete(obj.JTableModel);
            delete(obj.JSelectionModel);
            
        end % destructor
        
    end %methods - constructor/destructor
    
    
    
    %% Public Methods
    methods
        
        function [str,data] = onCopy(obj)
            % Get the currently selected data, useful for implementing Copy
            % in an application.
            
            % Get the current selection
            data = obj.SelectedData;
            
            % Convert to comma separated string
            strCell = data;
            isChar = cellfun(@(x)ischar(x),data);
            strCell(isChar) = strcat('"',strCell(isChar),'"');
            strCell(~isChar) = cellfun(@(x)mat2str(x),strCell(~isChar),...
                'UniformOutput',false);
            str = strjoin(strCell, ', ');
            
        end
        
    end %methods
    
    
    
    %% Protected Methods
    methods (Access=protected)
        
        function create(obj)
            % Create the graphics objects
            
            % Create the table model
            obj.JTableModel = obj.constructJObj('com.mathworks.consulting.widgets.table.TableModel');
            obj.JTableModel.TableChangedCallback = @(h,e)onTableModelChanged(obj,h,e);
            
            % Create the table on a scroll pane
            obj.createScrollPaneJControl('com.mathworks.consulting.widgets.table.Table',obj.JTableModel);
            obj.JControl.setSelectionMode(javax.swing.ListSelectionModel.SINGLE_SELECTION)
            obj.JControl.getTableHeader().setReorderingAllowed(false)
            obj.JControl.setAutoCreateColumnsFromModel(false)
            obj.JControl.setFillsViewportHeight(true)
            
            % Get selection model
            obj.JSelectionModel = obj.constructJObj(obj.JControl.getSelectionModel());
            obj.JSelectionModel.ValueChangedCallback = @(h,e)onSelectionChanged(obj,h,e);
            %obj.JSelectionModel.setSelectionMode(0); %default to single selection
            
            % Get the sortable model
            obj.JSortableTableModel = obj.JControl.getModel();
            %obj.JSortableTableModel.SortChangedCallback = @(h,e)onSortChanged(obj,h,e);
            set(obj.JSortableTableModel, 'SortChangedCallback',@(h,e)onSortChanged(obj,h,e))
            obj.JSortableTableModel.setResetOnTableStructureChangeEvent(false);
            
            % Set the java callbacks for mouse events
            set([obj.JScrollPane obj.JControl],...
                'MouseClickedCallback',@(h,e)onMouseEvent(obj,h,e),...
                'MousePressedCallback',@(h,e)onMouseEvent(obj,h,e),...
                'MouseReleasedCallback',@(h,e)onMouseEvent(obj,h,e),...
                'MouseDraggedCallback',@(h,e)onMouseEvent(obj,h,e),...
                'MouseMovedCallback',@(h,e)onMouseEvent(obj,h,e));
            
            % Set some defaults
            obj.FontSize = 10;
            
        end %function
        
        
        function onStyleChanged(obj,~)
            % Handle updates to style changes
            
            % Ensure the construction is complete
            if obj.IsConstructed
                
                % Call superclass methods
                onStyleChanged@uiw.abstract.JavaControl(obj);
                
                % Is row height fixed?
                jFontPixels = obj.JControl.getFont().getSize();
                if obj.RowHeight >= 0
                    rowHeight = obj.RowHeight;
                else
                    % Base on font size
                    rowHeight = jFontPixels + 6;
                end
                headerHeight = jFontPixels + 8;
                
                % Give the java thread a brief instant to catch up before
                % setting header width. Otherwise, ColumnWidth may be
                % incorrect.
                pause(0.01)
                
                % Set row height
                obj.JControl.setRowHeight(rowHeight);
                
                % Adjust font of headers too
                jHeader = obj.JControl.getTableHeader();
                jHeader.setFont(obj.getJFont());
                headerMinSize = jHeader.getMinimumSize();
                headerMinSize.height = headerHeight;
                jHeader.setMinimumSize(headerMinSize)
                headerMaxSize = jHeader.getMaximumSize();
                headerMaxSize.height = headerHeight;
                jHeader.setMaximumSize(headerMaxSize)
                headerSize = jHeader.getPreferredSize();
                headerSize.height = headerHeight;
                headerSize.width = sum(obj.ColumnWidth);
                jHeader.setPreferredSize(headerSize)
                
                % Set the background
                jColor = obj.rgbToJavaColor(obj.BackgroundColor);
                obj.JControl.setBackground(jColor);
                
            end %if obj.IsConstructed
            
        end %function
        
        
        function onMouseEvent(obj,h,jEvent)
            % Triggered on mouse events from Java
            
            if obj.isvalid()
                
                % Get mouse event data
                mouseEvent = obj.getMouseEventData(jEvent);
                
                % Add table-specific mouse event data
                addprop(mouseEvent,'Location');
                addprop(mouseEvent,'Cell');
                jPoint = jEvent.getPoint();
                mouseEvent.Cell = [obj.JControl.rowAtPoint(jPoint),...
                    obj.JControl.columnAtPoint(jPoint)] + 1;
                if h==obj.JControl
                    mouseEvent.Location = 'table';
                else
                    mouseEvent.Location = 'scrollpanel';
                end
                
                % Trigger the appropriate callback and notify
                switch mouseEvent.Interaction
                    case 'ButtonClicked'
                        
                        hgfeval(obj.MouseClickedCallback,obj,mouseEvent)
                        
                        % Launch context menu in certain cases
                        if strcmp(mouseEvent.SelectionType,'alt') && mouseEvent.ControlOn~=1
                            
                            % Default to the standard context menu
                            cMenu = obj.UIContextMenu;
                            
                            % Launch the context menu
                            obj.showContextMenu(cMenu)
                            
                        end %if strcmp(evt.SelectionType,'alt')
                        
                    case 'ButtonDown'
                        obj.notify('ButtonDown',mouseEvent);
                        
                    case 'ButtonUp'
                        % Do nothing - no callback defined
                        
                    case 'ButtonMotion'
                        obj.notify('MouseMotion',mouseEvent);
                        
                    case 'ButtonDrag'
                        obj.notify('MouseDrag',mouseEvent);
                        
                end %switch evt.Interaction
                
            end %if obj.isvalid()
            
        end %function
        
        
        function onSelectionChanged(obj, ~, e)
            % Triggered on cell selection changed by interaction
            
            if obj.isvalid() && obj.CallbacksEnabled && ~e.getValueIsAdjusting()
                
                % Cache the selected rows/columns
                switch obj.SelectionType
                    
                    case 'column'
                        selRows = ':';
                        selCols = double(obj.JControl.getSelectedColumns() + 1)';
                        isNew = ~isequal(obj.SelectedColumns_, selCols);
                        
                    case 'row'
                        selRows = double(obj.JControl.getSelectedRows() + 1)';
                        selCols = ':';
                        isNew = ~isequal(obj.SelectedRows_, selRows);
                        
                    case 'cell'
                        selRows = double(obj.JControl.getSelectedRows() + 1)';
                        selCols = double(obj.JControl.getSelectedColumns() + 1)';
                        isNew = ~isequal(obj.SelectedRows_, selRows) ||...
                            ~isequal(obj.SelectedColumns_, selCols);
                        
                    otherwise %none
                        selRows = [];
                        selCols = [];
                        isNew = ~isequal(obj.SelectedRows_, selRows) ||...
                            ~isequal(obj.SelectedColumns_, selCols);
                        
                end %switch obj.SelectionType
                
                % Did anything really change?
                if isNew
                    
                    % Set the new values
                    obj.SelectedRows_ = selRows;
                    obj.SelectedColumns_ = selCols;
                    
                    % Redraw the component
                    obj.redraw();
                    
                    % Call the callback
                    evt = struct(...
                        'Source',obj,...
                        'SelectedRows',obj.SelectedRows,...
                        'SelectedColumns',obj.SelectedColumns);
                    evt.SelectedData = obj.SelectedData; %may be array, so assign after
                    hgfeval(obj.CellSelectionCallback, obj, evt);
                    
                end %if isNew
                
            end %if obj.isvalid()&& ~eventData.getValueIsAdjusting()
        end % onSelectionChanged
        
        
        function onSortChanged(obj, ~, ~)
            % Triggered by sort controls interaction
            
            if obj.isvalid()
                
                % Call the callback
                evt = struct(...
                    'Source',obj,...
                    'NewSortOrder',mat2str(obj.RowSortIndex'));
                hgfeval(obj.SortCallback, obj, evt);
                
            end %if obj.isvalid()
            
        end % onSortChanged
        
        
        function onTableModelChanged(obj, ~, e)
            % Triggered by any changes to table model, such as user edits
            
            if ~obj.isvalid() || ~obj.CallbacksEnabled
                return
            end
            
            % What rows/columns were changed?
            cIdx = e.getColumn() + 1;
            rIdx = (e.getFirstRow():e.getLastRow()) + 1;
            
            % What happened? Proceed only if a single cell was edited. If
            % the columns/rows were not >0, it was likely a programmatic
            % set of the data that we ignore.
            if isscalar(rIdx) && rIdx>0
                
                % Get the new value
                jValue = obj.JTableModel.getValueAt(rIdx-1,cIdx-1);
                
                % Convert Java types back to MATLAB as needed
                mValue = obj.ColumnFormatEnum(cIdx).toMLType(jValue);
                
                % Prepare event data
                evt.Source = obj;
                evt.Indices = [rIdx cIdx];
                evt.NewValue = mValue;
                
                % Get the old value first, then update cached DataM
                if isnumeric(obj.DataM)
                    evt.OldValue = obj.DataM(rIdx,cIdx);
                    if ischar(mValue) || ( isscalar(mValue) && isstring(mValue) )
                        mValue = str2double(mValue);
                    end
                    % Return if the value is unchanged
                    if obj.DataM(rIdx,cIdx) - mValue == 0
                        return
                    end
                    obj.DataM(rIdx,cIdx) = mValue;
                else
                    evt.OldValue = obj.DataM{rIdx,cIdx};
                    obj.DataM{rIdx,cIdx} = mValue;
                end
                
                % Call the callback
                if ~isequaln(evt.OldValue, evt.NewValue)
                    hgfeval(obj.CellEditCallback,obj,evt);
                end
                
            end %if isscalar(rIdx) && rIdx>0
            
        end % onTableModelChanged
        
    end %methods
    
    
    
    %% Public methods
    methods
        
        function setCellColor(obj,rIdx,cIdx,color)
            % setCellColor - Sets the background color for a cell
            % -------------------------------------------------------------------------
            % Abstract: Set the background color for a cell
            %
            % Syntax:
            %           obj.setCellColor(rIdx,cIdx,color)
            %           setCellColor(obj,rIdx,cIdx,color))
            %
            % Inputs:
            %           obj - Table object
            %           rIdx - row index to get (scalar)
            %           cIdx - column index to get (scalar)
            %           color - color (char or [r,g,b])
            %
            % Outputs:
            %           value - value from the cell
            %
            
            % Validate
            narginchk(4,4);
            obj.validateIndex(rIdx,cIdx);
            
            % Set the color
            color = uiw.utility.interpretColor(color);
            jColor = obj.rgbToJavaColor(color);
            obj.JControl.setCellColor(rIdx,cIdx,jColor)
            
            % Redraw in case changes have been made
            obj.redrawJava_private();
            
        end %setCellColor
        
        
        function value = getCell(obj,rIdx,cIdx)
            % getCell - Get a cell to the specified value
            % -------------------------------------------------------------------------
            % Abstract: Get a cell to the specified value
            %
            % Syntax:
            %           value = obj.getCell(row,col)
            %           value = getCell(obj,row,col)
            %
            % Inputs:
            %           obj - Table object
            %           rIdx - row index to get (scalar)
            %           cIdx - column index to get (scalar)
            %
            % Outputs:
            %           value - value from the cell
            %
            
            % Validate
            narginchk(3,3);
            obj.validateIndex(rIdx,cIdx);
            
            % Is the table sorted? If so, use the sorted row index.
            if ~isempty(obj.RowSortIndex)
                rIdx = obj.RowSortIndex(rIdx);
            end
            
            % Get the value
            if isnumeric(obj.DataM)
                value = obj.DataM(rIdx,cIdx);
            else
                value = obj.DataM{rIdx,cIdx};
            end
            
        end
        
        
        function setCell(obj,rIdx,cIdx,value)
            % setCell - Set a cell to the specified value
            % -------------------------------------------------------------------------
            % Abstract: Set a cell to the specified value
            %
            % Syntax:
            %           obj.setCell(row,col,value)
            %           setCell(obj,row,col,value)
            %
            % Inputs:
            %           obj - Table object
            %           rIdx - row index to get (scalar)
            %           cIdx - column index to get (scalar)
            %           value - value to set
            %
            % Outputs:
            %           none
            %
            
            % Validate
            narginchk(4,4);
            obj.validateIndex(rIdx,cIdx);
            validateattributes(value,{'cell','char','string','numeric','logical','datetime'},{});
            
            % Put the value in a cell if not already
            if ~iscell(value)
                value = {value};
            end
            
            % Convert data to Java types as needed
            jValue = obj.ColumnFormatEnum(cIdx).toJavaType(value);
            
            % Is the table sorted? If so, use the sorted row index.
            if ~isempty(obj.RowSortIndex)
                rIdx = obj.RowSortIndex(rIdx);
            end
            
            % Disable callbacks while updating Java
            obj.CallbacksEnabled = false;
            
            % Set the value
            obj.JTableModel.setValueAt(jValue{:},rIdx-1,cIdx-1);
            
            % Re-enable callbacks
            obj.CallbacksEnabled = true;
            
            % Set the cached value
            if isnumeric(obj.DataM)
                if isnumeric(value{:})
                    obj.DataM(rIdx,cIdx) = value{:};
                else
                    % A non-number was entered, so switch DataM to cell format
                    obj.DataM = num2cell(obj.DataM);
                    obj.DataM(rIdx,cIdx) = value;
                end
            else %DataM cache is cell
                obj.DataM(rIdx,cIdx) = value;
            end %if isnumeric(obj.DataM)
            
        end
        
        
        function sizeColumnsToData(obj)
            % sizeColumnsToData - Set column sizes automatically
            % -------------------------------------------------------------------------
            % Abstract: Set column sizes automatically to fit the contents
            %
            % Syntax:
            %           obj.sizeColumnsToData()
            %           sizeColumnsToData(obj)
            %
            % Inputs:
            %           obj - Table object
            %
            % Outputs:
            %           none
            %
            
            com.mathworks.mwswing.MJUtilities.initJIDE;
            com.jidesoft.grid.TableUtils.autoResizeAllColumns(obj.JControl);
            
        end %function
        
        
        function stopEditing(obj)
            % stopEditing - Stop editing the current cell
            % -------------------------------------------------------------------------
            % Abstract: Programmatically stops editing of the current cell
            %
            % Syntax:
            %           obj.stopEditing()
            %           stopEditing(obj)
            %
            % Inputs:
            %           obj - Table object
            %
            % Outputs:
            %           none
            %
            
            jEditor = obj.JControl.getCellEditor();
            if ~isempty(jEditor)
                jEditor.stopCellEditing();
                pause(0.01); % Allow Java to catch up
            end
            
        end %function
        
        
        function sortColumn(obj,col,descending,append)
            % sortColumn - Sort a column
            % -------------------------------------------------------------------------
            % Abstract: Programmatically sorts a column
            %
            % Syntax:
            %           obj.sortColumn(col)
            %           obj.sortColumn(col,descending)
            %           obj.sortColumn(col,descending,append)
            %
            % Inputs:
            %           obj - Table object
            %           col - column number
            %           descending - sort in reverse? [true/(false)]
            %           append - append to existing sort? [true/(false)]
            %
            % Outputs:
            %           none
            %
            
            % Parse and validate inputs
            if nargin<4
                append = false;
                if nargin<3
                    descending = false;
                end
            end
            validateattributes(col,{'numeric'},{'positive','integer','<=',size(obj.DataM,2)});
            validateattributes(append,{'logical'},{'scalar'});
            validateattributes(descending,{'logical'},{'scalar'});
            
            % Zero-based column index
            jCol = col-1;
            
            % Perform the sort
            obj.JSortableTableModel.sortColumn(jCol,~append);
            if descending
                obj.JSortableTableModel.reverseColumnSortOrder(jCol);
            end
            
        end %function
        
    end %methods
    
    
    
    %% Private Methods - INTERNAL USE
    methods (Access=private)
        
        function redrawJava_private(obj)
            % Handle state changes that may need Java redraw
            
            % Ensure the construction is complete
            if obj.IsConstructed
                
                obj.JScrollPane.repaint(obj.JScrollPane.getBounds())
                obj.JScrollPane.setViewportView(obj.JControl)
                
                % Set the column editability
                jEditableArray = obj.JTableModel.isEditable();
                for idx = 1:jEditableArray.size()
                    thisValue = obj.Editable && ~isempty(obj.CellEditor{idx});
                    if idx <= numel(obj.ColumnEditable)
                        thisValue = obj.ColumnEditable(idx) && thisValue;
                    end
                    jEditableArray.set(idx-1, thisValue);
                end
                obj.JTableModel.setEditable(jEditableArray);
                
                % Repaint to show everything correctly
                obj.JControl.repaint();
                
            end %if obj.IsConstructed
            
        end %function redrawJava_private
        
        
        function updateNumberOfColumns(obj,NumCol,FlagRemove)
            % Handle state changes that may need change to Java columns
            
            % Assume we should remove extras if needed
            if nargin<3
                FlagRemove = true;
            end
            
            if obj.JavaObj.setColumnCount(NumCol,FlagRemove)
                obj.ColumnFormatEnum(end+1:NumCol) = uiw.enum.TableColumnFormat.DEFAULT;
                obj.redrawJava_private();
                obj.onStyleChanged(); %To get column header widths set properly for scrolling right
            end
            
        end %function
        
        
        function outArg = evalOnColumns(obj,fcnName,inArg)
            % Evaluate a function handle on each Java column
            
            % Default output
            outArg = cell(1,0);
            
            % Add more columns if needed (don't reduce)
            if nargin>2
                numInArg = numel(inArg);
                updateNumberOfColumns(obj,numInArg,false);
            end
            
            % Get the column model
            jColumnModel = obj.JControl.getColumnModel();
            jNumCol = jColumnModel.getColumnCount();
            
            % Apply the function to each jColumn
            for idx=jNumCol:-1:1
                jColumn = jColumnModel.getColumn(idx-1);
                if nargout
                    outArg{idx} = jColumn.(fcnName);
                elseif nargin>2 && idx<=numInArg
                    jColumn.(fcnName)(inArg{idx})
                end
            end
            
            % Redraw in case changes have been made
            if nargin>=3
                obj.redrawJava_private();
            end
            
        end %function
        
        
        function applyColumnFormats(obj)
            % Handle column format changes that need to be passed to Java
            
            % Ensure the construction is complete
            if obj.IsConstructed
                
                % Add more columns if needed (don't reduce)
                NumCol = numel(obj.ColumnFormatEnum);
                updateNumberOfColumns(obj,NumCol,false)
                
                % Update the cell renderers and editors
                [renderers, editors] = ...
                    obj.ColumnFormatEnum.getColumnRenderersEditors(obj.ColumnFormatData);
                obj.CellRenderer = renderers;
                obj.CellEditor = editors;
                
                % Redraw in case changes have been made
                obj.redrawJava_private();
                
            end %if obj.IsConstructed
            
        end %function
        
        
        function applySelectionModel(obj)
            % Handle selection model updates that need to be passed to Java
            
            % Ensure the construction is complete
            if obj.IsConstructed
                
                % Selection mode:
                %   0 - SINGLE_SELECTION (single)
                %   1 - SINGLE_INTERVAL_SELECTION (contiguous)
                %   2 - MULTIPLE_INTERVAL_SELECTION (discontiguous)
                modeIdx = find(strcmp(obj.SelectionMode,obj.ValidSelectionModes),1) - 1;
                
                % Get the  selection models
                jColumnModel = obj.JControl.getColumnModel();
                jColumnSelectionModel = jColumnModel.getSelectionModel();
                
                % Clear existing selection
                obj.JSelectionModel.clearSelection()
                jColumnSelectionModel.clearSelection();
                obj.SelectedRows_ = [];
                obj.SelectedColumns_ = [];
                
                % Selection Type
                switch obj.SelectionType
                    
                    case 'row'
                        obj.JControl.setCellSelectionEnabled(false);
                        obj.JControl.setRowSelectionAllowed(true)
                        obj.JControl.setColumnSelectionAllowed(false);
                        
                    case 'column'
                        obj.JControl.setCellSelectionEnabled(false);
                        obj.JControl.setRowSelectionAllowed(false)
                        obj.JControl.setColumnSelectionAllowed(true);
                        
                        % Apply the listeners - this fixes an issue where
                        % clicking the same row in another column would not
                        % trigger the callback.
                        % https://coderanch.com/t/513754/java/JTable-selection-listener-doesn-listen
                        jSelListeners = obj.JSelectionModel.getListSelectionListeners;
                        for idx = 1:numel(jSelListeners)
                            jColumnSelectionModel.addListSelectionListener(jSelListeners(idx));
                        end
                        
                    case 'cell'
                        obj.JControl.setRowSelectionAllowed(false)
                        obj.JControl.setColumnSelectionAllowed(false);
                        obj.JControl.setCellSelectionEnabled(true);
                        
                    otherwise %none
                        obj.JControl.setCellSelectionEnabled(false);
                        obj.JControl.setRowSelectionAllowed(false)
                        obj.JControl.setColumnSelectionAllowed(false);
                        
                end %switch obj.SelectionType
                
                % Set the selection mode
                obj.JSelectionModel.setSelectionMode(modeIdx);
                jColumnSelectionModel.setSelectionMode(modeIdx);
                
                
            end %if obj.IsConstructed
            
        end %function
        
        
        function scrollToSelection(obj)
            % Scroll to the currently selected cells
            
            % Scroll to the selection
            if isvalid(obj)
                
                rowIdx = obj.SelectedRows;
                colIdx = obj.SelectedColumns;
                
                rowIsSelected = ~isempty(rowIdx) && isnumeric(rowIdx);
                columnIsSelected = ~isempty(colIdx) && isnumeric(colIdx);
                
                if rowIsSelected && columnIsSelected
                    
                    % Scroll both ways to the selection
                    rect1 = obj.JControl.getCellRect(rowIdx(1)-1,colIdx(1)-1,true);
                    rect2 = obj.JControl.getCellRect(rowIdx(end)-1,colIdx(end)-1,true);
                    rectFull = createUnion(rect1,rect2);
                    obj.JControl.scrollRectToVisible(rectFull);
                    
                elseif rowIsSelected
                    
                    % Scroll only vertically to the selection
                    obj.JControl.scrollRowToVisible(rowIdx(1)-1);
                    
                elseif columnIsSelected
                    
                    % Scroll only horizontally to the selection
                    yScroll = obj.JScrollPane.getVerticalScrollBar().getValue();
                    rectOrig = obj.JControl.getBounds();
                    rect1 = obj.JControl.getCellRect(0,colIdx(1)-1,true);
                    rect2 = obj.JControl.getCellRect(0,colIdx(end)-1,true);
                    rect12 = createUnion(rect1,rect2);
                    rectFull = rect12;
                    rectFull.y = yScroll;
                    rectFull.height = rectOrig.height;
                    obj.JControl.scrollRectToVisible(rectFull);
                    
                end %if ~isempty(rowIdx) && ~isempty(colIdx)
            end %if isvalid(obj)
            
        end %function
        
        
        function validateIndex(obj,rIdx,cIdx)
            % Validate a row and column index is within the data size
            
            [nRows,nCols] = size(obj.DataM);
            validateattributes(rIdx,{'numeric'},...
                {'scalar','integer','positive','<=',nRows})
            validateattributes(cIdx,{'numeric'},...
                {'scalar','integer','positive','<=',nCols})
            
        end %function
        
    end %methods
    
    
    
    %% Get/Set methods
    methods
        
        % ColumnEditable
        function set.ColumnEditable(obj, value)
            validateattributes(value,{'logical'},{'vector'});
            obj.ColumnEditable = value;
            % Redraw to apply changes
            obj.redrawJava_private();
        end % set.ColumnEditable
        
        % CellEditor (protected)
        function value = get.CellEditor(obj)
            value = obj.evalOnColumns('getCellEditor');
        end
        function set.CellEditor(obj, value)
            obj.evalOnColumns('setCellEditor',value);
        end
        
        % CellRenderer (protected)
        function value = get.CellRenderer(obj)
            value = obj.evalOnColumns('getCellRenderer');
        end
        function set.CellRenderer(obj, value)
            obj.evalOnColumns('setCellRenderer',value);
        end
        
        % ColumnFormat
        function value = get.ColumnFormat(obj)
            value = {obj.ColumnFormatEnum.Name};
        end
        function set.ColumnFormat(obj, value)
            %uiw.widget.TableRenderers.validateColumnFormat(value);
            format = uiw.enum.TableColumnFormat.fromName(value);
            obj.ColumnFormatEnum = format;
            obj.applyColumnFormats()
        end % set.ColumnFormat
        
        % ColumnFormatData
        function set.ColumnFormatData(obj, value)
            obj.ColumnFormatData = value;
            obj.applyColumnFormats()
        end % set.ColumnFormatData
        
        % ColumnName
        function value = get.ColumnName(obj)
            value = obj.evalOnColumns('getHeaderValue');
        end
        function set.ColumnName(obj, value)
            validateattributes(value,{'cell'},{'vector'})
            % Add or remove columns to match
            updateNumberOfColumns(obj,numel(value));
            obj.evalOnColumns('setHeaderValue',value);
        end
        
        % ColumnMinWidth
        function value = get.ColumnMinWidth(obj)
            value = cell2mat( obj.evalOnColumns('getMinWidth') );
        end
        function set.ColumnMinWidth(obj, value)
            validateattributes(value,{'numeric'},...
                {'nonnegative','integer','finite','nonnan','vector'});
            obj.evalOnColumns('setMinWidth',num2cell(value));
            obj.onStyleChanged();
        end
        
        % ColumnMaxWidth
        function value = get.ColumnMaxWidth(obj)
            value = cell2mat( obj.evalOnColumns('getMaxWidth') );
        end
        function set.ColumnMaxWidth(obj, value)
            validateattributes(value,{'numeric'},...
                {'nonnegative','integer','finite','nonnan','vector'});
            obj.evalOnColumns('setMaxWidth',num2cell(value));
            obj.onStyleChanged();
        end
        
        % ColumnPreferredWidth
        function value = get.ColumnPreferredWidth(obj)
            value = cell2mat( obj.evalOnColumns('getPreferredWidth') );
        end
        function set.ColumnPreferredWidth(obj, value)
            validateattributes(value,{'numeric'},...
                {'nonnegative','integer','finite','nonnan','vector'});
            obj.evalOnColumns('setPreferredWidth',num2cell(value));
            obj.onStyleChanged();
        end
        
        % ColumnIsSorted (read-only)
        function value = get.ColumnIsSorted(obj)
            jNumCol = obj.JSortableTableModel.getColumnCount();
            for idx=jNumCol:-1:1
                value(idx) = obj.JSortableTableModel.isColumnSorted(idx-1);
            end
        end
        
        % ColumnSortDirection (read-only)
        function value = get.ColumnSortDirection(obj)
            jNumCol = obj.JSortableTableModel.getColumnCount();
            value = zeros(1,jNumCol);
            for idx=jNumCol:-1:1
                if obj.JSortableTableModel.isColumnSorted(idx-1)
                    if obj.JSortableTableModel.isColumnAscending(idx-1)
                        value(idx) = 1;
                    else
                        value(idx) = -1;
                    end
                end
            end
        end
        
        % ColumnSortable
        function value = get.ColumnSortable(obj)
            jNumCol = obj.JSortableTableModel.getColumnCount();
            for idx=jNumCol:-1:1
                value(idx) = obj.JSortableTableModel.isColumnSortable(idx-1);
            end
        end
        function set.ColumnSortable(obj, value)
            jNumCol = obj.JSortableTableModel.getColumnCount();
            validateattributes(value,{'logical','numeric'},...
                {'nonnegative','integer','finite','nonnan','vector','numel',jNumCol});
            for idx=jNumCol:-1:1
                obj.JSortableTableModel.setColumnSortable(idx-1,value(idx));
            end
        end
        
        % ColumnWidth
        function value = get.ColumnWidth(obj)
            value = cell2mat( obj.evalOnColumns('getWidth') );
        end
        function set.ColumnWidth(obj, value)
            validateattributes(value,{'numeric'},...
                {'nonnegative','integer','finite','nonnan','vector'});
            % Need to turn off auto-resize
            obj.ColumnResizePolicy = 'off';
            obj.evalOnColumns('setWidth',num2cell(value));
            obj.onStyleChanged();
        end
        
        % ColumnResizable
        function value = get.ColumnResizable(obj)
            value = cell2mat( obj.evalOnColumns('getResizable') );
        end
        function set.ColumnResizable(obj, value)
            validateattributes(value,{'logical'},{'vector'});
            obj.evalOnColumns('setResizable',num2cell(value));
        end
        
        % ColumnResizePolicy
        function value = get.ColumnResizePolicy(obj)
            ModeIdx = obj.JControl.getAutoResizeMode();
            value = obj.ValidResizeModes{ModeIdx+1};
        end
        function set.ColumnResizePolicy(obj, value)
            value = validatestring(value,obj.ValidResizeModes);
            ModeIdx = find(strcmp(value,obj.ValidResizeModes), 1) - 1;
            obj.JControl.setAutoResizeMode(ModeIdx);
            obj.onStyleChanged();
        end
        
        % Data
        function value = get.Data(obj)
            % Is the table sorted?
            if ~isempty(obj.RowSortIndex)
                % Yes - use the sorted row index
                jRowIdx = obj.RowSortIndex;
                value = obj.DataM(jRowIdx,:);
            else
                % No - just return the cached data
                value = obj.DataM;
            end
        end % get.Data
        function set.Data(obj, value)
            
            if isequaln(value, obj.Data)
                return
            end
            
            % Convert numeric input to cell, then validate
            mValue = value;
            if isnumeric(value)
                value = num2cell(value);
            end
            validateattributes(value,{'cell','string'},{'2d'})
            
            % Attempt to retain selection
            SelRows = obj.SelectedRows;
            SelCols = obj.SelectedColumns;
            
            % Remove the cached selection, which will later restore
            obj.SelectedRows_ = [];
            obj.SelectedColumns_ = [];
            
            % Convert data to Java types as needed
            jValue = obj.ColumnFormatEnum.toJavaType(value);
            
            % Disable callbacks while updating Java
            obj.CallbacksEnabled = false;
            
            % Set the data in the table. Do not reduce number of columns on
            % Data alone!
            [NumRows, NumCols] = size(value);
            updateNumberOfColumns(obj,NumCols,false) %NO REDUCE
            obj.JTableModel.setDataVector(jValue, obj.ColumnName)
            obj.DataM = mValue;
            
            % Retain the selection if possible
            NewSelRows = SelRows(SelRows <= NumRows);
            NewSelCols = SelCols(SelCols <= NumCols);
            switch obj.SelectionType
                
                case 'row'
                    obj.SelectedRows = NewSelRows;
                    
                case 'column'
                    obj.SelectedColumns = NewSelCols;
                    
                case 'cell'
                    obj.SelectedRows = NewSelRows;
                    obj.SelectedColumns = NewSelCols;
                    
                otherwise %none
                    % Note - the other cases above will trigger redraw when
                    % selection is changed.
                    obj.redraw();
                    
            end %switch obj.SelectionType
            
            % Redraw in case changes have been made
            obj.redrawJava_private();
            
            % Allow Java to catch up
            pause(0.01);
            
            % Re-enable callbacks
            obj.CallbacksEnabled = true;
            
        end
        
        % DataTable
        function value = get.DataTable(obj)
            colNames = obj.ColumnName;
            data = obj.Data;
            if ~iscell(data)
                data = num2cell(data);
            end
            if numel(colNames)~=size(data,2) || any(cellfun(@isempty,colNames))
                value = cell2table(data);
            else
                value = cell2table(data, 'VariableNames', colNames);
            end
        end % get.DataTable
        function set.DataTable(obj, value)
            validateattributes(value,{'table'},{})
            
            mValue = table2cell(value);
            columnName = value.Properties.VariableNames;
            
            % Did the data change?
            if ~isequaln(mValue, obj.Data)
                
                % Attempt to retain selection
                SelRows = obj.SelectedRows;
                SelCols = obj.SelectedColumns;
                
                % Remove the cached selection, which will later restore
                obj.SelectedRows_ = [];
                obj.SelectedColumns_ = [];
                
                % Convert data to Java types as needed
                jValue = obj.ColumnFormatEnum.toJavaType(mValue);
                
                % Disable callbacks while updating Java
                obj.CallbacksEnabled = false;
                
                % Set the data in the table
                [NumRows, NumCols] = size(value);
                updateNumberOfColumns(obj,NumCols,true) %REDUCE COLUMNS IF NEEDED
                obj.JTableModel.setDataVector(jValue, columnName)
                obj.DataM = mValue;
                obj.ColumnName = columnName;
                
                % Retain the selection if possible
                NewSelRows = SelRows(SelRows <= NumRows);
                NewSelCols = SelCols(SelCols <= NumCols);
                switch obj.SelectionType
                    
                    case 'row'
                        obj.SelectedRows = NewSelRows;
                        
                    case 'column'
                        obj.SelectedColumns = NewSelCols;
                        
                    case 'cell'
                        obj.SelectedRows = NewSelRows;
                        obj.SelectedColumns = NewSelCols;
                        
                    otherwise %none
                        obj.redraw();
                        
                end %switch obj.SelectionType
                
                % Redraw in case changes have been made
                obj.redrawJava_private();
                
                % Allow Java to catch up
                pause(0.01);
                
                % Re-enable callbacks
                obj.CallbacksEnabled = true;
                
            elseif ~isequal(obj.ColumnName, columnName)
                obj.ColumnName = columnName;
            end
        end
        
        % Editable
        function set.Editable(obj, value)
            if ischar(value) || ( isscalar(value) && isstring(value) )
                value = strcmp(value,'on');
            end
            validateattributes(value,{'logical','numeric'},{'real','scalar'});
            obj.Editable = logical(value);
            obj.redrawJava_private();
        end
        
        % RowHeight
        function set.RowHeight(obj, value)
            validateattributes(value,{'numeric'},{'real','scalar','>=',-1});
            obj.RowHeight = value;
            obj.onStyleChanged();
        end
        
        % RowSortIndex (protected)
        function value = get.RowSortIndex(obj)
            value = obj.JSortableTableModel.getIndexes()+1;
        end
        
        % Sortable
        function value = get.Sortable(obj)
            value = obj.JControl.SortingEnabled;
        end
        function set.Sortable(obj, value)
            validateattributes(value,{'logical','numeric'},{'real','scalar'});
            obj.JControl.SortingEnabled = logical(value);
        end
        
        % SelectedColumns
        function value = get.SelectedColumns(obj)
            value = obj.SelectedColumns_;
        end
        function set.SelectedColumns(obj, value)
            validateattributes(value,{'numeric'},{'real','integer',...
                'positive','<=',obj.JTableModel.getColumnCount()});
            
            % Set the new value
            if isvalid(obj)
                jColumnModel = obj.JControl.getColumnModel();
                jColumnSelectionModel = jColumnModel.getSelectionModel();
                jColumnSelectionModel.clearSelection();
                for idx = 1:numel(value)
                    jColumnSelectionModel.addSelectionInterval(value(idx)-1, value(idx)-1);
                end
                obj.SelectedColumns_ = value;
            end
            
            % Scroll to the selection
            obj.scrollToSelection();
            
            % Redraw in case changes have been made
            obj.redraw();
            
        end % set.SelectedColumns
        
        % SelectedRows
        function value = get.SelectedRows(obj)
            value = obj.SelectedRows_;
        end
        function set.SelectedRows(obj, value)
            validateattributes(value,{'numeric'},{'real','integer',...
                'positive','<=',size(obj.DataM,1)});
            
            % Set the new value
            if isvalid(obj)
                obj.JSelectionModel.clearSelection()
                for idx = 1:numel(value)
                    obj.JSelectionModel.addSelectionInterval(value(idx)-1, value(idx)-1);
                end
                obj.SelectedRows_ = value;
            end
            
            % Scroll to the selection
            obj.scrollToSelection();
            
            % Redraw in case changes have been made
            obj.redraw();
            
        end % set.SelectedRows
        
        % SelectedData
        function value = get.SelectedData(obj)
            value = obj.DataM(obj.SelectedRows, obj.SelectedColumns);
        end
        
        % SelectionMode
        function set.SelectionMode(obj, value)
            value = validatestring(value,obj.ValidSelectionModes);
            obj.SelectionMode = value;
            obj.applySelectionModel();
        end
        
        %  SelectionType
        function set.SelectionType(obj, value)
            value = validatestring(value,obj.ValidSelectionTypes);
            obj.SelectionType = value;
            obj.applySelectionModel();
        end
        
    end % get/set methods
    
    
end % classdef