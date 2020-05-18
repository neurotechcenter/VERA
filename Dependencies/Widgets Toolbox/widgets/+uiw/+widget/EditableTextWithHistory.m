classdef EditableTextWithHistory < uiw.abstract.EditablePopupControl ...
        & uiw.mixin.HasEditableTextField
    % EditableTextWithHistory - A popup control with editable text
    %
    % Create a widget that is for editable text with a popup for history
    %
    % Syntax:
    %           w = uiw.widget.EditableTextWithHistory('Property','Value',...)
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
    properties (AbortSet, Dependent)
        History (:,1) string %History items list [string]
    end
    
    
    %% Constructor / Destructor
    methods
        function obj = EditableTextWithHistory(varargin)
            
            % Call superclass constructors
            obj@uiw.abstract.EditablePopupControl();
            
            % Set properties from P-V pairs
            obj.assignPVPairs(varargin{:});
            
            % Assign the construction flag
            obj.IsConstructed = true;
            obj.CallbacksEnabled = false;
            
            % Redraw the widget
            obj.onResized();
            obj.onEnableChanged();
            obj.onStyleChanged();
            obj.redraw();
            
            % Now enable callbacks
            obj.CallbacksEnabled = true;
            
        end % constructor
        
    end %methods - constructor/destructor
    
    
    
    %% Protected methods
    methods (Access=protected)
        
        function setValue(obj,value)
            % Set the selection to Java control
            
            validateattributes(value,{'char'},{})
            
            % Add the history
            %RAJ move to set.Value?
            obj.addHistory(obj.interpretValueAsString(value));
            
            % Call superclass method
            obj.setValue@uiw.abstract.EditablePopupControl(value);
            
        end %function
        
        
        function addHistory(obj,str)
            % Add the string to the top of history
            
            if ~isempty(str)
                obj.CallbacksEnabled = false;
                isDupe = strcmp(str,obj.History);
                if any(isDupe)
                    idxDupe = find(isDupe,1);
                    obj.JControl.removeItemAt(idxDupe - 1);
                end
                obj.JControl.insertItemAt(str,0);
                obj.CallbacksEnabled = true;
            end
            
        end %function
        
    end % Protected methods
    
    
    %% Get/Set methods
    methods
        
        % Items
        function value = get.History(obj)
            value = string.empty(0,1);
            if obj.IsConstructed
                jModel = obj.JControl.getModel();
                nItems = jModel.getSize();
                for idx=1:nItems
                    value{idx,1} = char(jModel.getElementAt(idx-1));
                end
            end
        end
        function set.History(obj,value)
            currentValue = obj.Value;
            jModel = javaObjectEDT('javax.swing.DefaultComboBoxModel',value);
            obj.CallbacksEnabled = false;
            obj.JControl.setModel(jModel);
            javaMethod('setSelectedItem',obj.JControl,currentValue);
            obj.CallbacksEnabled = true;
        end
        
    end % Get/Set methods
    
end % classdef
