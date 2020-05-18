classdef (Abstract) AppWindow < uiw.abstract.BaseFigure & uiw.mixin.HasPreferences
    % AppWindow - Base class for an app's traditional figure window
    %
    % This class provides the basic properties needed for a hand-coded app
    % that exists within a traditional MATLAB figure window. For an app
    % that also utilizes sessions to save and load state to a MAT-file,
    % inherit AppWithSessions instead.
    %
    
    %   Copyright 2008-2019 The MathWorks, Inc.
    %
    % Auth/Revision:
    %   MathWorks Consulting
    %   $Author: rjackey $
    %   $Revision: 309 $
    %   $Date: 2019-01-31 11:54:46 -0500 (Thu, 31 Jan 2019) $
    % ---------------------------------------------------------------------
    
    
    %% Abstract Properties (subclass must implement these)
    properties(Abstract, Constant, Access=protected)
        AppName char %Example: 'AppWindow'
    end
    
    
    %% Properties
    properties (SetAccess=protected)
        Menu struct = struct() %structure for subclasses to place menus
    end
    
    
    
    %% Constructor and Destructor
    methods
        
        function obj = AppWindow(varargin)
            % Construct the app
            
            % Call superclass constructors
            obj@uiw.abstract.BaseFigure('Visible','off');
            
            % Check for preference input and assign it first, in case
            % Preferences was subclassed
            [splitArgs,remainArgs] = obj.splitArgs('Preferences', varargin{:});
            if ~isempty(splitArgs)
                obj.Preferences = splitArgs{2};
            end
            
            % Retrieve preferences
            obj.loadPreferences();
            
            % Load last figure position
            % Note obj.Figure.Position is inner position, where
            % obj.Position is outer position. Inner position is the same
            % regardless of any menubar or toolbar, while outer position
            % changes if either is added. Use inner position for this
            % purpose so it does not depend on if/when any menubar or
            % toolbar is added to the figure.
            obj.Figure.Position = obj.getPreference('Position',[100 100 1000 700]);
            
            % Assign PV pairs to properties
            [splitArgs,remainArgs] = obj.splitArgs('Visible', remainArgs{:});
            obj.assignPVPairs(remainArgs{:});
            
            % Update the title
            obj.redrawTitle();
            
            % Ensure it's on the screen, in case display settings changed
            obj.moveOnScreen();
            
            % Now, set the remaining args
            if isempty(splitArgs)
                obj.Visible = 'on';
            else
                obj.assignPVPairs(splitArgs{:}); %Visible
            end
            
        end %function
        
        
        function delete(obj)
            % Triggered on app destruction
            
            % Is this object still valid?
            if ~isempty(obj.Figure) && isvalid(obj.Figure)
                
                % Store last position in preferences
                obj.Units = 'pixels';
                lastPos = obj.Figure.Position;
                obj.setPreference('Position',lastPos)
                
                % Save preferences
                obj.savePreferences();
                
            end %if isvalid(obj) && ...
            
        end %function
        
    end %constructor/destructor
    
    
    
    %% Public methods
    methods
        
        function throwError(~,varargin)
            % Throw an error dialog, without logging it
            % If the app inherits uiw.mixin.HasLogger, then use method
            % logError instead to log the error and throw a dialog.
            
            if nargin<2
                title = 'Error';
                message = '';
            elseif isa(varargin{1},'MException')
                errObj = varargin{1};
                stackInputs = [{errObj.stack.name};{errObj.stack.line}];
                stackText = sprintf('\n\t\t> %s (line %d)',stackInputs{:});
                title = varargin{2};
                message = sprintf(varargin{3:end});
                message = [message newline errObj.message stackText];
            elseif nargin == 2
                title = 'Error';
                message = varargin{1};
            else
                title = varargin{1};
                message = sprintf(varargin{2:end});
            end
            
            % Create an error dialog
            hDlg = errordlg(message,title,'modal');
            %RAJ - move to center over app - add method to Figure after
            %changing the dialog to a new uiw.dialog class.
            uiwait(hDlg);
            
        end %function
        
        
        function redrawTitle(obj)
            % Update the figure title - subclass may override
            
            obj.Title = obj.AppName;
            
        end %function
        
        
        function onExit(obj,h)
            % Triggered on figure closed - subclass may override
            
            % Call superclass method
            obj.onExit@uiw.abstract.BaseFigure(h);
            
        end %function
        
    end %methods
    
    
    
    %% Protected methods
    methods (Access=protected)
        
        function redraw(obj)
            % Handle state changes that may need UI redraw - subclass may override
            
            % Ensure the construction is complete
            if obj.IsConstructed
                
            end %if obj.IsConstructed
            
        end % function
        
        
        function onResized(obj)
            % Handle changes to widget size - subclass may override
            
            % Ensure the construction is complete
            if obj.IsConstructed
                
                
            end %if obj.IsConstructed
            
        end %function
        
        
        function onStyleChanged(obj,~)
            % Handle updates to style changes - subclass may override
            
            % Ensure the construction is complete
            if obj.IsConstructed
                
                % Get any other objects at the top level of the widget
                hTopLevel = findall(obj.Figure,'-depth',1);
                
                % Call superclass method implementation to make changes
                obj.onStyleChanged@uiw.mixin.HasContainer(hTopLevel)
                
            end %if obj.IsConstructed
            
        end %function
        
    end %methods
    
    
    
    %% Sealed Protected methods
    methods (Sealed, Access=protected)
        
        function onContainerResized(obj)
            % Triggered on resize of the app's figure
            
            obj.onResized();
            
        end % function
        
    end %methods
    
    
    
    %% Display Customization
    methods (Access=protected)
        
        function propGroup = getPropertyGroups(obj)
            
            subclassProps = properties('uiw.abstract.AppWindow');
            subclassProps = setdiff(properties(obj), subclassProps);
            
            propGroup = [
                obj.getFigurePropertyGroup()
                obj.getAppPropertyGroup()
                matlab.mixin.util.PropertyGroup(subclassProps,'Other App Properties:    app.__________')
                ];
            
        end %function
        
        
        function propGroup = getAppPropertyGroup(obj)
            
            titleTxt = ['AppWindow Properties: '...
                '(<a href = "matlab: helpPopup uiw.abstract.AppWindow">'...
                'AppWindow Documentation</a>)'];
            thisProps = {
                'AppName'
                'IsConstructed'
                };
            g2 = matlab.mixin.util.PropertyGroup(thisProps,titleTxt);
            
            titleTxt = 'Layouts:    app.hLayout.__________';
            thisProps = obj.hLayout;
            g3 = matlab.mixin.util.PropertyGroup(thisProps,titleTxt);
            
            titleTxt = 'Menus:    app.Menu.__________';
            thisProps = obj.Menu;
            g4 = matlab.mixin.util.PropertyGroup(thisProps,titleTxt);
            
            titleTxt = 'Graphics Objects:    app.h.__________';
            thisProps = obj.h;
            g5 = matlab.mixin.util.PropertyGroup(thisProps,titleTxt);
            
            propGroup = [g2;g3;g4;g5];
            
        end %function
        
    end %methods
    
end % classdef
