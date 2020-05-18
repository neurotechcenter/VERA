classdef PlotSelector < uiw.abstract.WidgetContainer
    % PlotSelector - Class definition for PlotSelector viewer
    % ---------------------------------------------------------------------
    % Abstract: Implements a viewer / editor
    %           
    % Syntax:
    %           obj = demoAppPkg.view.PlotSelector
    %           obj = demoAppPkg.view.PlotSelector('Property','Value',...)
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
   
    
    %% Methods in separate files
    methods (Access=protected)
        create(obj);
        redraw(obj);
        redrawSelections(obj);
    end
    
    
    %% Constructor
    methods
        function obj = PlotSelector(varargin)
            % Constructor for PlotSelector
            
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
        
        function onSliderChanged(obj,evt)
            % Triggered when slider is changed
            
            % What was set?
            newValue = evt.Source.Value;
            
            % Set the new value
            obj.DataModel.DelayTime = newValue;
            
        end %function
        
        
        function onPopupSelection(obj,evt)
            % Triggered when a popup selection is made
            
            % What was selected?
            newValue = evt.Source.Value;
            
            % Update the model
            switch evt.Source
                
                case obj.h.PlotTypePopup
                    obj.DataModel.PlotType = newValue;
                
                case obj.h.DelayTypePopup
                    obj.DataModel.DelayType = newValue;
                
                case obj.h.CarrierPopup
                    obj.DataModel.CarrierFilter = newValue;
                
                case obj.h.OriginPopup
                    obj.DataModel.OriginFilter = newValue;
                
                case obj.h.DestinationPopup
                    obj.DataModel.DestinationFilter = newValue;
                    
                otherwise
                    warning('onPopup:UnhandledControl','Unhandled control');
                    
            end %switch
            
        end %function
        
        
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
                
                case 'DataChanged'
                    
                    % Need to redraw everything including choices
                    obj.redraw();
                    
                case 'FilterChanged'
                    
                    % Need to redraw selections
                    obj.redrawSelections();
                    
                case 'PlotSettingChanged'
                    
                    % Need to redraw selections
                    obj.redrawSelections();
                    
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