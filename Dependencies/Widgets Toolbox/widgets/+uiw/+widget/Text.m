classdef Text < uiw.abstract.WidgetContainer & uiw.mixin.HasEditableText
    % Text - A simple text display control
    %
    % Create a widget with non-editable text.
    %
    % Syntax:
    %           w = uiw.widget.Text('Property','Value',...)
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
    properties (GetAccess=protected, SetAccess=private)
        hText matlab.ui.control.UIControl % The text control
    end
    
    
    %% Constructor / Destructor
    methods
        
        function obj = Text(varargin)
            % Construct the widget
            
            % Call superclass constructors
            obj@uiw.abstract.WidgetContainer();
            
            obj.hText = uicontrol(...
                'Parent',obj.hBasePanel,...
                'Style','text',...
                'HorizontalAlignment','left',...
                'Units','normalized',...
                'Position',[0 0 1 1]);
            obj.TextForegroundColor = obj.hText.ForegroundColor;
            obj.TextBackgroundColor = obj.hText.BackgroundColor;
            
            obj.hTextFields = obj.hText;
            
            % Populate public properties from P-V input pairs
            obj.assignPVPairs(varargin{:});
            
            % Assign the construction flag
            obj.IsConstructed = true;
            
            % Redraw the widget
            obj.onResized();
            obj.onEnableChanged();
            obj.redraw();
            obj.onStyleChanged();
            
        end % constructor
        
    end %methods - constructor/destructor
    
    
    
    %% Protected Methods
    methods (Access=protected)
        
        function onEnableChanged(obj,~)
            % Handle updates to Enable state
            if obj.IsConstructed
                
                % Call superclass methods
                onEnableChanged@uiw.abstract.WidgetContainer(obj);
                onEnableChanged@uiw.mixin.HasEditableText(obj);
                
            end %if obj.IsConstructed
        end % function
        
        
        function onStyleChanged(obj,~)
            % Handle updates to style and value validity changes
            if obj.IsConstructed
                
                % Call superclass methods
                onStyleChanged@uiw.abstract.WidgetContainer(obj);
                onStyleChanged@uiw.mixin.HasEditableText(obj);
                
            end %if obj.IsConstructed
        end % function
        
        
        function onValueChanged(obj,evt)
            % Handle updates to value changes
            
            str = evt.NewString;
            if ~isequal(str, obj.hText.String)
                obj.hText.String = str;
                obj.redraw();
            end
            
        end % function
        
    end %methods
    
end % classdef
