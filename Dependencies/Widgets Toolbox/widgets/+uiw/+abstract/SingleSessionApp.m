classdef (Abstract) SingleSessionApp < uiw.abstract.AppWindow & uiw.abstract.SessionManagement
    % SingleSessionApp - Base class for app that saves state to MAT file
    %
    % This class provides a base for a hand-coded app that exists within a
    % traditional MATLAB figure window, and can save/load state to a single
    % MAT file.
    %
    % The app that inherits from this class may add a file menu by calling
    % this code:
    %
    %   obj.createFileMenu();
    %
    
%   Copyright 2018-2019 The MathWorks Inc.
    %
    % Auth/Revision:
    %   MathWorks Consulting
    %   $Author: rjackey $
    %   $Revision: 324 $
    %   $Date: 2019-04-23 08:05:17 -0400 (Tue, 23 Apr 2019) $
    % ---------------------------------------------------------------------
    
    
    %% Abstract Methods (subclass must implement these)
    methods(Abstract, Access=protected)
        sessionObj = createSession(obj) %Creation of the session object
        onSessionSet(obj,evt) %What to do when the session changes
    end
    
    
    %% Constructor
    methods
        function obj = SingleSessionApp(varargin)
            % Construct the single session management
            
            % Call superclass constructor
            obj@uiw.abstract.SessionManagement();
            obj@uiw.abstract.AppWindow(varargin{:});
            
            % Single session apps should launch with a new session
            % Create the new session
            obj.onNewSession();
            
        end %function
    end %constructor
    
    
    %% Session Management - subclass may override
    methods
        
        function addSession(obj,sessionObj,sessionPath)
            % Add the specified session to the app - subclass may override
            
            obj.Session = sessionObj;
            obj.SessionPath = string(sessionPath);
            obj.IsDirty = false;
            
            % Notify about the change
            obj.redrawTitle();
            evt = uiw.event.EventData(...
                'Interaction','SessionAdded',...
                'Session',sessionObj);
            obj.notify('SessionSet',evt);
            
        end %function
        
        
        function statusOk = promptToSave(obj,~)
            % Prompt to save if session is dirty
            % statusOk = promptToSave(obj)
            
            % If anything is dirty, save it
            statusOk = ~any(obj.IsDirty) || ...
                obj.promptToSave@uiw.abstract.SessionManagement();
            
        end %function
        
        
        function redrawTitle(obj)
            % Redraw the app's title
            
            if isempty(obj.SessionPath)
                obj.Title = obj.AppName;
            else
                obj.Title = sprintf('%s - %s', obj.AppName, obj.SessionPath);
            end
            if obj.IsDirty
                obj.Title = [obj.Title ' *'];
            end
            
        end %function
        
    end %methods
    
    
    
    %% Session Management - Sealed Methods
    methods (Sealed)
        
        function onNewSession(obj,varargin)
            % Create a new session, providing any extra args to session
            % object constructor - subclass may override
            
            % If there is an existing session, prompt to save it
            if ~isempty(obj.Session) && ~obj.promptToSave()
                return % User cancelled
            end %if ~isempty(obj.Session)
            
            % Delete the session
            idxSel = obj.getSessionInfo(varargin{:});
            obj.deleteSession(idxSel);
            
            % Call superclass implementation to make new session,
            % preserving any extra args to the session obj constructor
            obj.onNewSession@uiw.abstract.SessionManagement(varargin{:});
            
        end %function
        
        
        function onOpenSession(obj,varargin)
            % Open a session from a file - subclass may override
            
            % Prompt the user to save any existing session, else cancel
            if ~obj.promptToSave()
                return
            end
            
            % Call superclass implementation to open a session
            obj.onOpenSession@uiw.abstract.SessionManagement(varargin{:});
            
        end %function

        
        function onExit(obj,h)
            % Triggered on app being exited - subclass may override
            
            % Exit if sessions are clean or user agrees to prompt
            if ~isvalid(obj) || ~any(obj.IsDirty) || obj.promptToSave()
                % Call superclass method
                obj.onExit@uiw.abstract.AppWindow(h);
            end
            
        end %function
        
        
        function markDirty(obj,~)
            % Mark session dirty
            obj.IsDirty = true;
            obj.redrawTitle();
            
        end %function
        
        
        function markClean(obj,~)
            % Mark session not dirty
            
            obj.IsDirty = false;
            obj.redrawTitle();
            
        end %function
        
    end %methods
    
    
    
    %% Protected Methods
    methods (Access=protected)
        
        function [idx,session,sessionPath] = getSessionInfo(obj,varargin)
            % Helper to get session and file path
            % For single session app, additional inputs don't matter
            % [idx,session,sessionPath] = getSessionInfo(obj)
            
            session = obj.Session;
            sessionPath = obj.SessionPath;
            
            idx = 1;
            if isempty(session)
                idx = [];
            end
            
        end %function
        
    end %Protected methods
    
    
    
    %% Display Customization
    methods (Access=protected)
        
        function propGroup = getPropertyGroups(obj)
            
            subclassProps = properties('uiw.abstract.SingleSessionApp');
            subclassProps = setdiff(properties(obj), subclassProps);
            
            titleTxt = ['Session Management Properties: '...
                '(<a href = "matlab: helpPopup uiw.abstract.SingleSessionApp">'...
                'SingleSessionApp Documentation</a>)'];
            thisProps = {
                'Session'
                'SessionName'
                'SessionPath'
                'IsDirty'
                'FileSpec'
                };
            sessionPropGroup = matlab.mixin.util.PropertyGroup(thisProps,titleTxt);
            
            propGroup = [
                obj.getFigurePropertyGroup()
                obj.getAppPropertyGroup()
                sessionPropGroup
                matlab.mixin.util.PropertyGroup(subclassProps,'Other App Properties:    app.__________')
                ];
            
        end %function
        
    end %methods
    
end %classdef
