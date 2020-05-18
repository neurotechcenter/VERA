classdef (Abstract) HasPreferences < handle
    % HasPreferences - Mixin class for managing app preferences
    %
    % This class provides the basic properties needed for managing
    % preferences storage of a hand-coded app that exists within a
    % traditional MATLAB figure window. 
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
    properties (SetAccess=protected)
        Preferences (1,1) uiw.model.Preferences %Model class for App preferences (may subclass uiw.model.Preferences to add more prefs)
        PreferenceGroup char % Name of Preference Group to store
    end
    
    
    %% Public methods
    methods (Sealed)
        
        function value = getPreference(obj,propName,defaultValue)
            % Get an app preference from the Preferences object
            
            if isprop(obj.Preferences, propName)
                value = obj.Preferences.(propName);
            elseif nargin>2
                value = defaultValue;
            else
                value = [];
            end
            
        end %function
        
        
        function setPreference(obj,propName,value)
            % Set an app preference in the Preferences object
            
            if ~isprop(obj.Preferences,propName)
                addprop(obj.Preferences,propName);
            end
            obj.Preferences.(propName) = value;
            
        end %function
        
        
        function loadPreferences(obj)
            % Load stored preferences
            
            obj.Preferences.load(obj.PreferenceGroup);
            
        end %function
        
        
        function savePreferences(obj)
            % Save preferences
            
            obj.Preferences.save(obj.PreferenceGroup);
            
        end %function
    
    end %methods
    
    
    
    %% Get/Set Methods
    methods
        
        function value = get.PreferenceGroup(obj)
            value = obj.PreferenceGroup;
            if isempty(value)
                value = class(obj);
            end
            value = matlab.lang.makeValidName(value);
        end
        
    end %methods
    
end % classdef
