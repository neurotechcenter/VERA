classdef ColorOrderSelector < uiw.widget.ListWithButtons
    % ColorOrderSelector - A color order selection control
    %
    % Create a widget that allows you to select color order for a plot
    %
    
%   Copyright 2017-2019 The MathWorks Inc.
    %
    % Auth/Revision:
    %   MathWorks Consulting
    %   $Author: rjackey $
    %   $Revision: 324 $
    %   $Date: 2019-04-23 08:05:17 -0400 (Tue, 23 Apr 2019) $
    % ---------------------------------------------------------------------
    
    
    %% Properties
    properties
        Editing (1,1) logical = false % Indicates whether the widget is in edit mode [true|(false)]
    end
    
    properties (Dependent)
        ColorOrder % The current color order matrix
    end
    
    
    %% Constructor / Destructor
    methods
        
        function obj = ColorOrderSelector(varargin)
            % Construct the control
            
            % Default Value
            colorOrder = get(groot,'DefaultAxesColorOrder');
            colorOrderCell = num2cell(colorOrder,2);
            colorOrderStr = cellfun(@num2str,colorOrderCell,'UniformOutput',false);
            
            % Populate public properties from P-V input pairs
            obj.assignPVPairs(...
                'AllowAdd', false, ...
                'AllowMultiSelect', true, ...
                'AllowMove', true, ...
                'AllowEdit', true, ...
                'ButtonLocation','right', ...
                'Items', colorOrderStr,...
                varargin{:});
            
            % Visual tweaks
            obj.h.Listbox.HorizontalAlignment = 'left'; %for edit mode
            
            % Edit button is toggle
            idxEdit = strcmp({obj.h.Button.Tag},'Edit');
            obj.h.Button(idxEdit).Style = 'toggle';
            
            % Assign the construction flag
            obj.IsConstructed = true;
            
            % Redraw the widget
            obj.onEnableChanged();
            obj.redraw();
            obj.onResized();
            obj.onStyleChanged();
            
        end %constructor
        
    end %methods - constructor/destructor
    
    
    
    %% Protected methods
    methods (Access = 'protected')
        
        %         function redraw(obj)
        %             % Handle state changes that may need UI redraw
        %
        %             % Ensure the construction is complete
        %             if obj.IsConstructed
        %
        %             % Call superclass method
        %             obj.redraw@uiw.widget.ListWithButtons();
        %
        %             end %if obj.IsConstructed
        %
        %         end %function obj.redraw()
        
        
        function redrawButtons(obj,selRows,numRows)
            % Handle updates to Enable state of the individual buttons
            
            % Call superclass implementation
            obj.redrawButtons@uiw.mixin.HasListSortingButtons(selRows,numRows);
            
            % Edit is always available in this case
            idxEdit = strcmp({obj.h.Button.Tag},'Edit');
            obj.h.Button(idxEdit).Enable = 'on';
            
        end %function
        
        
        function startEdit(obj)
            % Start edit mode
            
            % All buttons except edit become disabled
            idxEdit = strcmp({obj.h.Button.Tag},'Edit');
            set(obj.h.Button(~idxEdit),'Enable','off');
            
            % Make the listbox an edit box
            obj.h.Listbox.Style = 'edit';
            
            
        end %function
        
        
        function newValue = finishEdit(obj)
            % Finish edit mode
            
            % Get the value
            newValueStr = obj.h.Listbox.String;
            
            % Parse the value and validate
            newValueCell = cellfun(@str2num,newValueStr,'UniformOutput',false);
            rowSize = cellfun(@numel,newValueCell,'UniformOutput',true);
            newValue = [];
            if all(rowSize == 3)
                newValue = cell2mat(newValueCell);
                if all(newValue(:)>=0) && all(newValue(:)<=1)
                    % Result is ok
                    obj.h.Listbox.Value = [];
                    obj.Items = newValueStr;
                end
            end
            if ~isempty(newValueStr)
                obj.SelectedIndex = 1;
            end
            
            % Make the listbox an listbox again
            obj.h.Listbox.Style = 'listbox';
            
            % Throw an error if necessary
            if isempty(newValue)
                message = 'Color Order must be a N*3 array with all values between 0 and 1';
                uiwait( errordlg(message,'Color Order','modal') );
            end
            
            obj.redraw();
            
        end %function
        
        
        function onButtonPressed(obj,h,evt)
            % Triggered on button press
            
            % Take custom action
            switch h.Tag
                
                case {'MoveDown','MoveUp'}
                    
                    % Call the superclass implementation
                    obj.onButtonPressed@uiw.widget.ListWithButtons(h,evt)
                    
                case 'Delete'
                    
                    % Prepare event data
                    evt = struct('Source',obj,'Interaction',h.Tag);
                    evt.SelectedItems = obj.SelectedItems;
                    evt.SelectedIndex = obj.SelectedIndex;
                    
                    % Delete the row
                    obj.Items(obj.SelectedIndex) = [];
                    
                    % Call the callback
                    obj.callCallback(evt);
                    
                case 'Edit'
                    if obj.Editing
                        
                        % Prepare event data
                        evt = struct('Source',obj,'Interaction',h.Tag);
                        evt.OldValue = obj.Items;
                        
                        % Complete editing and get the new value
                        obj.Editing = false;
                        newValue = obj.finishEdit();
                        evt.NewValue = newValue;
                        
                        % Verify a valid change
                        if ~isempty(newValue)
                            % Call the callback
                            obj.callCallback(evt);
                        end
                        
                    else
                        obj.Editing = true;
                        obj.startEdit();
                    end
                    
            end %switch Interaction
            
        end %function onButtonPressed
        
        
        function onSelectionChanged(obj)
            % Triggered on selection change
            
            % Call the superclass implementation, only if not editing
            if ~obj.Editing
                obj.onSelectionChanged@uiw.widget.ListWithButtons()
            end
            
        end %function onAddButtonPressed
        
    end %protected Methods
    
    
    
    %% Get/Set methods
    methods
        
        % ColorOrder
        function value = get.ColorOrder(obj)
            colorOrderStr = obj.Items;
            colorOrderCell = cellfun(@str2num,colorOrderStr,'UniformOutput',false);
            value = cell2mat(colorOrderCell);
        end
        function set.ColorOrder(obj,value)
            validateattributes(value,{'numeric'},{'size',[NaN 3],'>=',0,'<=',1})
            colorOrderCell = num2cell(value,2);
            colorOrderStr = cellfun(@num2str,colorOrderCell,'UniformOutput',false);
            obj.Items = colorOrderStr;
        end
        
    end % Get/Set methods
    
    
end %classdef
