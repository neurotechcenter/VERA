classdef (Abstract) BaseLabel < handle
    % BaseLabel - Base class for a Widget Label
    %
    % This class provides a label and related utilities for widgets,
    % dialogs, etc. The widget must implement onContainerResized to set the
    % positioning of the label.
    %
    
%   Copyright 2017-2019 The MathWorks Inc.
    %
    % Auth/Revision:
    %   MathWorks Consulting
    %   $Author: rjackey $
    %   $Revision: 324 $  $Date: 2019-04-23 08:05:17 -0400 (Tue, 23 Apr 2019) $
    % ---------------------------------------------------------------------
    
    
    %% Properties
    properties (AbortSet, Dependent)
        Label char %The label (char). If set, LabelVisible changes to 'on'.
        LabelFontAngle char %Font angle of the label [(normal)|italic]
        LabelFontName char %Font name of the label
        LabelFontSize double %Font size of the label
        LabelFontUnits char %Font units of the label [inches|centimeters|characters|normalized|(points)|pixels]
        LabelFontWeight char %Font weight of the label [(normal)|bold]
        LabelForegroundColor %Font color of the label
        LabelHorizontalAlignment char %Alignment of the label
        LabelVisible char %Toggles the label visibility [on|(off)]
        LabelTooltipString char %Tooltip of the label
    end %properties
    
    properties (AbortSet)
        %Placement of the label [(left)|right|top|bottom]
        LabelLocation char {mustBeMember(LabelLocation,{'left','right','top','bottom'})} = 'left' 
        
        %Pixel height of label (applies to top|bottom location)
        LabelHeight (1,1) double {mustBePositive} = 20 
        
        %Pixel width of label (applies to left|right location)
        LabelWidth (1,1) double {mustBePositive} = 75 
        
         %Pixel spacing between label and widget
        LabelSpacing (1,1) double {mustBeNonnegative} = 4
    end %properties

    properties (Access=protected)
       LabelVisible_ (1,1) logical = false; %Cache of LabelVisible
    end
    
    properties (SetAccess=immutable, GetAccess=protected)
        hLabel %The label control
    end %properties
    
    
    
    %% Abstract Methods
    methods (Abstract, Access=protected) %Must be defined in subclass
        onContainerResized(obj) %Handle resize of container - subclass must implement
    end %methods
    
    
    %% Constructor
    methods
        function obj = BaseLabel()
            % Construct the label
            
            % Create a label
            obj.hLabel = matlab.ui.control.UIControl(...
                'HandleVisibility','off',...
                'Style', 'text', ...
                'HorizontalAlignment','left',...
                'Units','pixels',...
                'TooltipString','',...
                'Visible','off',...
                'FontSize',10);
            
            obj.onContainerResized();
            
        end %function
    end %constructor
    
    
    %% Private methods
    methods (Access=private)
        
        function makeLabelVisible(obj)
            % Turns on the label visibility
            
            obj.LabelVisible_ = true;
            uiw.utility.setPropsIfDifferent(obj.hLabel,'Visible','on')
            obj.onContainerResized();
            
        end %function
        
    end %methods
    
    
    
    %% Get/Set methods
    methods
        
        function set.LabelSpacing(obj,value)
            obj.LabelSpacing = value;
            obj.makeLabelVisible();
        end
        
        function value = get.Label(obj)
            value = obj.hLabel.String;
        end
        function set.Label(obj, value)
            obj.hLabel.String = value;
            obj.makeLabelVisible();
        end
        
        function set.LabelLocation(obj, value)
            obj.LabelLocation = value;
            obj.makeLabelVisible();
        end
        
        function set.LabelWidth(obj, value)
            obj.LabelWidth = value;
            obj.makeLabelVisible();
        end
        
        function set.LabelHeight(obj, value)
            obj.LabelHeight = value;
            obj.makeLabelVisible();
        end
        
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % Pass-through properties that modify the label uicontrol
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        function value = get.LabelVisible(obj)
            value = obj.hLabel.Visible;
        end
        function set.LabelVisible(obj,value)
            obj.hLabel.Visible = value;
            obj.makeLabelVisible();
        end
        
        function value = get.LabelForegroundColor(obj)
            value = obj.hLabel.ForegroundColor;
        end
        function set.LabelForegroundColor(obj,value)
            obj.hLabel.ForegroundColor = value;
        end
        
        function value = get.LabelFontAngle(obj)
            value = obj.hLabel.FontAngle;
        end
        function set.LabelFontAngle(obj,value)
            obj.hLabel.FontAngle = value;
        end
        
        function value = get.LabelFontName(obj)
            value = obj.hLabel.FontName;
        end
        function set.LabelFontName(obj,value)
            obj.hLabel.FontName = value;
        end
        
        function value = get.LabelFontSize(obj)
            value = obj.hLabel.FontSize;
        end
        function set.LabelFontSize(obj,value)
            obj.hLabel.FontSize = value;
        end
        
        function value = get.LabelFontUnits(obj)
            value = obj.hLabel.FontUnits;
        end
        function set.LabelFontUnits(obj,value)
            obj.hLabel.FontUnits = value;
        end
        
        function value = get.LabelFontWeight(obj)
            value = obj.hLabel.FontWeight;
        end
        function set.LabelFontWeight(obj,value)
            obj.hLabel.FontWeight = value;
        end
        
        function value = get.LabelHorizontalAlignment(obj)
            value = obj.hLabel.HorizontalAlignment;
        end
        function set.LabelHorizontalAlignment(obj,value)
            obj.hLabel.HorizontalAlignment = value;
        end
        
        function value = get.LabelTooltipString(obj)
            value = obj.hLabel.TooltipString;
        end
        function set.LabelTooltipString(obj,value)
            obj.hLabel.TooltipString = value;
        end
        
    end % Get/Set methods
    
    
end % classdef