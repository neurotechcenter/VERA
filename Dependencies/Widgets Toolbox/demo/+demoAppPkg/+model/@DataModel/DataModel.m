classdef DataModel < handle & uiw.mixin.AssignPVPairs
    % DataModel - Class definition for data and analysis model
    % ---------------------------------------------------------------------
    % Abstract: This object defines data table of an analysis
    %
    % Syntax:
    %           obj = demoAppPkg.model.DataModel
    %           obj = demoAppPkg.model.DataModel('Property','Value',...)
    %
    
%   Copyright 2018-2019 The MathWorks Inc.
    %
    % Auth/Revision:
    %   MathWorks Consulting
    %   $Author: rjackey $
    %   $Revision: 324 $  $Date: 2019-04-23 08:05:17 -0400 (Tue, 23 Apr 2019) $
    % ---------------------------------------------------------------------
    
    %% Events
    events
        ModelChanged %Triggered when relevant properties of the model are changed
    end
    
    
    %% Properties
    properties (AbortSet)
        Table table %Table of airline data
        
        % Plot selections
        PlotType (1,1) demoAppPkg.enum.PlotType = demoAppPkg.enum.PlotType.Fraction %Selected plot type
        DelayType (1,1) demoAppPkg.enum.DelayType = demoAppPkg.enum.DelayType.Departure %Selected delay type to plot
        DelayTime (1,1) double {mustBeNonnegative,mustBeFinite} = 15; % Minimum time (minutes) considered a delay
        
        % Filters
        CarrierFilter %Selected carriers to display
        OriginFilter %Selected origins to display
        DestinationFilter %Selected destinations to display
    end
    
    properties (Dependent, SetAccess=private)
        FilteredTable
    end
    
    properties (SetAccess=protected)
        RowIsSelected (:,1) logical %Logical index of rows selected
    end
    
    
    
    %% Methods in separate files
    methods
        [x,y] = getBarPlotData(obj)
    end %methods
    
    methods(Access=protected)
        applyFilters(obj)
    end %methods
    
    
    %% Constructor
    methods
        function obj = DataModel(varargin)
            % Constructor for demoAppPkg.model.DataModel
            
            % Populate public properties from P-V input pairs
            obj.assignPVPairs(varargin{:});
            
            % Prepare event data
            evt = uiw.event.EventData(...
                'EventType','DataChanged',...
                'Property','Table',...
                'Model',obj);
            
            % Trigger notification to listeners
            obj.notify('ModelChanged',evt)
            
        end %function
    end %methods
    
    
    
    %% Protected methods
    methods (Access=protected)
        
        function clearFilters(obj)
            
            % Clear the filters
            obj.CarrierFilter = [];
            obj.OriginFilter = [];
            obj.DestinationFilter = [];
            obj.RowIsSelected = true( height(obj.Table), 1 );
            
        end %function
        
    end %methods
    
    
    
    %% Get / Set Methods
    methods
        
        function value = get.FilteredTable(obj)
            value = obj.Table(obj.RowIsSelected,:);
        end
        
        
        function set.Table(obj,value)
            obj.Table = value;
            
            % Clear the filters first
            obj.clearFilters();
            
            % Prepare event data
            evt = uiw.event.EventData(...
                'EventType','DataChanged',...
                'Property','Table',...
                'Model',obj);
            
            % Trigger notification to listeners
            obj.notify('ModelChanged',evt)
        end
        
        function set.PlotType(obj,value)
            obj.PlotType = value;
            
            % Prepare event data
            evt = uiw.event.EventData(...
                'EventType','PlotSettingChanged',...
                'Property','PlotType',...
                'Model',obj);
            
            % Trigger notification to listeners
            obj.notify('ModelChanged',evt)
        end
        
        function set.DelayType(obj,value)
            obj.DelayType = value;
            
            % Prepare event data
            evt = uiw.event.EventData(...
                'EventType','PlotSettingChanged',...
                'Property','DelayType',...
                'Model',obj);
            
            % Trigger notification to listeners
            obj.notify('ModelChanged',evt)
        end
        
        function set.DelayTime(obj,value)
            obj.DelayTime = value;
            
            % Prepare event data
            evt = uiw.event.EventData(...
                'EventType','PlotSettingChanged',...
                'Property','DelayTime',...
                'Model',obj);
            
            % Trigger notification to listeners
            obj.notify('ModelChanged',evt)
        end
        
        function set.CarrierFilter(obj,value)
            validateattributes(value,{'char','string','categorical'},{});
            
            obj.CarrierFilter = value;
            obj.applyFilters();
            
            % Prepare event data
            evt = uiw.event.EventData(...
                'EventType','FilterChanged',...
                'Property','CarrierFilter',...
                'Model',obj);
            
            % Trigger notification to listeners
            obj.notify('ModelChanged',evt)
        end
        
        function set.OriginFilter(obj,value)
            validateattributes(value,{'char','string','categorical'},{});                
            
            obj.OriginFilter = value;
            obj.applyFilters();
            
            % Prepare event data
            evt = uiw.event.EventData(...
                'EventType','FilterChanged',...
                'Property','OriginFilter',...
                'Model',obj);
            
            % Trigger notification to listeners
            obj.notify('ModelChanged',evt)
        end
        
        function set.DestinationFilter(obj,value)
            validateattributes(value,{'char','string','categorical'},{});
            
            obj.DestinationFilter = value;
            obj.applyFilters();
            
            % Prepare event data
            evt = uiw.event.EventData(...
                'EventType','FilterChanged',...
                'Property','DestinationFilter',...
                'Model',obj);
            
            % Trigger notification to listeners
            obj.notify('ModelChanged',evt)
        end
        
    end %methods
    
end %classdef
