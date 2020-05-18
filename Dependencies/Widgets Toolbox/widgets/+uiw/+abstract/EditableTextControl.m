classdef (Abstract) EditableTextControl < uiw.abstract.WidgetContainer ...
        & uiw.mixin.HasEditableTextField & uiw.mixin.HasCallback
    % EditableTextControl  - Base class for an editable text control
    %
    % This is an abstract base class and cannot be instantiated. It
    % provides an 'edit' style uicontrol that may be customized by a
    % subclass. It also has a label which may optionally be used. The label
    % will be shown once any Label* property has been set.
    
%   Copyright 2008-2019 The MathWorks Inc.
    %
    % Auth/Revision:
    %   MathWorks Consulting
    %   $Author: rjackey $
    %   $Revision: 324 $
    %   $Date: 2019-04-23 08:05:17 -0400 (Tue, 23 Apr 2019) $
    % ---------------------------------------------------------------------
    
    %% Properties
    properties (GetAccess=protected, SetAccess=protected)
        hEditBox matlab.graphics.Graphics % The editable text control
    end
    
    properties (AbortSet, Dependent)
        IsMultiLine logical % Single line or multi-line text?
    end
    
    
    %% Constructor
    methods
        function obj = EditableTextControl()
            % Construct the control
            
            % Call superclass constructors
            obj@uiw.abstract.WidgetContainer();
            
            obj.hEditBox = uicontrol(...
                'Parent',obj.hBasePanel,...
                'Style','edit',...
                'HorizontalAlignment','left',...
                'Units','normalized',...
                'Position',[0 0 1 1],...
                'Callback', @(h,e)obj.onTextEdited() );
            
            obj.hTextFields = obj.hEditBox;
            
        end % constructor
    end %methods
    
    
    %% Protected Methods
    methods (Access=protected)
        
        function onEnableChanged(obj,~)
            % Handle updates to Enable state - subclass may override
            if obj.IsConstructed
                
                % Call superclass methods
                onEnableChanged@uiw.abstract.WidgetContainer(obj);
                onEnableChanged@uiw.mixin.HasEditableText(obj);
                
            end %if obj.IsConstructed
        end % function
        
        
        function onStyleChanged(obj,~)
            % Handle updates to style and value validity changes - subclass may override
            if obj.IsConstructed
                
                % Call superclass methods
                onStyleChanged@uiw.abstract.WidgetContainer(obj);
                onStyleChanged@uiw.mixin.HasEditableText(obj);
                
            end %if obj.IsConstructed
        end % function
        
        
        function onValueChanged(obj,evt)
            % Handle updates to value changes - subclass may override
            
            str = evt.NewString;
            if ~isequal(str, obj.hEditBox.String)
                obj.hEditBox.String = str;
                obj.redraw();
            end
            
        end % function
        
        
        function onTextEdited(obj)
            % Triggered on text interaction - subclass may override
            
            % Ensure the construction is complete
            if obj.IsConstructed
                str = obj.hEditBox.String;
                value = obj.interpretStringAsValue(str);
                
                % Validate
                ok = checkValue(obj,value);
                if ok
                    % Trigger callback if value changed
                    if ~isequal(obj.Value, value)
                        evt = struct('Source', obj, ...
                            'Interaction', 'Edit', ...
                            'OldValue', obj.Value, ...
                            'NewValue', value);
                        obj.Value = obj.interpretValueAsString(value);
                        obj.callCallback(evt);
                    end
                else
                    % Value was invalid, so revert
                    str = obj.interpretValueAsString(obj.Value);
                    obj.hEditBox.String = str;
                end
                
            end %if obj.IsConstructed
        end % onTextEdited
        
    end %methods
    
    
    %% Get/Set methods
    methods
        
        function isMultiLine = get.IsMultiLine(obj)
            isMultiLine = (obj.hEditBox.Max - obj.hEditBox.Min)>1;
        end
        function set.IsMultiLine(obj,value)
            validateattributes(value,{'logical'},{'scalar'});
            obj.hEditBox.Min = 0;
            if value
                obj.hEditBox.Max = 2; %change the edit box to multiline
            else
                obj.hEditBox.Max = 1; %change the edit box to single line
            end
            
        end
        
    end % Get/Set methods
    
    
end % classdef