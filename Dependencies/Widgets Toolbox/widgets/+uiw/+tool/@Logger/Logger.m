classdef Logger < uiw.mixin.AssignPVPairs
    % Logger - Object definition for Logger
    % ---------------------------------------------------------------------
    % Abstract: A logger object to encapsulate logging and debugging
    %           messages for a MATLAB application.
    %
    % Syntax:
    %           logObj = Logger.getInstance();
    %
    %
    % Logger Properties:
    %
    %
    % Logger Events:
    %
    %     NewMessage - fires when a new messages arrives
    %
    %
    % Logger Methods:
    %
    %     clearMessages(obj) - Clears the log messages currently stored in
    %     the Logger object
    %
    %     clearLogFile(obj) - Clears the log messages currently stored in
    %     the log file
    %
    %     write(obj,level,messageText) - Writes a message to the log
    %
    %
    % Examples:
    %     logObj = uiw.tool.Logger('MyApp');
    %     logObj.write('WARNING','My warning message')
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
        NewMessage %Triggered when a new message is posted
    end
    
    
    %% Properties
    properties (SetAccess=protected)
        Name char %Unique name of this logger
    end
    
    properties (Dependent, SetAccess=protected)
        Messages %Array of log messages
        LastMessage %The most recent message
    end
    
    properties
        BufferSize (1,1) uint16 {mustBePositive,mustBeInteger,mustBeFinite} = 100; %Number of messages to buffer before wrapping
        FileLevel (1,1) uiw.enum.LogLevel = 'user' %Level of messages to save to the log file
        DisplayLevel (1,1) uiw.enum.LogLevel = 'user' %Level of messages to display in the command window
        LogFile char %The file name or path to the log file. If empty, nothing will be logged to file.
        Callback function_handle % Callback function handle to trigger when a log message is received
    end
    
    
    %% Internal properties
    properties (Transient, Access=private)
        MessageBuffer uiw.tool.LogMessage %Array of log messages
        BufferIndex (1,1) uint16 = 0 %Index to the most recent message within the buffer
        BufferIsWrapped (1,1) logical = false %Indicates whether the buffer has wrapped around
        FileId (1,1) double = -1 %File identifier for the log file
    end
    
    
    %% Methods in separate files with custom attributes
    methods (Access=private)
        statusOk = openLogFile(obj,fileName,openType)
        closeLogFile(obj)
    end
    
    
    
    %% Constructor / Destructor
    methods
        
        function obj = Logger(name,varargin)
            % Construct the logger
            
            % Was a name provided?
            if nargin<1 || isempty(name)
                [~,name] = fileparts(tempname);
            else
                validateattributes(name,{'char','string'},{'nonempty'});
                name = matlab.lang.makeValidName(name,'ReplacementStyle','delete');
            end
            
            % Track a singleton logger for each unique name
            persistent AllLoggers
            if isempty(AllLoggers)
                AllLoggers = uiw.tool.Logger.empty(0);
            else
                AllLoggers(~isvalid(AllLoggers)) = []; 
            end
            
            % Does this logger name already exist?
            isMatch = strcmp({AllLoggers.Name}, name);
            if sum(isMatch)>1
                    % Multiple matches! This should not happen.
                    
                    error('Multiple loggers found with same name: "%s".',obj.Name);
                    
            elseif any(isMatch)
                % Yes it exists - return the stored logger
                
                obj = AllLoggers(isMatch);
                
            else
                % No it does not exist - instantiate and store the logger
                
                % Generate a logger name and log filepath
                obj.Name = name;
                fileName = strcat('Log_',name,'.txt');
                if verLessThan('matlab','9.4')
                    obj.LogFile = fullfile(tempdir,char(fileName));
                else
                    obj.LogFile = fullfile(tempdir,fileName);
                end
                
                % Initialize the message buffer
                obj.clearMessages();
                
                % Add this logger to the persistent list
                AllLoggers(end+1) = obj;
                
            end %if isempty(AllLoggers) || ~any( strcmp({AllLoggers.Name}, obj.Name) )
            
            % Assign PV pairs to properties
            obj.assignPVPairs(varargin{:});
            
        end %function
        
        
        function delete(obj)
            % Destruct the Logger
            
            % If a log file was open, close it
            if ~isempty(obj.Name)
                obj.closeLogFile();
            end
            
        end %function
        
    end %methods
    
    
    
    %% Public Methods
    methods (Sealed, Hidden)
        
        function tf = isLevelLogged(obj,level)
            % Returns true if the specified level should be logged
            level = uiw.enum.LogLevel(level);
            tf = ~isempty(obj.FileLevel) && ~isempty(obj.DisplayLevel) && ...
                level > 0 && level <= max(obj.FileLevel, obj.DisplayLevel);
        end
        
        
        function tf = isLevelLoggedToFile(obj,level)
            % Returns true if the specified level should be logged to file
            level = uiw.enum.LogLevel(level);
            tf = level > 0 && level <= obj.FileLevel;
        end
        
        function tf = isLevelLoggedToDisplay(obj,level)
            % Returns true if the specified level should be logged to command window
            level = uiw.enum.LogLevel(level);
            tf = level > 0 && level <= obj.DisplayLevel;
        end
        
    end %public methods
    
    
    
    %% Private Methods
    methods (Sealed, Access = private)
        
        function callCallback( obj, varargin )
            % Call the function handle based callback
            
            if ~isempty(obj.Callback)
                obj.Callback(obj, varargin{:});
            end
            
        end %function
        
    end %protected methods
    
    
    
    %% Get/Set Methods
    methods
        
        function value = get.LastMessage(obj)
            if obj.BufferIndex > 0
                value = obj.MessageBuffer(obj.BufferIndex);
            else
                value = uiw.tool.LogMessage.empty(0,0);
            end
        end %function
        
        
        function value = get.Messages(obj)
            if obj.BufferIndex > 0
                value = obj.MessageBuffer( 1:obj.BufferIndex );
            elseif obj.BufferIsWrapped
                value = [
                    obj.MessageBuffer( (obj.BufferIndex + 1):end )
                    obj.MessageBuffer( 1:obj.BufferIndex ) ];
            else
                value = obj.MessageBuffer( 1:obj.BufferIndex );
            end
        end %function
        
        
        function set.BufferSize(obj,value)
            validateattributes(value,{'numeric'},...
                {'positive','integer','real','finite','<',2^16})
            obj.BufferSize = value;
            obj.clearMessages();
        end %function
        
        
        function set.LogFile(obj,value)
            obj.closeLogFile();
            statusOk = obj.openLogFile(value);
            if statusOk
                obj.LogFile = value; %Keep the new log file name
            else
                obj.openLogFile(); %If it failed to open, revert and don't change the file name
            end
        end %function
        
    end %methods
    
end %classdef