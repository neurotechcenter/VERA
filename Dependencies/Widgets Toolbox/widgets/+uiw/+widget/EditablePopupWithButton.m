classdef EditablePopupWithButton < uiw.widget.EditablePopup
    % EditablePopupWithButton - A popup control with editable text and action button
    %
    % This provides an editable popup along with a pushbutton that may be
    % customized. It also has a label which may optionally be used. The
    % label will be shown once any Label* property has been set.
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
        ButtonVisible % Toggle the button visibility [(true)|false]
    end
    
    properties (SetAccess=protected)
        hButton = [] % Button control
    end
    
    
    %% Constructor
    methods
        function obj = EditablePopupWithButton(varargin)
            % Construct the control
            
            % Call superclass constructors
            obj = obj@uiw.widget.EditablePopup();
            
            % Create the controls
            obj.hButton = uicontrol(...
                'Parent',obj.hBasePanel,...
                'Style','pushbutton',...
                'String','...',...
                'Units','pixels',...
                'Callback', @(h,e)obj.onButtonClick() );
            
            % Set properties from P-V pairs
            obj.assignPVPairs(varargin{:});
            
            % Do the following only if the object is not a subclass
            if strcmp(class(obj), 'uiw.widget.EditablePopupWithButton') %#ok<STISA>
                
                % Assign the construction flag
                obj.IsConstructed = true;
                
                % Redraw the widget
                obj.onResized();
                obj.onEnableChanged();
                obj.onStyleChanged();
                obj.redraw();
                
            end %if strcmp(class(obj),...
            
        end % constructor
    end %methods
    
    
    %% Protected Methods
    methods (Access=protected)
        
        function onResized(obj)
            % Handle changes to widget size
            
            % Ensure the construction is complete
            if obj.IsConstructed && ~isempty(obj.hButton)
                
                % Get widget dimensions
                [w,h] = obj.getInnerPixelSize;
                %pad = obj.Padding;
                spc = obj.Spacing;
                
                if obj.ButtonVisible
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
                    
                else
                    % Show text only
                    txtPos = [1 1 w h];
                    set(obj.hButton,'Visible','off');
                    
                end %if strcmp(obj.ButtonVisible,'on')
                
                % Calculations for a normal uicontrol popup:
                % FontSize =  10: Height = 25
                % FontSize =  20: Height = 42
                % FontSize =  50: Height = 92
                % FontSize = 100: Height = 175
                % Buffer is 8-9, so h = FontSize*1.6666 + 8
                
                % Calculate popup height based on font size
                if strcmp(obj.FontUnits,'points')
                    hW = round(obj.FontSize*1.666666) + 8;
                    txtPos([2 4]) = [h-hW+1 hW];
                end
                
                % Set popup position
                set(obj.HGJContainer,'Position',txtPos);
                
            end %if obj.IsConstructed
            
        end %function onResized(obj)
        
        
        function onButtonClick(obj)
            % Triggered on button press
            
            % Call callback
            evt = struct( 'Source', obj, ...
                'Interaction', 'ButtonClicked');
            obj.callCallback(evt);
            
        end % onButtonClick
        
    end %methods
    
    
    
    %% Get/Set methods
    methods
        
        % ButtonVisible
        function value = get.ButtonVisible(obj)
            value = strcmp(obj.hButton.Visible,'on');
        end
        function set.ButtonVisible(obj,value)
            obj.hButton.Visible = uiw.utility.tf2onoff(value);
            obj.onResized();
        end
        
    end %Get/Set methods
    
    
end % classdef
