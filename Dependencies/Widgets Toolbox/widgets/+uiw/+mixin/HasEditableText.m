classdef HasEditableText < handle & matlab.mixin.CustomDisplay...
        & uiw.mixin.HasCallback
    % HasEditableText - Mixin for editable text field capabilities
    %
    % This mixin class provides properties and methods useful for handling
    % editable text fields and a corresponding value. It provides methods
    % for validating entries and converting between textual and data
    % representations. Additionally, this class implements properties that
    % are useful if a widget wants to set background/foreground to a
    % different color when the value is not valid. A subclass may override
    % onStyleChanged to customize how the widget responds to invalid
    % values.
    
%   Copyright 2017-2019 The MathWorks Inc.
    %
    % Auth/Revision:
    %   MathWorks Consulting
    %   $Author: rjackey $
    %   $Revision: 324 $  $Date: 2019-04-23 08:05:17 -0400 (Tue, 23 Apr 2019) $
    % ---------------------------------------------------------------------
    
    %% Properties
    properties (AbortSet)
        TextEditable char {mustBeMember(TextEditable,{'on','off'})} = 'on' % Can the text be manually edited? [(on)|off]
        TextBackgroundColor (1,3) double {mustBeFinite,mustBeGreaterThanOrEqual(TextBackgroundColor,0),mustBeLessThanOrEqual(TextBackgroundColor,1)} = [1 1 1] % Color for text background
        TextForegroundColor (1,3) double {mustBeFinite,mustBeGreaterThanOrEqual(TextForegroundColor,0),mustBeLessThanOrEqual(TextForegroundColor,1)} = [0 0 0] % Color for text
        TextInvalidBackgroundColor (1,3) double {mustBeFinite,mustBeGreaterThanOrEqual(TextInvalidBackgroundColor,0),mustBeLessThanOrEqual(TextInvalidBackgroundColor,1)} = [1 0.8 0.8] % Color for text background when value is invalid (If empty, no change)
        TextInvalidForegroundColor (1,3) double {mustBeFinite,mustBeGreaterThanOrEqual(TextInvalidForegroundColor,0),mustBeLessThanOrEqual(TextInvalidForegroundColor,1)} = [1 1 1]% Color for text when value is invalid (If empty, no change)
        TextIsValid (1,1) logical = true % Flag whether value is valid [(true)|false]
        TextHorizontalAlignment char {mustBeMember(TextHorizontalAlignment,{'left','center','right'})} = 'left' % Alignment of the text (['left'],'center','right')
        Value = [] % Current value of the control (any type: char, double, etc.)
    end
    
    properties (AbortSet, Access=protected)
        hTextFields = gobjects(0) % Array of text graphics objects that need their styles set upon changes
    end
    
    
    %% Protected Methods
    methods (Access=protected)
        
        function onEnableChanged(obj,~)
            % Handle updates to Enable state - subclass may override
            
            % Ensure the construction is complete
            if ~isempty(obj.hTextFields)
                
                % Handle 'inactive' state too
                if strcmpi(obj.Enable,'on') && strcmpi(obj.TextEditable, 'off')
                    set(obj.hTextFields,'Enable','off');
                elseif strcmpi(obj.Enable,'on') && strcmpi(obj.TextEditable, 'inactive')
                    set(obj.hTextFields,'Enable','inactive');
                else
                    set(obj.hTextFields,'Enable',obj.Enable);
                end
                
            end %if ~isempty(obj.hTextFields)
            
        end % function
        
        
        function onStyleChanged(obj,~)
            % Handle updates to style and value validity changes - subclass may override
            
            % Ensure the construction is complete
            if ~isempty(obj.hTextFields)
                
                thisFields = obj.hTextFields( isprop(obj.hTextFields,'HorizontalAlignment') );
                set(thisFields,'HorizontalAlignment',obj.TextHorizontalAlignment);
                if obj.TextIsValid
                    set(obj.hTextFields,...
                        'ForegroundColor',obj.TextForegroundColor,...
                        'BackgroundColor',obj.TextBackgroundColor);
                else
                    if ~isempty(obj.TextInvalidForegroundColor)
                        set(obj.hTextFields,'ForegroundColor',obj.TextInvalidForegroundColor)
                    end
                    if ~isempty(obj.TextInvalidBackgroundColor)
                        set(obj.hTextFields,'BackgroundColor',obj.TextInvalidBackgroundColor)
                    end
                end
                
            end %if ~isempty(obj.hTextFields)
            
        end %function
        

        function onValueChanged(~,~)
            % Handle updates to value changes - subclass may override
            
        end %function
        
        
        function StatusOk = checkValue(~,value)
            % Return true if the value is valid - subclass may override
            
            StatusOk = ischar(value) || ( isscalar(value) && isstring(value) );
            
        end %function checkValue

        
        function value = interpretStringAsValue(~,str) 
            % Convert entered text to stored data type - subclass may override
            
            value = str;
            
        end %function interpretStringAsValue


        function str = interpretValueAsString(~,value)
            % Convert stored data to displayed text - subclass may override
            
            str = char(value);
            
        end %function
        
    end %methods

    
    %% Display Customization
    methods (Access=protected)
        
        function propGroup = getEditableTextPropertyGroup(~)
            titleTxt = 'Common Editable Text Widget Properties:';
            thisProps = {
                'TextBackgroundColor'
                'TextEditable'
                'TextForegroundColor'
                'TextHorizontalAlignment'
                'TextInvalidBackgroundColor'
                'TextInvalidForegroundColor'
                'TextIsValid'
                'Callback'
                'Value'
                };
            propGroup = matlab.mixin.util.PropertyGroup(thisProps,titleTxt);
            
        end %function
      
    end %methods   
    
    
    
    %% Get/Set Methods
    methods
        
        % TextEditable
        function set.TextEditable(obj,value)
            value = validatestring(value,{'on','off'});
            obj.TextEditable = value;
            evt = struct('Property','TextEditable','Value',value);
            obj.onEnableChanged(evt);
        end
        
        % TextHorizontalAlignment
        function set.TextHorizontalAlignment(obj,value)
            value = validatestring(value,{'left','center','right'});
            evt = struct('Property','HorizontalAlignment',...
                'OldValue',obj.TextHorizontalAlignment,...
                'NewValue',value);
            obj.TextHorizontalAlignment = value;
            obj.onStyleChanged(evt);
        end
        
        % TextBackgroundColor
        function set.TextBackgroundColor(obj,value)
            value = uiw.utility.interpretColor(value);
            evt = struct('Property','TextBackgroundColor',...
                'OldValue',obj.TextBackgroundColor,...
                'NewValue',value);
            obj.TextBackgroundColor = value;
            obj.onStyleChanged(evt);
        end
        
        % TextForegroundColor
        function set.TextForegroundColor(obj,value)
            value = uiw.utility.interpretColor(value);
            evt = struct('Property','TextForegroundColor',...
                'OldValue',obj.TextForegroundColor,...
                'NewValue',value);
            obj.TextForegroundColor = value;
            obj.onStyleChanged(evt);
        end

        % TextInvalidBackgroundColor
        function set.TextInvalidBackgroundColor(obj,value)
            value = uiw.utility.interpretColor(value);
            evt = struct('Property','TextInvalidBackgroundColor',...
                'OldValue',obj.TextInvalidBackgroundColor,...
                'NewValue',value);
            obj.TextInvalidBackgroundColor = value;
            obj.onStyleChanged(evt);
        end
        
        % TextInvalidForegroundColor
        function set.TextInvalidForegroundColor(obj,value)
            value = uiw.utility.interpretColor(value);
            evt = struct('Property','TextInvalidForegroundColor',...
                'OldValue',obj.TextInvalidForegroundColor,...
                'NewValue',value);
            obj.TextInvalidForegroundColor = value;
            obj.onStyleChanged(evt);
        end
        
        % IsValid
        function set.TextIsValid(obj,value)
            validateattributes(value,{'logical'},{'scalar'});
            evt = struct('Property','TextIsValid',...
                'OldValue',obj.TextIsValid,...
                'NewValue',value);
            obj.TextIsValid = value;
            obj.onStyleChanged(evt);
        end
        
        % Value
        function set.Value(obj,value)
            if ischar(value) || ( isscalar(value) && isstring(value) )
                % Values entered into edit field by user will go here
                value = obj.interpretStringAsValue(value);
            end
            if checkValue(obj, value)
                str = obj.interpretValueAsString(value);
                evt = struct('Property','Value',...
                    'OldValue',obj.Value,...
                    'NewValue',value,...
                    'NewString',str);
                obj.Value = value;
                onValueChanged(obj,evt)
            end
        end
        
    end %methods
    
    
end % classdef