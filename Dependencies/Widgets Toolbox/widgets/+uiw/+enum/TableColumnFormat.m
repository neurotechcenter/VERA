classdef TableColumnFormat < handle
    % TableColumnFormat - Enumeration of column formats for a Table widget
    %
    % Abstract: This contains the information for column formats
    %
    % Syntax:
    %           obj = uiw.enum.TableColumnFormat.<MEMBER>
    %
    % TableColumnFormat Properties:
    %
    %     Renderer - the Java cell renderer
    %
    %     Editor - the Java cell editor
    %
    % TableColumnFormat Options:
    %
    %   Set the Table widget's ColumnFormat to a cell array containing char
    %   values of a combination of the following choices:
    %
    %       '' (default format - no special treatment)
    %       'numeric' (floating point numbers)
    %       'integer' (integer numbers)
    %       'logical' (checkbox)
    %       'char' (single line text)
    %       'longchar' (multi-line text)
    %       'popup' (popup/dropdown single selection)
    %       'popuplist' (popup/dropdown multi-selection)
    %       'bank' (2 decimal places, red if negative, specify
    %               ColumnFormatData with a Java number format,
    %               e.g. '#,##0.00', to customize the display,
    %               decimal places, punctuation, etc.)
    %       'date' (date selection, no time)
    %       'color' (cell data is [R, G, B] format)
    %       'imageicon' (cell data is a file path to an image to display)
    %       'custom' (not fully supported, but similar to 'bank', specify a
    %               number format in ColumnFormatData)
    %
    %   Example:
    %       t.ColumnFormat = {'bank','numeric','popup','popuplist'};
    %       t.ColumnFormatData = {'$ #,##0.00',[],{'apples','oranges'},{'fork','spoon','knife'} };
    %
    
%   Copyright 2017-2019 The MathWorks Inc.
    %
    % Auth/Revision:
    %   MathWorks Consulting
    %   $Author: rjackey $
    %   $Revision: 324 $  $Date: 2019-04-23 08:05:17 -0400 (Tue, 23 Apr 2019) $
    % ---------------------------------------------------------------------
    
    
    %% Enumerations
    enumeration
        DEFAULT('')
        NUMERIC('numeric')
        INTEGER('integer')
        LOGICAL('logical')
        CHAR('char')
        LONGCHAR('longchar')
        POPUP('popup')
        POPUPLIST('popuplist')
        BANK('bank')
        DATE('date')
        COLOR('color')
        IMAGEICON('imageicon')
        CUSTOM('custom')
    end %enumeration
    
    
    %% Properties
    properties (SetAccess=immutable)
        Name = '' %The user viewable/settable name for this column format
        DefaultFormat = '' %The default ColumnFormatData to use, if the table's ColumnFormatData is empty
        RendererClass %The Java class to instantiate for the column renderer
        EditorClass %The Java class to instantiate for the column editor
        NeedsCustomRenderer = false %True if we can't reuse the same renderer on multiple columns, e.g. we need to instantiate a new editor for each column
        NeedsCustomEditor = false %True if we can't reuse the same editor on multiple columns, e.g. we need to instantiate a new editor for each column
        RendererNeedsFormatData = false %True if the Java renderer needs to use the table's ColumnFormatData
        EditorNeedsFormatData = false %True if the Java editor needs to use the table's ColumnFormatData
        ToJavaFcn %Function to convert a column cell array to Java format
        FromJavaFcn %Function to convert a single cell's data back to MATLAB format
    end
    
    % These are instantiated on the first access, unless a custom renderer or
    % editor is needed for that particular column
    properties (SetAccess=private)
        Renderer %The Java cell renderer for this column format
        Editor %The Java cell editor for this column format
    end %properties
    
    
    %% Constructor
    methods
        function obj = TableColumnFormat(name)
            % Construct the enumeration members
            
            obj.Name = name;
            
            switch name
                
                case 'numeric'
                    obj.RendererClass = 'com.jidesoft.grid.NumberCellRenderer';
                    obj.EditorClass = 'com.jidesoft.grid.DoubleCellEditor';
                    
                case 'integer'
                    obj.RendererClass = 'com.jidesoft.grid.NumberCellRenderer';
                    obj.EditorClass = 'com.jidesoft.grid.IntegerCellEditor';
                    
                    obj.ToJavaFcn = @(x)cellfun(@fix,x,'UniformOutput',false); %discard any decimal
                    
                case 'logical'
                    obj.RendererClass = 'com.jidesoft.grid.BooleanCheckBoxCellRenderer';
                    obj.EditorClass = 'com.jidesoft.grid.BooleanCheckBoxCellEditor';
                    
                case 'char'
                    obj.RendererClass = 'javax.swing.table.DefaultTableCellRenderer';
                    obj.EditorClass = 'com.jidesoft.grid.StringCellEditor';
                    
                case 'longchar'
                    %obj.RendererClass = 'javax.swing.table.DefaultTableCellRenderer';
                    obj.RendererClass = 'com.jidesoft.grid.MultilineStringCellRenderer';
                    obj.EditorClass = 'com.jidesoft.grid.MultilineStringCellEditor';
                    
                case 'popup'
                    %obj.RendererClass = 'javax.swing.table.DefaultTableCellRenderer';
                    obj.RendererClass = 'com.jidesoft.grid.ContextSensitiveCellRenderer';
                    if ismac
                        %obj.EditorClass = 'com.mathworks.consulting.widgets.table.PopupCellEditor';
                        obj.EditorClass = 'com.jidesoft.grid.LegacyListComboBoxCellEditor';
                    else
                        obj.EditorClass = 'com.jidesoft.grid.ListComboBoxCellEditor';
                    end
                    
                    obj.NeedsCustomEditor = true;
                    obj.EditorNeedsFormatData = true;
                    obj.DefaultFormat = ' ';
                    
                case 'popuplist'
                    obj.RendererClass = 'com.jidesoft.grid.MultilineTableCellRenderer';
                    if ismac
                        %obj.EditorClass = 'com.mathworks.consulting.widgets.table.PopupCellEditor';
                        obj.EditorClass = 'com.jidesoft.grid.LegacyCheckBoxListComboBoxCellEditor';
                    else
                        obj.EditorClass = 'com.jidesoft.grid.CheckBoxListComboBoxCellEditor';
                    end
                    
                    obj.NeedsCustomEditor = true;
                    obj.EditorNeedsFormatData = true;
                    obj.DefaultFormat = ' ';
                    
                    obj.FromJavaFcn = @(x)uiw.utility.java2mat(x);
                    
                case 'bank'
                    obj.RendererClass = 'com.mathworks.consulting.widgets.table.NumberCellRenderer';
                    obj.EditorClass = 'com.jidesoft.grid.DoubleCellEditor';
                    
                    obj.NeedsCustomRenderer = true;
                    obj.RendererNeedsFormatData = true;
                    obj.DefaultFormat = '#,##0.00';
                    
                    %obj.FromJavaFcn = @(x)str2double(x);
                    
                case 'date'
                    obj.RendererClass = 'com.mathworks.consulting.widgets.table.DateCellRenderer';
                    if ismac
                        obj.EditorClass = 'com.mathworks.consulting.widgets.table.LegacyDateCellEditor';
                    else
                        obj.EditorClass = 'com.mathworks.consulting.widgets.table.DateCellEditor';
                        
                    end
                    
                    obj.NeedsCustomEditor = true;
                    obj.EditorNeedsFormatData = true;
                    obj.NeedsCustomRenderer = true;
                    obj.RendererNeedsFormatData = true;
                    obj.DefaultFormat = 'MMMM dd, yyyy';
                    
                    obj.ToJavaFcn = @(x)uiw.utility.mat2java(x);
                    obj.FromJavaFcn = @(x)uiw.utility.java2mat(x);
                    
                case 'color'
                    obj.RendererClass = 'com.jidesoft.grid.ColorCellRenderer';
                    if ismac
                        %obj.EditorClass = 'com.jidesoft.grid.StringCellEditor';
                        obj.EditorClass = 'com.jidesoft.grid.LegacyColorCellEditor';
                    else
                        obj.EditorClass = 'com.jidesoft.grid.ColorCellEditor';
                    end
                    
                    obj.ToJavaFcn = @(x)uiw.utility.mat2java(x,'java.awt.Color');
                    obj.FromJavaFcn = @(x)uiw.utility.java2mat(x);
                    
                case 'imageicon'
                    obj.RendererClass = 'com.jidesoft.grid.IconCellRenderer';
                    
                    obj.ToJavaFcn = @(x)uiw.utility.mat2java(x,'javax.swing.ImageIcon');
                    obj.FromJavaFcn = @(x)uiw.utility.java2mat(x);
                    
                case 'custom'
                    obj.RendererClass = 'com.mathworks.consulting.widgets.table.NumberCellRenderer';
                    obj.EditorClass = 'com.jidesoft.grid.DoubleCellEditor';
                    
                    obj.NeedsCustomRenderer = true;
                    obj.RendererNeedsFormatData = true;
                    
                otherwise
                    obj.RendererClass = 'javax.swing.table.DefaultTableCellRenderer';
                    obj.EditorClass = 'com.jidesoft.grid.StringCellEditor';
                    
            end %switch
            
        end %constructor
    end %methods
    
    
    %% Public Methods
    methods
        
        %% Conversion from MATLAB to Java by column format
        function jValue = toJavaType(obj,mValue)
            % Convert a data column to the Java data equivalent by column format
            
            % Copy the input over
            jValue = mValue;
            
            % What columns need conversion?
            needConvert = find( ~cellfun(@isempty, {obj.ToJavaFcn}) );
            numCol = size(mValue,2);
            for idx = 1:numel(needConvert)
                thisIdx = needConvert(idx);
                if thisIdx<=numCol
                    % Convert to java type
                    jValue(:,thisIdx) = obj(thisIdx).ToJavaFcn( mValue(:,thisIdx) );
                end
            end
            
        end %function
        
        
        %% Conversion from Java to MATLAB by column format
        function mValue = toMLType(obj,jValue)
            % Convert a Java value to MATLAB equivalent by column format
            
            % Convert to java type
            if isempty(obj.FromJavaFcn)
                mValue = jValue;
            else
                mValue = obj.FromJavaFcn(jValue);
            end
            
        end %function
        
        
        
        %% Cell Renderers
        function [renderers, editors] = getColumnRenderersEditors(obj,formatData)
            % Get renderers and editors for each column, based on settings
            % provided
            
            % Prep formatData
            NumFormats = numel(obj);
            if numel(formatData) < NumFormats
                formatData{NumFormats} = [];
            end
            
            % Preallocate
            renderers = cell(1,NumFormats);
            editors = cell(1,NumFormats);
            
            % Loop on each column format
            for idx=1:NumFormats
                
                % Check if we need to create a Java renderer object
                if isempty(obj(idx).Renderer) || obj(idx).NeedsCustomRenderer
                    if obj(idx).RendererNeedsFormatData
                        thisFormatData = formatData{idx};
                        if isempty(thisFormatData)
                            thisFormatData = obj(idx).DefaultFormat;
                        end
                        jRenderer = javaObject(obj(idx).RendererClass, thisFormatData);
                    else
                        jRenderer = javaObject(obj(idx).RendererClass);
                    end
                    
                    renderers{idx} = jRenderer;
                    if ~obj(idx).NeedsCustomRenderer
                        obj(idx).Renderer = jRenderer;
                    end
                else
                    renderers{idx} = obj(idx).Renderer;
                end %if
                
                % Check if we need to create a Java editor object
                if isempty(obj(idx).Editor) || obj(idx).NeedsCustomEditor
                    if isempty(obj(idx).EditorClass)
                        jEditor = [];
                    elseif obj(idx).EditorNeedsFormatData
                        thisFormatData = formatData{idx};
                        if isempty(thisFormatData)
                            thisFormatData = obj(idx).DefaultFormat;
                        end
                        jEditor = javaObject(obj(idx).EditorClass, thisFormatData);
                    else
                        jEditor = javaObject(obj(idx).EditorClass);
                    end
                    
                    editors{idx} = jEditor;
                    if ~obj(idx).NeedsCustomEditor
                        obj(idx).Editor = jEditor;
                    end
                else
                    editors{idx} = obj(idx).Editor;
                end %if
                
            end %for idx=1:numel(obj)
            
        end %function
        
    end %methods
    
    
    
    %% Static Methods
    methods (Static)
        
        function obj = fromName(name)
            % Return the TableColumnFormat enumeration matching a name
            
            validateattributes(name,{'char','cell'},{});
            name = cellstr(name);
            objList = enumeration('uiw.enum.TableColumnFormat');
            validNames = {objList.Name};
            name = cellfun(@(x)validatestring(x,validNames),name,'Uni',false);
            for idx=numel(name):-1:1
                obj(idx) = objList(strcmp(name{idx},validNames));
            end
            
        end %function
        
    end %methods
    
end % classdef