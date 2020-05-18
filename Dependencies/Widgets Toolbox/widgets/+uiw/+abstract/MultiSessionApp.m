classdef (Abstract, Hidden) MultiSessionApp < uiw.abstract.AppWindow & uiw.abstract.SessionManagement
    % MultiSessionApp - Base class for app that saves state to MAT file
    %
    % This class provides a base for a hand-coded app that exists within a
    % traditional MATLAB figure window, and can save/load state to multiple
    % MAT files.
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
    
    
    %% Properties
    properties (AbortSet, SetAccess=private)
        SelectedSessionIdx double = double.empty(0,1)
    end
    
    properties (AbortSet, Dependent, SetAccess=private)
        NumSessions
        SelectedSession
        SelectedSessionName
        SelectedSessionPath
    end
    
    
    %% Constructor
    methods
        function obj = MultiSessionApp(varargin)
            % Construct the multi session management
            
            % Call superclass constructor
            obj@uiw.abstract.SessionManagement();
            obj@uiw.abstract.AppWindow(varargin{:});
            
        end %function
    end %constructor
    
    
    %% Session Management - subclass may override
    methods
        
        function addSession(obj,sessionObj,sessionPath)
            % Add the specified session to the app - subclass may override
            
            idxNew = obj.NumSessions + 1;
            if isempty(obj.Session)
                obj.Session = sessionObj;
            else
                obj.Session(idxNew,1) = sessionObj;
            end
            obj.SessionPath{idxNew,1} = sessionPath;
            obj.SelectedSessionIdx = idxNew;
            obj.IsDirty(idxNew,1) = false;
            
            % Notify about the change
            obj.redrawTitle();
            evt = uiw.event.EventData(...
                'Interaction','SessionAdded',...
                'Session',sessionObj);
            obj.notify('SessionSet',evt);
            
        end %function
        
        
        function statusOk = promptToSave(obj,varargin)
            % Prompt to save if session is dirty
            % statusOk = promptToSave(obj)
            % statusOk = promptToSave(obj,sessionIdx)
            % statusOk = promptToSave(obj,sessionIdx, sessionPath)
            % statusOk = promptToSave(obj,sessionObj)
            % statusOk = promptToSave(obj,sessionObj, sessionPath)
            
            % If anything is dirty, save it
            statusOk = ~any(obj.IsDirty) || ...
                obj.promptToSave@uiw.abstract.SessionManagement(varargin{:});
            
        end %function
        
        
        function redrawTitle(obj)
            % Redraw the app's title
            
            if obj.SelectedSessionIdx <= numel(obj.SessionPath)
                obj.Title = sprintf('%s - %s', obj.AppName,...
                    obj.SessionPath{obj.SelectedSessionIdx});
            else
                obj.Title = obj.AppName;
            end
            if obj.IsDirty
                obj.Title = [obj.Title ' *'];
            end
            
        end %function
        
    end %methods
    
    
    
    %% Session Management - Sealed Methods
    methods (Sealed)
        
        function selectSession(obj,sessionObj)
            % Select a session by object or index
            % selectSession(obj,sessionObj)
            % selectSession(obj,sessionIdx)
            
            % Get the session and file path to save
            [obj.SelectedSessionIdx, sessionObj] = getSessionInfo(obj,sessionObj);
            
            % Notify about the change
            evt = uiw.event.EventData(...
                'Interaction','SessionSelected',...
                'Session',sessionObj);
            obj.notify('SessionSet',evt);
            
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
            obj.IsDirty(obj.SelectedSessionIdx) = true;
            obj.redrawTitle();
            
        end %function
        
        
        function markClean(obj,~)
            % Mark session not dirty
            
            obj.IsDirty(obj.SelectedSessionIdx) = false;
            obj.redrawTitle();
            
        end %function
        
    end %methods
    
    
    
    %% Protected Methods
    methods (Access=protected)
        
        function deleteSession(obj,idxSel)
            % Delete the specified session from the app - subclass may override
            
            obj.Session(idxSel) = [];
            obj.SessionPath(idxSel) = [];
            obj.IsDirty(idxSel) = [];
            
            % Check for a valid selected session
            if obj.NumSessions == 0
                obj.SelectedSessionIdx = [];
            elseif obj.SelectedSessionIdx > obj.NumSessions
                obj.SelectedSessionIdx = obj.NumSessions;
            end
            
        end %function
        
        
        function [idx,session,sessionPath] = getSessionInfo(obj,varargin)
            % Helper to get session and file path
            % [idx,session,sessionPath] = getSessionInfo(obj)
            % [idx,session,sessionPath] = getSessionInfo(obj,sessionIdx)
            % [idx,session,sessionPath] = getSessionInfo(obj,sessionIdx, sessionPath)
            % [idx,session,sessionPath] = getSessionInfo(obj,sessionObj)
            % [idx,session,sessionPath] = getSessionInfo(obj,sessionObj, sessionPath)
            
            if nargin<2
                idx = obj.SelectedSessionIdx;
            elseif isempty(varargin{1})
                idx = [];
            elseif isnumeric(varargin{1})
                validateattributes(varargin{1},{'numeric'},{'integer','positive','<=',obj.NumSessions});
                idx = varargin{1};
            elseif islogical(varargin{1})
                validateattributes(varargin{1},{'logical'},{'numel',obj.NumSessions});
                idx = varargin{1};
            else
                idx = ismember(obj.Session, varargin{1});
            end
            
            session = obj.Session(idx);
            
            if nargin<3
                sessionPath = obj.SessionPath(idx);
            elseif numel(varargin{2}) ~= numel(sessionObj)
                error('Size of sessionPath must equal size of sessionObj.');
            else
                sessionPath = string(varargin{2});
            end
            
        end %function
        
    end %Protected methods
    
    
    
    %% Display Customization
    methods (Access=protected)
        
        function propGroup = getPropertyGroups(obj)
            
            subclassProps = properties('uiw.abstract.MultiSessionApp');
            subclassProps = setdiff(properties(obj), subclassProps);
            
            titleTxt = ['Session Management Properties: '...
                '(<a href = "matlab: helpPopup uiw.abstract.MultiSessionApp">'...
                'MultiSessionApp Documentation</a>)'];
            thisProps = {
                'SelectedSession'
                'SelectedSessionIdx'
                'SelectedSessionName'
                'SelectedSessionPath'
                'NumSessions'
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
    
    
    
    %% Get/Set methods
    methods
        
        function value = get.NumSessions(obj)
            value = numel(obj.Session);
        end
        
        function value = get.SelectedSession(obj)
            if obj.SelectedSessionIdx <= obj.NumSessions
                value = obj.Session( obj.SelectedSessionIdx );
            else
                value = obj.Session( [] );
            end
        end
        
        function value = get.SelectedSessionName(obj)
            % Grab the session object for the selected session
            sIdx = obj.SelectedSessionIdx;
            if isempty(sIdx) || isempty(obj.SessionPath)
                value = '';
            else
                value = obj.SessionNames{obj.SelectedSessionIdx};
            end
        end
        
        function value = get.SelectedSessionPath(obj)
            % Grab the session object for the selected session
            sIdx = obj.SelectedSessionIdx;
            if isempty(sIdx) || numel(obj.SessionPath) < sIdx
                value = '';
            else
                value = obj.SessionPath{sIdx};
            end
        end
        
    end %methods
        
end %classdef
