classdef DisplayTable < uiw.abstract.WidgetContainer
    % DisplayTable - Class definition for DisplayTable viewer
    % ---------------------------------------------------------------------
    % Abstract: Implements a viewer / editor
    %           
    % Syntax:
    %           obj = demoAppPkg.view.DisplayTable
    %           obj = demoAppPkg.view.DisplayTable('Property','Value',...)
    %
    
%   Copyright 2018-2019 The MathWorks Inc.
    %
    % Auth/Revision:
    %   MathWorks Consulting
    %   $Author: rjackey $
    %   $Revision: 324 $  $Date: 2019-04-23 08:05:17 -0400 (Tue, 23 Apr 2019) $
    % ---------------------------------------------------------------------
    
    
    %% Properties
    properties (AbortSet)
        DataModel (1,1) demoAppPkg.model.DataModel = demoAppPkg.model.DataModel %The data model to display and manipulate
    end
    
    properties (Transient, Access=private)
        ModelChangedListener event.listener %Listener to model changes
    end %properties
    
    %% Methods in separate files with custom permissions
    methods (Access=protected)
        create(obj);
        redraw(obj);
    end
    
    
    %% Constructor
    methods
        function obj = DisplayTable(varargin)
            % Constructor for DisplayTable
            
            % Call superclass constructor
            obj = obj@uiw.abstract.WidgetContainer();
            
            % Create the base graphics
            obj.create();
            
            % Populate public properties from P-V input pairs
            obj.assignPVPairs(varargin{:});
            
            % Assign the construction flag
            % This marks the viewer construction complete, so view updates
            % will begin. The view updates don't occur before this is
            % marked true, for performance and visual reasons.
            obj.IsConstructed = true;
            
            % Redraw the widget
            obj.onResized();
            obj.onEnableChanged();
            obj.redraw();
            obj.onStyleChanged();
            
        end %function
    end %methods
    
    
    
    %% Protected Methods
    methods (Access=protected)
        
        function onModelSet(obj)
            % Triggered when a new DataModel is set
            
            % Attach a listener to the new model
            obj.ModelChangedListener = event.listener(obj.DataModel,...
                'ModelChanged',@(h,e)onModelChanged(obj,e) );
            
            % New model, so full redraw is needed
            obj.redraw();
            
        end %function
        
        
        function onModelChanged(obj,evt)
            % Triggered on existing DataModel events
            
            % Take action for this EventType
            switch evt.EventType
                
                case {'DataChanged','FilterChanged'}
                    
                    % Affects this view - need to redraw
                    obj.redraw();
                    
                case {'PlotSettingChanged'}
                    
                    % Does not affect this view - Take no action
                    
                otherwise
                    
                    % Throw a warning, then redraw just to be safe
                    warning('onModelChanged:UnhandledEvent',...
                        'Unhandled event type: %s',evt.EventType);
                    
                    obj.redraw();
                    
            end %switch
            
        end %function
        
    end %methods
    
    
    %% Get / Set Methods
    methods
        
        function set.DataModel(obj,value)
            obj.DataModel = value;
            obj.onModelSet();
        end %function
        
    end %methods
    
end %classdef