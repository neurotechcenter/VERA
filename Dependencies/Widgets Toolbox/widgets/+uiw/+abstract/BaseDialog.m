classdef (Abstract) BaseDialog <  uiw.abstract.BaseFigure & uiw.abstract.BasePanel & ...
        uiw.mixin.HasCallback & dynamicprops
    % BaseDialog - Base class for building dialog windows
    %
    % This class provides the basic properties needed for a dialog window
    % that will contain interactive graphics objects. This defaults to a
    % modal dialog. If a non-modal dialog is preferred, set WindowStyle to
    % 'normal' on construction.
    %
    % For blocking dialogs, if the BaseDialog subclass does not already assign
    % the results to obj.Output in other callbacks, then the subclass
    % should implement onButtonPressed method. The subclass implementation
    % of onButtonPressed should first assign results to obj.Output, and at
    % the end, call the superclass method BaseDialog\onButtonPressed to handle
    % the button click and callbacks.
    %
    % Example subclass implementation:
    %
    %   function onButtonPressed(obj,action)
    %       obj.Output = <assign appropriate data here>;
    %       obj.onButtonPressed@uiw.abstract.BaseDialog(action);
    %   end %function
    %
    
%   Copyright 2017-2019 The MathWorks Inc.
    %
    % Auth/Revision:
    %   MathWorks Consulting
    %   $Author: rjackey $
    %   $Revision: 324 $  $Date: 2019-04-23 08:05:17 -0400 (Tue, 23 Apr 2019) $
    % ---------------------------------------------------------------------
    
    
    %% Properties
    properties (AbortSet, SetAccess=protected)
        Output %Results / Output Data from the dialog
        IsWaitingForOutput = false %True if dialog is waiting for output. Pressing a button (ok, cancel, or close) will toggle this false and cause the waitForOutput() method to complete.
    end
    
    properties (AbortSet, Dependent)
        DialogSize %Initial size of dialog [width height]
        ShowOk %Whether to have OK button [(true)|false]
        ShowCancel %Whether to have Cancel button [(true)|false]
        ShowApply %Whether to have Apply button [true|(false)]
        Resize %Whether the dialog is resizable ['on'|('off')]
    end
    
    properties (Access=private)
        hMainButtons matlab.ui.control.UIControl %
        LastAction = '' %
    end
    
    
    %% Constructor / destructor
    methods
        
        function obj = BaseDialog(varargin)
            
            % Get mouse position
            g = groot;
            CPos = g.PointerLocation;
            
            % Pull out DialogSize input now for creating the figure
            [remainArgs,visibleIn] = uiw.mixin.AssignPVPairs.removeArg('Visible', varargin{:});
            [dialogSizeArgs,remainArgs] = uiw.mixin.AssignPVPairs.splitArgs('DialogSize', remainArgs{:});
            if numel(dialogSizeArgs)>=2 && numel(dialogSizeArgs{end})==2
                dialogSizeIn = dialogSizeArgs{end};
            else
                dialogSizeIn = [600 300];
            end
            
            % Position the figure near the mouse location
            StartPos = CPos - dialogSizeIn/2;
            
            % Create the label and base panel for the widget
            obj@uiw.abstract.BaseFigure(...
                'Units','pixels',...
                'Position',[StartPos dialogSizeIn],...
                'WindowStyle','modal',...
                'Resize','off',...
                'Visible','off');
            obj@uiw.abstract.BasePanel();
            
            % Set the panel parent
            set(obj.hBasePanel,...
                'Parent',obj.Figure,...
                'Units','pixels');
            
            % Ensure it is fully on screen
            obj.moveOnScreen();
            
            % Now, set the visibility
            if isempty(visibleIn)
                obj.Visible = 'on';
            else
                obj.Visible = visibleIn;
            end
            
            % Now, give a moment for the dialog figure to render
            drawnow;
            
            % Create the main buttons
            obj.hMainButtons = [
                matlab.ui.control.UIControl(...
                'String','Apply',...
                'Visible','off',...
                'Callback',@(h,e)onButtonPressed(obj,'apply'));
                matlab.ui.control.UIControl(...
                'String','OK',...
                'Visible','on',...
                'Callback',@(h,e)onButtonPressed(obj,'ok'));
                matlab.ui.control.UIControl(...
                'String','Cancel',...
                'Visible','on',...
                'Callback',@(h,e)onButtonPressed(obj,'cancel'));
                ];
            set(obj.hMainButtons,...
                'Parent',obj.Figure,...
                'Style','pushbutton',...
                'Units','pixels',...
                'FontSize', 10)
            
            % Assign PV pairs to properties
            obj.assignPVPairs(remainArgs{:});
            
            % If only showing the Cancel button, it should be named
            % Close instead
            if obj.ShowOk && ~obj.ShowCancel && ~obj.ShowApply
                obj.hMainButtons(2).String = 'Close';
            end
            
            % Adjust button sizing
            obj.onContainerResized();
            
        end %function
        
    end %constructor
    
    
    
    %% Public Methods
    methods
        
        function [Output, LastAction] = waitForOutput(obj,flagDelete)
            % Puts MATLAB in a wait state until the dialog disappears by the user clicking Ok, Cancel, or Close
            
            % Wait for action
            obj.IsWaitingForOutput = true;
            waitfor(obj,'IsWaitingForOutput',false)
            
            % Produce output
            Output = obj.Output;
            LastAction = obj.LastAction;
            
            % Close the dialog
            if nargin<2 || flagDelete
                delete(obj)
            end
        end
        
        
        function onExit(obj,~,~)
            % Triggered on figure closed
            
            if obj.IsWaitingForOutput
                obj.onButtonPressed('cancel');
            else
                delete(obj);
            end
            
        end
        
    end %methods
    
    
    %% Protected Methods
    methods (Access=protected)
        
        % This method may be overridden for custom behavior
        function redraw(obj)
            % Handle state changes that may need UI redraw - subclass may override
            
            % Ensure the construction is complete
            if obj.IsConstructed
                
            end %if obj.IsConstructed
            
        end %function
        
        
        % This method may be overridden for custom behavior
        function onResized(obj)
            % Handle changes to dialog size - subclass may override
            
            % Ensure the construction is complete
            if obj.IsConstructed
                
            end %if obj.IsConstructed
            
        end %function
        
        
        function onEnableChanged(obj,~)
            % Handle updates to Enable state - subclass may override
            
            % Ensure the construction is complete
            if obj.IsConstructed
                
                % Find all uicontrols depth 1 that have an Enable field
                hTopLevel = findall(obj.hBasePanel,'-property','Enable','-depth',1);
                
                % Call superclass method implementation to make changes
                obj.onEnableChanged@uiw.mixin.HasContainer(hTopLevel)
                
            end %if obj.IsConstructed
            
        end %function
        
        
        % This method may be overridden for custom behavior
        
        function onStyleChanged(obj,~)
            % Handle updates to style changes - subclass may override
            
            % Ensure the construction is complete
            if obj.IsConstructed
                
                % Get any other objects at the top level of the widget
                hTopLevel = findall(obj.hBasePanel,'-depth',1);
                hTopLevel = vertcat(hTopLevel, obj.hMainButtons);
                
                % Call superclass method implementation to make changes
                obj.onStyleChanged@uiw.mixin.HasContainer(hTopLevel)
                
            end %if obj.IsConstructed
            
        end %function
        
        
        function onButtonPressed(obj,action)
            % Handle button press events - Subclass must override this method
            %
            % For blocking dialogs, if the BaseDialog subclass does not already
            % assign the results to obj.Output in other callbacks, then the
            % subclass should implement onButtonPressed method. The
            % subclass implementation of onButtonPressed should first
            % assign results to obj.Output, and at the end, call the
            % superclass method BaseDialog\onButtonPressed to handle the button
            % click and callbacks.
            %
            % Example subclass implementation:
            %
            %   function onButtonPressed(obj,action)
            %       obj.Output = <assign appropriate data here>;
            %       obj.onButtonPressed@uiw.abstract.BaseDialog(action);
            %   end %function
            %
            
            % Prep event data
            obj.LastAction = action;
            evt = struct('Source', obj, ...
                'Action',action, ...
                'Output',obj.Output);
            
            % What action to take?
            if strcmpi(action,'apply')
                % Apply button pressed
                
                % Call the callback, if one exists
                obj.callCallback(evt);
                
            elseif obj.IsWaitingForOutput
                % Other button pressed, and waiting for output
                
                % Toggle status, allowing waitForOutput() to complete
                obj.IsWaitingForOutput = false;
                
            else
                % Other button pressed, but not waiting for output
                
                % Call the callback, if one exists
                obj.callCallback(evt);
                
                % Delete the dialog
                delete(obj)
                
            end %if strcmpi(action,'apply')
            
        end %function
        
    end %methods
    
    
    %% Sealed Protected methods
    methods (Sealed, Access=protected)
        
        function [w,h] = getInnerPixelSize(obj)
            % Calculate inner area pixel size
            % [w,h] = getInnerPixelSize(obj)
            
            % Calculate inner area pixel size
            OuterPixelPos = getpixelposition(obj.hBasePanel);
            InnerPos = obj.hBasePanel.InnerPosition;
            OuterPos = obj.hBasePanel.OuterPosition;
            sz = floor(OuterPixelPos(3:4) .* InnerPos(3:4) ./ OuterPos(3:4));
            sz = max(sz, [10 10]);
            h = sz(2);
            w = sz(1);
        end % getInnerPixelSize
        
        
        function onContainerResized(obj)
            % Triggered on resize of the dialog's container
            
            % Ensure the construction is complete
            if ~isempty(obj.hMainButtons)
                
                % Get positioning of the figure
                [wF,hF] = obj.getPixelSize();
                pad = obj.Padding;
                spc = obj.Spacing;
                
                % What buttons are visible?
                ButtonVis = {obj.hMainButtons.Visible};
                IsVisible = strcmp(ButtonVis,'on');
                NumVis = sum(IsVisible);
                
                % Position buttons
                butMaxW = 80;
                butMinW = 25;
                butScaledW = floor( (wF-(NumVis-1)*spc-2*pad)/NumVis  );
                butW = max( min(butMaxW, butScaledW), butMinW );
                butH = 25;
                y0b = pad+1;
                xMult(3) = 0;
                xMult(IsVisible) = NumVis:-1:1;
                x0b = wF - xMult*(butW+spc) + spc - pad;
                set(obj.hMainButtons(1),'Position',[x0b(1) y0b butW butH])
                set(obj.hMainButtons(2),'Position',[x0b(2) y0b butW butH])
                set(obj.hMainButtons(3),'Position',[x0b(3) y0b butW butH])
                
                % Position hBasePanel for dialog contents
                if any(IsVisible)
                    y0c = y0b + butH + spc;
                    hL = max(hF-y0c, 10);
                    set(obj.hBasePanel,'Position',[1 y0c wF hL]);
                else
                    set(obj.hBasePanel,'Position',[1 1 wF hF]);
                end
                
            end %if ~isempty(obj.hMainButtons)
            
            obj.onResized();
            
        end % function
        
        
        function addWidgetProps(obj,wObj)
            %For dialog that wraps a widget, add the widget's properties to
            %the dialog as dynamic properties, ignoring properties of
            %WidgetContainer
            
            % Get a list of public properties of the widget that are not
            % part of the WidgetContainer superclass or the dialog
            widgetContainerProps = properties('uiw.abstract.WidgetContainer');
            allWidgetProps = properties(wObj);
            dialogMC = metaclass(obj);
            dialogProps = {dialogMC.PropertyList.Name}';
            propNamesToAdd = setdiff(allWidgetProps, ...
                [widgetContainerProps; dialogProps], 'stable');
            
            % Get the meta property info for the properties to add
            widgetMC = metaclass(wObj);
            widgetMP = widgetMC.PropertyList;
            propsToAdd = widgetMP(contains({widgetMP.Name}, propNamesToAdd));
            
            for thisProp = propsToAdd'
                
                % Add the property
                mp = addprop(obj, thisProp.Name);
                
                % Add a set method
                if strcmp(thisProp.SetAccess,'public')
                    mp.SetMethod = @(xObj,value)set(wObj, thisProp.Name, value);
                else
                    mp.SetAccess = thisProp.SetAccess;
                end
                
                % Add a get method
                if strcmp(thisProp.GetAccess,'public')
                    mp.GetMethod = @(xObj)get(wObj, thisProp.Name);
                else
                    mp.GetAccess = thisProp.GetAccess;
                end
                
            end %for thisProp = propsToAdd'
            
        end %function
        
    end %methods
    
    
    
    %% Get/Set Methods
    methods
        
        % ShowApply
        function value = get.ShowApply(obj)
            value = strcmp(obj.hMainButtons(1).Visible,'on');
        end
        function set.ShowApply(obj,value)
            validateattributes(value,{'logical'},{'scalar'})
            obj.hMainButtons(1).Visible = uiw.utility.tf2onoff(value);
            obj.onContainerResized();
        end
        
        % ShowOk
        function value = get.ShowOk(obj)
            value = strcmp(obj.hMainButtons(2).Visible,'on');
        end
        function set.ShowOk(obj,value)
            validateattributes(value,{'logical'},{'scalar'})
            obj.hMainButtons(2).Visible = uiw.utility.tf2onoff(value);
            obj.onContainerResized();
        end
        
        % ShowCancel
        function value = get.ShowCancel(obj)
            value = strcmp(obj.hMainButtons(3).Visible,'on');
        end
        function set.ShowCancel(obj,value)
            validateattributes(value,{'logical'},{'scalar'})
            obj.hMainButtons(3).Visible = uiw.utility.tf2onoff(value);
            obj.onContainerResized();
        end
        
        % DialogSize
        function value = get.DialogSize(obj)
            value = obj.Figure.Position(3:4);
        end
        function set.DialogSize(obj,value)
            validateattributes(value,{'numeric'},...
                {'finite','positive','size',[1 2]})
            obj.Figure.Position(3:4) = value;
        end
        
        % Resize
        function value = get.Resize(obj)
            value = obj.Figure.Resize;
        end
        function set.Resize(obj,value)
            obj.Figure.Resize = value;
        end
        
    end %methods
    
    
end % classdef
