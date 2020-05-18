classdef App < uiw.abstract.SingleSessionApp
    % App - Class definition for a MATLAB desktop application
    % ---------------------------------------------------------------------
    % Instantiates the Application figure window
    %
    % Syntax:
    %           app = demoAppPkg.view.App
    %           app = demoAppPkg.view.App('Property','Value',...)
    %
    
%   Copyright 2018-2019 The MathWorks Inc.
    %
    % Auth/Revision:
    %   MathWorks Consulting
    %   $Author: rjackey $
    %   $Revision: 324 $
    %   $Date: 2019-04-23 08:05:17 -0400 (Tue, 23 Apr 2019) $
    % ---------------------------------------------------------------------
    
    %% Properties
    properties (Transient, Access=private)
        ModelChangedListener event.listener %Listener to model changes
    end %properties
    
    
    %% Application Settings
    properties (Constant, Access=protected)
        
        % Abstract in superclass
        AppName char = 'Airline Delay Analysis'
        
    end %properties
    
    
    %% Methods in separate files with custom permissions
    methods (Access=protected)
        create(obj);
        redraw(obj);
    end

    
    %% Constructor and Destructor
    methods
        
        % Constructor
        function obj = App(varargin)
            % Construct the app
            
            % Call superclass constructor
            obj@uiw.abstract.SingleSessionApp();
            % After developing, use below instead to delay visibility
            %obj@uiw.abstract.SingleSessionApp('Visible','off');
            
            % Create the file menu from SessionManagement & SingleSessionApp
            obj.createFileMenu();

            % Create the base graphics
            obj.create();
            
            % Populate public properties from P-V input pairs
            obj.assignPVPairs(varargin{:});
            
            % Mark construction complete to tell redraw the graphics exist
            obj.IsConstructed = true;
            
            % Redraw the entire view
            obj.redraw();
            
            % Now, make the figure visible
            obj.Visible = 'on';
            
        end %function
        
    end %methods
    
    
    
    %% Protected Methods
    methods (Access=protected)
        
        function sessionObj = createSession(~) 
            %Creation of the session object
            
            sessionObj = demoAppPkg.model.DataModel();
            
        end %function
        
        
        function onDataMenuItem(obj,evt)
            %Triggered on menu items
            
            % Which menu item?
            switch evt.Source.Tag
                
                case 'DataLoad'
                    
                    title = 'Load Data';
                    message = 'Loading Data...';
                    hDlg = msgbox(message,title,'modal');
                    
                    % Load the data
                    obj.Session.importFile('airlinesmall.csv');
                    
                    % Wait for user to close dialog
                    uiwait(hDlg);
                    
                otherwise
                    
                    warning('demoApp:invalidMenuItem',...
                        'Unhandled Menu Selection: %s', evt.Source.Tag);
                    
            end %switch
            
        end %function
        
        
        function onSessionSet(obj,~)
            %What to do when the session changes
            
            % Attach a listener to the new model
            obj.ModelChangedListener = event.listener(obj.Session,...
                'ModelChanged',@(h,e)onModelChanged(obj,e) );
            
            % New model, so full redraw is needed
            obj.redraw();
            
        end %function
        
        
        function onModelChanged(obj,evt)
            % Triggered on existing DataModel events
            
            % Take action for this EventType
            switch evt.EventType
                
                case 'DataChanged'
                    
                    % Mark the session dirty
                    obj.markDirty();
                    
                    % Need to redraw
                    obj.redraw();
                    
                case 'FilterChanged'
                    
                    % Mark the session dirty
                    obj.markDirty();
                    
                    % Need to redraw
                    obj.redraw();
                    
                case 'PlotSettingChanged'
                    
                    % Mark the session dirty
                    obj.markDirty();
                    
                    % Need to redraw
                    obj.redraw();
                
                otherwise
                    
                    % Throw a warning, then redraw just to be safe
                    warning('onModelChanged:UnhandledEvent',...
                        'Unhandled event type: %s',evt.EventType);
                    
                    obj.redraw();
                    
            end %switch
            
        end %function
        
    end %methods
    
    
end %classdef