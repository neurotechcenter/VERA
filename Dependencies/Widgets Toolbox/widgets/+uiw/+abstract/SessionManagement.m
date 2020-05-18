classdef (Abstract, AllowedSubclasses = {?uiw.abstract.SingleSessionApp,?uiw.abstract.MultiSessionApp}) ...
        SessionManagement < uiw.mixin.HasPreferences
    % SessionManagement - Base class for app with session management
    %
    % This class adds common properties and methods that are used by
    % session management for an app. See SingleSessionApp and
    % MultiSessionApp for implementations.
    %
    
    %   Copyright 2018-2019 The MathWorks, Inc.
    %
    % Auth/Revision:
    %   MathWorks Consulting
    %   $Author: rjackey $
    %   $Revision: 319 $
    %   $Date: 2019-04-01 14:23:02 -0400 (Mon, 01 Apr 2019) $
    % ---------------------------------------------------------------------
    
    
    %% Abstract Methods (subclass must implement these)
    methods(Abstract)
        addSession(obj,sessionObj,sessionPath) % Add the specified session to the app
        %removeSession(obj,sessionObj) %Remove the specified session from the app
        markDirty(obj,sessionObj) %Mark session dirty
        markClean(obj,sessionObj) %Mark session not dirty
        redrawTitle(obj) %Redraw the app title, triggered when session status changes
    end
    methods(Abstract, Access=protected)
        sessionObj = createSession(obj) %Creation of the session object
        onSessionSet(obj,evt) %What to do when the session object is set
        [idx,session,sessionPath] = getSessionInfo(obj,varargin) %Return the session, index, etc.
    end
    
    
    %% Events
    events (NotifyAccess={?uiw.abstract.SingleSessionApp,?uiw.abstract.MultiSessionApp,?uiw.mixin.HasLogger})
        SessionSet %Triggered after Session has been set
    end
    
    
    %% Properties
    
    % These properties are set only within this class or direct subclasses
    properties (AbortSet, SetAccess={?uiw.abstract.SingleSessionApp,?uiw.abstract.MultiSessionApp})
        Session %Session data for the app
        SessionPath string %Path to store the session file
        IsDirty logical %Indicates modifications have not been saved
    end %properties
    
    properties (AbortSet, Dependent, SetAccess=private)
        SessionName
    end %properties
    
    properties (AbortSet, SetAccess=protected)
        FileSpec (:,2) cell = {'*.mat','MATLAB MAT File'};
    end
    
    % These properties are only used within this class
    properties (Access=private)
        FileMenu (1,1) struct
        RecentFilesMenu matlab.ui.container.Menu
        SessionSetListener
    end %properties
    
    
    
    %% Constructor / Destructor
    methods
        function obj = SessionManagement()
            % Construct the session management
            
            % Set up the listener
            obj.SessionSetListener = event.listener(obj,'SessionSet',@(h,e)onSessionSet(obj,e));
            
        end %function
    end %methods
    
    
    
    %% Public Methods
    methods
        
        function onNewSession(obj,varargin)
            % Create a new session - superclass may override
            
            try
                % Instantiate the session object - app subclass must
                % implement createSession and return an object
                newSessionObj = obj.createSession(varargin{:});
                
                % Use 'untitledX' as the initial name
                sessionPath = matlab.lang.makeUniqueStrings(...
                    'untitled',obj.SessionName);
                
                obj.addSession(newSessionObj,sessionPath);
            
            catch err
                % Throw an error
                obj.throwError(err,'New Session','Unable to create new session.\n')
            end
            
        end %function
        
        
        function onOpenSession(obj,sessionPath)
            % Open a session from a file - subclass may override
            
            % Prompt for a filename to load
            if nargin < 2
                sessionPath = obj.promptFileNameToLoad();
            end
            
            % Validate the file exists and isn't already open
            if isequal(sessionPath,'')
                
                % User cancelled
                return
                
            elseif ~exist(sessionPath,'file')
                
                % Throw an error
                obj.throwError('Open Session','The specified file does not exist: \n%s',sessionPath)
                
            elseif ismember(sessionPath, obj.SessionPath)
                
                % Throw an error
                obj.throwError('Open Session','The specified file is already open: \n%s',sessionPath)
                
            else
                try
                    % Load the session file
                    newSessionObj = obj.loadSessionFromFile(sessionPath);
                    
                    % Add the session to the app
                    obj.addSession(newSessionObj, sessionPath);
                    obj.addRecentSessionPath(sessionPath);
                    
                catch err
                    % Throw an error
                    obj.throwError(err,'Open Session',...
                        'The file %s did not contain a valid Session or could not be loaded.\n',...
                        sessionPath);
                end
            end
            
            
        end %function
        
        
        function statusOk = onCloseSession(obj,varargin)
            % Close a session
            % statusOk = onCloseSession(obj)
            % statusOk = onCloseSession(obj,sessionObj)
            
            statusOk = obj.closeSession(varargin{:});
            
        end %function
        
        
        function statusOk = promptToSave(obj,varargin)
            % Prompt to save changes for the specified session(s)
            % statusOk = promptToSave(obj)
            % statusOk = promptToSave(obj,sessionIdx)
            % statusOk = promptToSave(obj,sessionIdx, sessionPath)
            % statusOk = promptToSave(obj,sessionObj)
            % statusOk = promptToSave(obj,sessionObj, sessionPath)
            
            % Get the session and file path to save
            [~,sessionObj,sessionPath] = getSessionInfo(obj,varargin{:});
            
            sessionPath = cellstr(sessionPath);
            statusOk = true;
            idx = 1;
            while statusOk && idx <= numel(sessionObj)
                message = sprintf('Save changes to %s?', sessionPath{idx});
                selection = questdlg(message,'Save Changes','Yes','No','Cancel','Yes');
                switch selection
                    case 'Yes'
                        statusOk = obj.saveSessionToFile(sessionPath,sessionObj);
                    case 'Cancel'
                        statusOk = false;
                        return
                end %switch Result
                idx = idx + 1;
            end
            
        end %function
        
        
        function removeSession(obj,varargin)
            % Remove the specified session from the app - subclass may override
            
            % Delete the session
            [idxSel,sessionObj] = obj.getSessionInfo(varargin{:});
            obj.deleteSession(idxSel);
            
            % Notify about the change
            obj.redrawTitle();
            evt = uiw.event.EventData(...
                'Interaction','SessionRemoved',...
                'Session',sessionObj);
            obj.notify('SessionSet',evt);
            
        end %function
        
        
        function redrawFileMenu(obj)
            % Redraw file menu items
            
            % Ensure the Open Recent exists
            if isfield(obj.FileMenu,'Menu') && isvalid(obj.FileMenu.Menu)
                
                % Refresh the list of Recent Files
                recentSessionPath = obj.getPreference('RecentSessionPaths',string.empty(0,1));
                
                % Add new items
                hItems = obj.RecentFilesMenu.Children;
                if isempty(hItems)
                    ItemsToAdd = recentSessionPath;
                else
                    ExistingItems = [hItems.UserData];
                    ToAdd = ~ismember(recentSessionPath, ExistingItems);
                    ItemsToAdd = recentSessionPath(ToAdd);
                end
                for idx=1:numel(ItemsToAdd)
                    uimenu(...
                        'Parent', obj.RecentFilesMenu,...
                        'Label', ItemsToAdd(idx),...
                        'Tag','FileOpenRecentItem',...
                        'UserData', ItemsToAdd(idx),...
                        'Callback', @(h,e)onOpenSession(obj, ItemsToAdd{idx}) );
                end
                
                % Remove old items and order the rest
                hItems = obj.RecentFilesMenu.Children;
                if ~isempty(hItems)
                    ExistingItems = [hItems.UserData]';
                    [ToKeep1, idxKeep] = ismember(ExistingItems, recentSessionPath);
                    delete(hItems(~ToKeep1));
                    hItems(~ToKeep1) = [];
                    Order = idxKeep(ToKeep1);
                    hItems = flipud(hItems(Order));
                    obj.RecentFilesMenu.Children = hItems;
                end
                
                % If no recent items, disable the menu item
                HasRecent = uiw.utility.tf2onoff( ~isempty(hItems) );
                set(obj.RecentFilesMenu,'Enable',HasRecent)
                
                % Enable File->Save only if dirty
                set(obj.FileMenu.Save,...
                    'Enable',uiw.utility.tf2onoff(any(obj.IsDirty)))
                
            end %if
            
        end %function
        
        
        function statusOk = saveSessionToFile(obj,sessionPath,sessionObj)
            % Save a session object into a MAT file - subclass may override
            
            try
                s.Session = sessionObj;
                save(sessionPath,'-struct','s');
                obj.addRecentSessionPath(sessionPath);
                statusOk = true;
            catch err
                % Throw an error
                obj.throwError(err,'Save Session','Unable to save session.\n')
                statusOk = false;
            end
            
        end %function
        
        
        function sessionObj = loadSessionFromFile(obj,sessionPath)
            % Load a session object from a MAT file - subclass may override
            
            s = load(sessionPath,'Session');
            sessionObj = s.Session;
            
            obj.addRecentSessionPath(sessionPath);
            
        end %function
        
        
        function statusOk = closeSession(obj,varargin)
            % Close a session - subclass may override
            
            % Get the session
            idxSel = getSessionInfo(obj,varargin{:});
            
            % Prompt to save changes
            statusOk = obj.promptToSave(idxSel);
            if statusOk
                obj.removeSession(idxSel)
            end %if statusOk
            
        end %function
        
    end %methods
    
    
    
    %% Session Management - Sealed Methods
    methods (Sealed)
        
        function sessionPath = onSaveSession(obj,forceDialog,varargin)
            % Save the session to a file
            % onSaveSession(obj,forceDialog,sessionObj,sessionPath)
            
            % Get the session and file path to save
            [idxSel,sessionObj,sessionPath] = getSessionInfo(obj,varargin{:});
            
            % Get the save location for this sesson. If new, prepare a
            % default path. If no path, use the last folder to start in.
            if isempty(fileparts(char(sessionPath))) %char() needed for R2017a fileparts compatibility
                lastFolder = obj.getPreference('LastFolder', pwd);
                sessionPath = fullfile(char(lastFolder), char(sessionPath));
            end
            
            % Do we need to prompt for a filename?
            if (nargin>=2 && forceDialog) || ~exist(char(sessionPath),'file')
                sessionPath = promptFileNameToSave(obj,sessionPath);
            end
            
            % Save the file
            if ~isempty(sessionPath)
                % Perform the save
                statusOk = obj.saveSessionToFile(sessionPath, sessionObj);
                
                % Update state for this session
                if statusOk
                    obj.markClean(sessionObj);
                else
                    sessionPath = '';
                end
            end
            
            % Store result
            obj.SessionPath(idxSel) = sessionPath;
            
            % Redraw the app title
            obj.redrawTitle();
            obj.redrawFileMenu();
            
        end %function
        
    end %methods
    
    
    
    %% Protected Methods
    methods (Access=protected)
        
        function deleteSession(obj,idxSel)
            % Delete the specified session from the app - subclass may override
            
            obj.Session(idxSel) = [];
            obj.SessionPath(idxSel) = [];
            obj.IsDirty(idxSel) = [];
            
        end %function
        
        
        function sessionPath = promptFileNameToSave(obj,startPath)
            % Prompt for a file to save - subclass may override
            
            [fileName,pathName] = uiputfile(obj.FileSpec,'Save as',char(startPath));
            
            % Did the user cancel?
            if isequal(fileName,0)
                % Yes - return empty
                sessionPath = [];
            else
                % No - Form the full path
                sessionPath = fullfile(pathName,fileName);
                
                % Track the last folder touched
                obj.setPreference('LastFolder',pathName);
                
            end %if isequal(fileName,0)
            
        end %function
        
        
        function sessionPath = promptFileNameToLoad(obj)
            % Prompt for a file to load - subclass may override
            
            lastFolder = obj.getPreference('LastFolder', pwd);
            [fileName,pathName] = uigetfile(obj.FileSpec,'Open File',char(lastFolder));
            
            % Did the user cancel?
            if isequal(fileName,0)
                % Yes - return empty
                sessionPath = '';
            else
                % No - Form the full path
                sessionPath = fullfile(pathName,fileName);
                
                % Track the last folder touched
                obj.setPreference('LastFolder',pathName);
                
            end %if isequal(fileName,0)
            
        end %function
        
        
        function h = createFileMenu(obj)
            % Create a file menu - subclass may override
            
            % Load recent file paths
            recentSessionPath = obj.getPreference('RecentSessionPaths',string.empty(0,1));
            
            % Validate each recent file, and remove any invalid files
            if verLessThan('matlab','9.3')
                idxOk = cellfun(@(x)exist(x,'file'),cellstr(recentSessionPath));
            else
                idxOk = arrayfun(@(x)exist(x,'file'),recentSessionPath);
            end
            recentSessionPath(~idxOk) = [];
            obj.setPreference('RecentSessionPaths',recentSessionPath);
            
            % Create the file menu items
            h.Menu = uimenu(...
                'Parent',[],...
                'Label','File',...
                'Tag','FileMenu');
            
            h.New = uimenu(...
                'Parent',h.Menu,...
                'Label','New...',...
                'Tag','FileNew',...
                'Accelerator','N',...
                'Callback',@(h,e)onNewSession(obj));
            
            h.Open = uimenu(...
                'Parent',h.Menu,...
                'Label','Open...',...
                'Tag','FileOpen',...
                'Accelerator','O',...
                'Callback',@(h,e)onOpenSession(obj));
            
            h.OpenRecent = uimenu(...
                'Parent',h.Menu,...
                'Label','Open Recent',...
                'Tag','FileOpenRecentMenu');
            
            h.Close = uimenu(...
                'Parent',h.Menu,...
                'Label','Close',...
                'Tag','FileClose',...
                'Separator','on',...
                'Visible','off',... %Hide for single-session app
                'Callback',@(h,e)onCloseSession(obj));
            
            h.Save = uimenu(...
                'Parent',h.Menu,...
                'Label','Save',...
                'Tag','FileSave',...
                'Accelerator','S',...
                'Separator','on',...
                'Callback',@(h,e)onSaveSession(obj,false));
            
            h.SaveAs = uimenu(...
                'Parent',h.Menu,...
                'Label','Save As...',...
                'Tag','FileSaveAs',...
                'Callback',@(h,e)onSaveSession(obj,true));
            
            h.Exit = uimenu(...
                'Parent',h.Menu,...
                'Label','Exit',...
                'Tag','FileExit',...
                'Accelerator','Q',...
                'Separator','on',...
                'Callback',@(h,e)onExit(obj,obj.Figure));
            
            % Store the result
            obj.FileMenu = h;
            obj.RecentFilesMenu = h.OpenRecent;
            
            % Check if we can attach to figure yet
            if isprop(obj,'Figure') && isscalar(obj.Figure) && isvalid(obj.Figure)
               h.Menu.Parent = obj.Figure; 
            end
            
            % Add menu items for recent files
            obj.redrawFileMenu();
            
        end %function
        
        
        function addRecentSessionPath(obj,filePaths)
            
            filePaths = string(filePaths);
            
            % Get the recent paths
            recentSessionPath = obj.getPreference('RecentSessionPaths',string.empty(0,1));
            recentSessionPath = string(recentSessionPath);
            
            % If this file is already in the list, remove it for reordering
            idxRemove = ismember(recentSessionPath, filePaths);
            recentSessionPath(idxRemove) = [];
            
            % Add the file to the top of the list
            if isempty(recentSessionPath)
                recentSessionPath = filePaths;
            else
                recentSessionPath = vertcat(filePaths, recentSessionPath);
            end
            
            % Crop the list to 8 entries
            recentSessionPath(9:end) = [];
            
            % Store the updated paths
            obj.setPreference('RecentSessionPaths',recentSessionPath);
            
            % Redraw the menu items
            obj.redrawFileMenu();
            
        end %function
        
    end %Protected methods
    
    
    
    %% Get/Set methods
    methods
        
        
        function value = get.SessionName(obj)
            if isempty(obj.SessionPath)
                value = "untitled";
            elseif verLessThan('matlab','9.3')
                [~,name,ext] = cellfun(@(x)fileparts(x),cellstr(obj.SessionPath),'uni',0);
                value = string(strcat(name, ext));
            else
                [~,name,ext] = arrayfun(@(x)fileparts(x),obj.SessionPath);
                value = strcat(name, ext);
            end
        end %function
        
        function set.IsDirty(obj,value)
            obj.IsDirty = value;
            obj.redrawTitle();
            obj.redrawFileMenu();
        end
        
    end %methods
    
end % classdef
