classdef EditablePopup < uiw.abstract.EditablePopupControl
    % EditablePopup - A popup control with editable text
    %
    % Create a widget that is an editable popup/combobox/dropdown
    %
    % Syntax:
    %           w = uiw.widget.EditablePopup('Property','Value',...)
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
    properties (AbortSet)
        Items cell = cell(0,1) %Cell array of all items in the list [cell of strings]
    end
    
    properties (Dependent, AbortSet)
        SelectedIndex double % The selected index from the list of choices (0 if edited)
    end
    
    
    %% Constructor / Destructor
    methods
        function obj = EditablePopup(varargin)
            
            % Call superclass constructors
            obj@uiw.abstract.EditablePopupControl();
            
            % These args must be set last
            [lastArgs,firstArgs] = obj.splitArgs({'SelectedIndex'},varargin{:});
            
            % Set properties from P-V pairs
            obj.assignPVPairs(firstArgs{:},lastArgs{:});
            
            % Do the following only if the object is not a subclass
            if strcmp(class(obj), 'uiw.widget.EditablePopup') %#ok<STISA>
                
                % Assign the construction flag
                obj.IsConstructed = true;
                
                % Redraw the widget
                obj.onResized();
                obj.onEnableChanged();
                obj.onStyleChanged();
                obj.redraw();
                
            end %if strcmp(class(obj),...
            
        end % constructor
        
    end %methods - constructor/destructor
    
    
    
    %% Protected methods
    methods (Access=protected)
        
        function onTextEdited(obj,~,e)
            % Handle interaction with text field
            
            % Ensure the construction is complete
            if obj.isvalid && obj.IsConstructed && obj.CallbacksEnabled
                
                str = deblank(obj.getValue());
                value = obj.interpretStringAsValue(str);
                
                % What do we do next?
                if isa(e,'java.awt.event.KeyEvent')
                    % Key press
                    
                    % Prepare event data
                    evt = struct('Source', obj, ...
                        'Interaction', 'KeyPress', ...
                        'PendingValue', value, ...
                        'PendingString', str, ...
                        'OldSelectedIndex', obj.SelectedIndex, ...
                        'NewSelectedIndex', [],...
                        'OldValue', obj.Value, ...
                        'NewValue', obj.Value);
                    
                    % Call the callback
                    if ~isequal(evt.OldValue,evt.PendingValue)
                        obj.callCallback(evt);
                    end
                    
                elseif ~checkValue(obj,value)
                    % Value was invalid, so revert
                    
                    %obj.CallbacksEnabled = false;
                    str = obj.interpretValueAsString(obj.Value);
                    obj.setValue(str);
                    %obj.CallbacksEnabled = true;
                    
                elseif ~isequal(obj.Value, value)
                    % Trigger callback if value changed
                    
                    % Prepare event data
                    evt = struct('Source', obj, ...
                        'Interaction', 'Edit', ...
                        'OldSelectedIndex', obj.SelectedIndex, ...
                        'NewSelectedIndex', [],...
                        'OldValue', obj.Value, ...
                        'NewValue', value,...
                        'NewString', str);
                    
                    % Set the value
                    obj.Value = value;
                    evt.NewSelectedIndex = obj.SelectedIndex;
                    
                    % Call the callback
                    obj.callCallback(evt);
                    
                end %if ~ok
                
            end %if obj.IsConstructed && obj.CallbacksEnabled
            
        end %function
        
    end % Protected methods
    
    
    %% Get/Set methods
    methods
        
        % Items
        function set.Items(obj,value)
            validateattributes(value,{'cell'},{})
            value = cellstr(value(:)');
            obj.Items = value;
            % If the Items was just edited, perhaps we shouldn't replace
            % the whole model. Only replace model if very new Items? Check
            % performance.
            if isempty(value)
                value = {''};
            end
            currentValue = obj.Value;
            jModel = javaObjectEDT('javax.swing.DefaultComboBoxModel',value);
            obj.JControl.setModel(jModel);
            javaMethod('setSelectedItem',obj.JControl,currentValue);
        end
        
        % SelectedIndex
        function value = get.SelectedIndex(obj)
            value = javaMethodEDT('getSelectedIndex',obj.JControl) + 1;
            if value==0
                value = [];
            end
        end
        function set.SelectedIndex(obj,value)
            obj.CallbacksEnabled = false;
            validateattributes(value,{'numeric'},{'nonnegative','integer','finite','<=',numel(obj.Items)})
            if value~=0
                obj.Value = obj.Items{value};
            else
                obj.Value = '';
            end
            %javaMethodEDT('setSelectedIndex',obj.JControl,value-1);
            obj.CallbacksEnabled = true;
        end
        
    end % Get/Set methods
    
end % classdef
