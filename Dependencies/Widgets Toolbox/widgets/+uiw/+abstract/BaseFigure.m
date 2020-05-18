classdef (Abstract) BaseFigure < uiw.mixin.HasContainer
    % BaseFigure - Base class for a traditional figure used for an app
    %
    % This class provides the basic properties and utilities needed for a
    % traditional MATLAB figure window, intended to bue used within
    % hand-coded apps. It is inherited by AppWindow and by BaseDialog classes.
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
        BackgroundColor %Background color of the figure
        DockControls %Toggles the figure dock controls [on|(off)]
        Position %Position on screen [left bottom width height]
        Units %Position units [inches|centimeters|normalized|points|pixels|characters]
        Tag %Tag for the figure
        Title %Name of the figure window
        UIContextMenu %Context menu for the figure
        Visible %Figure visibility [on|(off)]
        WindowStyle %Type of window [(normal)|docked|modal]
    end
    
    properties (SetAccess=immutable)
        Figure matlab.ui.Figure %The figure handle
    end
    
    properties (Access=private)
        DestroyedListener %Listener for figure being closed/destroyed
        SizeChangedListener %Listener for the figure being resized
    end
    
    
    
    %% Constructor / destructor
    methods
        
        function obj = BaseFigure(varargin)
            
            % Create the base inside figure
            obj.Figure = matlab.ui.Figure(...
                'Name', '', ...
                'MenuBar', 'none', ...
                'Toolbar', 'none', ...
                'WindowStyle','normal',...
                'DockControls','off', ...
                'NumberTitle', 'off', ...
                'IntegerHandle','off',...
                'HandleVisibility', 'callback', ...
                'Units','pixels',...
                'DeleteFcn',@(h,e)delete(obj),...
                'CloseRequestFcn',@(h,e)onExit(obj,h), ...
                'UserData',obj,... %Store object to prevent deletion
                varargin{:});
            
            % Attach listeners and callbacks
            obj.DestroyedListener = event.listener(obj.Figure,...
                'ObjectBeingDestroyed',@(h,e)onExit(obj,h));
            obj.SizeChangedListener = event.listener(obj.Figure,...
                'SizeChanged',@(h,e)onContainerResized(obj));
            
        end %function
        
        function delete(obj)
            % Is this object still valid?
            if ~isempty(obj.Figure) && isvalid(obj.Figure) &&...
                    ~strcmpi(obj.Figure,'on')
                delete(obj.Figure);
            end
        end %function
        
    end %constructor/destructor
    
    
    
    %% Public Methods
    methods
        
        function onExit(obj,h)
            % Triggered on figure closed - subclass may override
            if isvalid(obj)
                obj.delete();
            elseif nargin >= 2
                delete(h)
            end
        end %function
        
    end %methods
    
    
    
    %% Sealed Public methods
    methods (Sealed)
        
        function moveOnScreen(obj)
            % Ensure the figure is placed on screen
            
            if strcmp(obj.Figure.Units,'pixels')
                
                % Get the corners of each screen
                g = groot;
                screenPos = g.MonitorPositions;
                screenCornerA = screenPos(:,1:2);
                screenCornerB = screenPos(:,1:2) + screenPos(:,3:4) - 1;
                
                % In case menu/toolbar are turned on after this runs, we
                % may want a buffer
                titleBarHeight = 0;
                
                % Get the corners of the figure (bottom left and top right)
                figPos = obj.Figure.OuterPosition;
                figCornerA = figPos(1:2);
                figCornerB = figPos(1:2) + figPos(:,3:4) - 1;
                
                % Are the corners on any screen?
                aIsOnScreen = all( figCornerA >= screenCornerA & ...
                    figCornerA <= screenCornerB, 2 );
                bIsOnScreen = all( figCornerB >= screenCornerA & ...
                    figCornerB <= screenCornerB, 2);
                
                % Are corners on a screen?
                
                % Are both corners fully on any screen?
                if any(aIsOnScreen) && any(bIsOnScreen)
                    % Yes - do nothing
                    
                elseif any(bIsOnScreen)
                    % No - only upper right corner is on a screen
                    
                    % Calculate the adjustment needed, and make it
                    figAdjust = max(figCornerA, screenCornerA(bIsOnScreen,:)) ...
                        - figCornerA;
                    figPos(1:2) = figPos(1:2) + figAdjust;
                    
                    % Ensure the upper right corner still fits
                    figPos(3:4) = min(figPos(3:4), ...
                        screenCornerB(bIsOnScreen,:) - figPos(1:2) - [0 titleBarHeight] + 1);
                    
                    % Move the figure
                    obj.Figure.OuterPosition = figPos;
                    
                elseif any(aIsOnScreen)
                    % No - only lower left corner is on a screen
                    
                    % Calculate the adjustment needed, and make it
                    figAdjust = min(figCornerB, screenCornerB(aIsOnScreen,:)) ...
                        - figCornerB;
                    figPos(1:2) = max( screenCornerA(aIsOnScreen,:),...
                        figPos(1:2) + figAdjust );
                    
                    % Ensure the upper right corner still fits
                    figPos(3:4) = min(figPos(3:4), ...
                        screenCornerB(aIsOnScreen,:) - figPos(1:2) - [0 titleBarHeight] + 1);
                    
                    % Move the figure
                    obj.Figure.OuterPosition = figPos;
                    
                else
                    % No - Not on any screen
                    
                    % This is slower, but uncommon anyway
                    movegui(obj.Figure,'onscreen');
                    
                end %if any( all(aIsOnScreen,2) & all(bIsOnScreen,2) )
                
            else
                
                % This is slower, but uncommon anyway
                movegui(obj.Figure,'onscreen');
                
            end %if strcmp(obj.Figure.Units,'pixels')
            
        end %function
        
    end %methods
    
    
    
    %% Protected methods
    methods (Access=protected)
        
        function onContainerResized(~)
            % Triggered on figure resized - subclass may override
            
        end %function
        
        
        function onVisibleChanged(~)
            % Handle updates to Visible state - subclass may override
            
        end %function
        
        
        function onStyleChanged(~)
            % Handle updates to style changes - subclass may override
            
        end %function
        
        
        function [w,h] = getInnerPixelSize(obj)
            % Calculate the figure's inner pixel size [width, height]
            
            OuterPixelPos = getpixelposition(obj.Figure);
            InnerPos = obj.Figure.InnerPosition;
            OuterPos = obj.Figure.OuterPosition;
            sz = floor(OuterPixelPos(3:4) .* InnerPos(3:4) ./ OuterPos(3:4));
            sz = max(sz, [10 10]);
            h = sz(2);
            w = sz(1);
            
        end % getInnerPixelSize
        
    end %methods
    
    
    
    %% Sealed Protected methods
    methods (Sealed, Access=protected)
        
        function pos = getPixelPosition(obj,recursive)
            % Calculate the figure's pixel position
            
            if nargin<2
                recursive = false;
            end
            pos = getpixelposition(obj.Figure, recursive);
            pos = ceil(pos);
            
        end %function
        
        
        function [w,h] = getPixelSize(obj)
            % Calculate the figure's outer pixel size [width, height]
            
            pos = getPixelPosition(obj,false);
            w = pos(3);
            h = pos(4);
            
        end % function
        
    end %methods
    
    
    
    %% Display Customization
    methods (Access=protected)
        
        function propGroup = getPropertyGroups(obj)
            
            propGroup = obj.getFigurePropertyGroup();
            
        end %function
        
        function propGroup = getFigurePropertyGroup(~)
            
            titleTxt = ['Figure Properties: '...
                '(<a href = "matlab: helpPopup uiw.abstract.BaseFigure">'...
                'Figure Documentation</a>)'];
            thisProps = {
                'Figure'
                'BackgroundColor'
                'DockControls'
                'Position'
                'Units'
                'Tag'
                'Title'
                'UIContextMenu'
                'Visible'
                'WindowStyle'
                'Padding'
                'Spacing'
                };
            propGroup = matlab.mixin.util.PropertyGroup(thisProps,titleTxt);
            
        end %function
        
    end %methods
    
    
    
    %% Get/Set Methods
    methods
        
        function value = get.BackgroundColor(obj)
            value = obj.Figure.Color;
        end
        function set.BackgroundColor(obj,value)
            obj.Figure.Color = value;
            obj.onStyleChanged();
        end
        
        function value = get.DockControls(obj)
            value = obj.Figure.DockControls;
        end
        function set.DockControls(obj,value)
            obj.Figure.DockControls = value;
        end
        
        function value = get.Position(obj)
            value = obj.Figure.OuterPosition;
        end
        function set.Position(obj,value)
            obj.Figure.OuterPosition = value;
        end
        
        function value = get.Tag(obj)
            value = obj.Figure.Tag;
        end
        function set.Tag(obj, value)
            obj.Figure.Tag = value;
        end
        
        function value = get.Title(obj)
            value = obj.Figure.Name;
        end
        function set.Title(obj,value)
            obj.Figure.Name = value;
        end
        
        function value = get.UIContextMenu(obj)
            value = obj.Figure.UIContextMenu;
        end
        function set.UIContextMenu(obj,value)
            obj.Figure.UIContextMenu = value;
        end
        
        function value = get.Units(obj)
            value = obj.Figure.Units;
        end
        function set.Units(obj,value)
            obj.Figure.Units = value;
        end
        
        function value = get.Visible(obj)
            value = obj.Figure.Visible;
        end
        function set.Visible(obj,value)
            obj.Figure.Visible = value;
            obj.onVisibleChanged();
        end
        
        function value = get.WindowStyle(obj)
            value = obj.Figure.WindowStyle;
        end
        function set.WindowStyle(obj,value)
            obj.Figure.WindowStyle = value;
        end
        
    end %methods
    
    
end % classdef
