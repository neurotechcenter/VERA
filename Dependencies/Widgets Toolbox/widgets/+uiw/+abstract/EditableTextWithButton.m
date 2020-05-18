classdef (Abstract) EditableTextWithButton < uiw.abstract.EditableTextControl
    % EditableTextWithButton - Base class for an editable field with a button
    % 
    % This is an abstract base class and cannot be instantiated. It
    % provides an 'edit' style uicontrol with a pushbutton that may be
    % customized. It also has a label which may optionally be used. The
    % label will be shown once any Label* property has been set.
        
%   Copyright 2008-2019 The MathWorks Inc.
    %
    % Auth/Revision:
    %   MathWorks Consulting
    %   $Author: rjackey $
    %   $Revision: 324 $
    %   $Date: 2019-04-23 08:05:17 -0400 (Tue, 23 Apr 2019) $
    % ---------------------------------------------------------------------
    
    %% Properties
    properties (AbortSet, Dependent)
        TextVisible (1,1) logical % TextVisible - Whether to show or hide the edit part [(true)|false]
        ButtonVisible (1,1) logical % ButtonVisible - Whether to show or hide the button part [(true)|false]
    end
    
    properties (GetAccess=protected, SetAccess=protected)
        hButton matlab.ui.control.UIControl % The button control
    end
    

    %% Abstract methods
    methods(Abstract, Access=protected)
        onButtonClick(obj) % Triggered on interaction with the button
    end % abstract methods
    
    
    %% Constructor
    methods
        function obj = EditableTextWithButton(varargin)
            % Construct the control
            
            % Call superclass constructors
            obj@uiw.abstract.EditableTextControl();
            
            % Switch the edit box to pixels
            obj.hEditBox.Units = 'pixels';
            
            % Create the button
            obj.hButton = uicontrol(...
                'Parent',obj.hBasePanel,...
                'Style','pushbutton',...
                'Units','pixels',...
                'Callback', @(h,e)obj.onButtonClick() );
            
            % Populate public properties from P-V input pairs
            obj.assignPVPairs(varargin{:});
            
            % Do the following only if the object is not a subclass
            if strcmp(class(obj), 'uiw.widget.EditableTextWithButton') %#ok<STISA>
                
                % Assign the construction flag
                obj.IsConstructed = true;
                
                % Redraw the widget
                obj.onResized();
                obj.onEnableChanged();
                obj.redraw();
                obj.onStyleChanged();
                
            end %if strcmp(class(obj),...
            
        end % constructor
    end %methods
    
    
    %% Protected Methods
    methods (Access=protected)
        
        function onResized(obj)
            % Triggered on widget resized
            
            % Ensure the construction is complete
            if obj.IsConstructed
                
                % Get widget dimensions
                [w,h] = obj.getInnerPixelSize;
                spc = obj.Spacing;
                
                if obj.ButtonVisible && obj.TextVisible
                    
                    butWidth = h;
                    txtWidth = w-butWidth-spc;
                    
                    % Check space is big enough
                    if w<(2*butWidth)+spc
                        butWidth = ceil(max(1,w/3-spc));
                        txtWidth = ceil(max(1,w-butWidth-spc));
                    end
                    
                    % Calculate sizes
                    butPos = [1+w-butWidth 1 butWidth h];
                    txtPos = [1 1 txtWidth h];
                    
                    % Update sizes and visibilities
                    set(obj.hButton,'Position',butPos,'Visible','on');
                    set(obj.hEditBox,'Position',txtPos,'Visible','on');
                    
                elseif obj.ButtonVisible && ~obj.TextVisible
                    
                    % Show button only
                    butPos = [1 1 w h];
                    set(obj.hButton,'Position',butPos,'Visible','on');
                    set(obj.hEditBox,'Visible','off');
                    
                elseif ~obj.ButtonVisible && obj.TextVisible
                    
                    % Show text only
                    txtPos = [1 1 w h];
                    set(obj.hButton,'Visible','off');
                    set(obj.hEditBox,'Position',txtPos,'Visible','on');
                    
                else
                    
                    % Hide both
                    set(obj.hButton,'Visible','off');
                    set(obj.hEditBox,'Visible','off');
                    
                end %if obj.ButtonVisible && obj.TextVisible
                
            end %if obj.IsConstructed
        end %function onResized(obj)
        
    end %methods

    
    
    %% Get/Set methods
    methods
        
        % ButtonVisible
        function value = get.ButtonVisible(obj)
            value = strcmp(obj.hButton.Visible,'on');
        end
        function set.ButtonVisible(obj,value)
            obj.hButton.Visible = uiw.utility.tf2onoff(value);
            obj.onContainerResized();
        end
        
        % TextVisible
        function value = get.TextVisible(obj)
            value = strcmp(obj.hEditBox.Visible,'on');
        end
        function set.TextVisible(obj,value)
            obj.hEditBox.Visible = uiw.utility.tf2onoff(value);
            obj.onContainerResized();
        end
        
    end %Get/Set methods
    
    
end % classdef