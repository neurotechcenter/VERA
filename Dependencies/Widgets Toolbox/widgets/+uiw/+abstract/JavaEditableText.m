classdef (Abstract) JavaEditableText < uiw.abstract.JavaControl & ...
        uiw.mixin.HasCallback & uiw.mixin.HasEditableText & uiw.mixin.HasValueEvents
    % JavaEditableText - Base class for JAVA editable text widgets
    % 
    % This is an abstract base class and cannot be instantiated. It
    % provides the basic properties and methods needed for a widget with a
    % Java control that is an editable text field. It also has a label
    % which may optionally be used. The label will be shown once any Label*
    % property has been set.
    %
    
%   Copyright 2008-2019 The MathWorks Inc.
    %
    % Auth/Revision:
    %   MathWorks Consulting
    %   $Author: rjackey $
    %   $Revision: 324 $
    %   $Date: 2019-04-23 08:05:17 -0400 (Tue, 23 Apr 2019) $
    % ---------------------------------------------------------------------

    
    %% Protected Methods
    methods (Access=protected)
        
        function redraw(obj)
            % Handle state changes that may need UI redraw - subclass may override
            
            % Ensure the construction is complete
            if obj.IsConstructed
                
                str = obj.interpretValueAsString(obj.Value);
                obj.setValue(str);
                
            end %if obj.IsConstructed
            
        end % redraw
        
        
        function onResized(obj,~,~)
            % Handle changes to widget size - subclass may override
            
            % Ensure the construction is complete
            if obj.IsConstructed
                
                % Get widget dimensions
                [w,h] = obj.getInnerPixelSize;
                
                % Position the HG container of the Java widget
                obj.HGJContainer.Position = [1 1 w h];
                
            end %if obj.IsConstructed
            
        end %function 
        
        
        function onEnableChanged(obj,~,~)
            % Handle updates to Enable state - subclass may override
            
            % Ensure the construction is complete
            if obj.IsConstructed
                
                % Call superclass methods
                onEnableChanged@uiw.abstract.JavaControl(obj);
                onEnableChanged@uiw.mixin.HasEditableText(obj);
                
                % Enable/Disable the Java control
                obj.JControl.setEditable( strcmpi(obj.TextEditable,'on') );
                
            end %if obj.IsConstructed
            
        end %function 
        
        
        % This method may be overridden for custom behavior
        function onStyleChanged(obj,~)
            % Handle updates to style and value validity changes - subclass may override
            
            % Ensure the construction is complete
            if obj.IsConstructed
                
                % Call superclass methods
                onStyleChanged@uiw.abstract.JavaControl(obj);
                onStyleChanged@uiw.mixin.HasEditableText(obj);
                
                % Set TextHorizontalAlignment
                jEnum = upper(obj.TextHorizontalAlignment);
                jValue = javax.swing.SwingConstants.(jEnum);
                obj.JEditor.setHorizontalAlignment(jValue);
                
                % Set Colors
                if obj.TextIsValid
                        jColor = obj.rgbToJavaColor(obj.TextForegroundColor);
                        obj.JEditor.setForeground(jColor)
                        jColor = obj.rgbToJavaColor(obj.TextBackgroundColor);
                        obj.JEditor.setBackground(jColor);
                else
                    if ~isempty(obj.TextInvalidForegroundColor)
                        jColor = obj.rgbToJavaColor(obj.TextInvalidForegroundColor);
                        obj.JEditor.setForeground(jColor)
                    end
                    if ~isempty(obj.TextInvalidBackgroundColor)
                        jColor = obj.rgbToJavaColor(obj.TextInvalidBackgroundColor);
                        obj.JEditor.setBackground(jColor);
                    end
                end
                
            end %if obj.IsConstructed
            
        end %function
        

        % This method may be overridden for custom behavior
        function onValueChanged(obj,~)
            % Handle updates to value changes - subclass may override
            
            obj.redraw();
            
        end %function
        
        
        function value = getValue(obj)
            % Get the text from Java control - subclass may override
            
            value = char(obj.JEditor.getText());
            if ~isempty(value)
                value = value(:)';
            end
            
        end %function
        
        
        function setValue(obj,value)
            % Set the text to Java control - subclass may override
            
            validateattributes(value,{'char'},{})
            javaMethodEDT('setText',obj.JEditor,value);
            
        end %function
        
        
        function onKeyReleased(obj,jEvent)
            
            % Call superclass method
            obj.onKeyReleased@uiw.abstract.JavaControl(jEvent);
            
            % Call ValueChangingFcn
            pendingValue = obj.interpretStringAsValue( obj.getValue() );
            obj.onValueChanging(pendingValue);
            
        end %function
        
        
        function onTextEdited(obj,~,~)
            % Triggered on Java text edited - subclass may override
            
            % Ensure the construction is complete
            if isvalid(obj) && obj.IsConstructed && obj.CallbacksEnabled
                
                str = obj.getValue();
                value = obj.interpretStringAsValue(str);
                
                % Validate
                ok = checkValue(obj,value);
                if ok
                    % Trigger callback if value changed
                    if ~isequal(obj.Value, value)
                        evt = struct('Source', obj, ...
                            'Interaction', 'Edit', ...
                            'OldValue', obj.Value, ...
                            'NewValue', value,...
                            'NewString', str);
                        obj.Value = obj.interpretValueAsString(value);
                        obj.callCallback(evt);
                    end
                else
                    % Value was invalid, so revert
                    obj.CallbacksEnabled = false;
                    str = obj.interpretValueAsString(obj.Value);
                    obj.setValue(str);
                    obj.CallbacksEnabled = true;
                end
                
            end %if isvalid(obj) && obj.IsConstructed && obj.CallbacksEnabled
            
        end %function
        
    end % Protected methods

    
    %% Display Customization
    methods (Access=protected)
        
        function propGroup = getPropertyGroups(obj)
            
            widgetProps = properties('uiw.abstract.JavaEditableText');
            thisProps = setdiff(properties(obj), widgetProps);
            propGroup = [
                obj.getWidgetPropertyGroup()
                obj.getLabelPropertyGroup()
                obj.getEditableTextPropertyGroup()
                matlab.mixin.util.PropertyGroup(thisProps,'This Widget''s Properties:')
                ];
            
        end %function
      
    end %methods    
        
        
end % classdef