classdef (Abstract, ConstructOnLoad) HasLogger < handle
    % HasLogger - Mixin for classes that contain a Logger
    % ---------------------------------------------------------------------
    %
    
%   Copyright 2017-2019 The MathWorks Inc.
    %
    % Auth/Revision:
    %   MathWorks Consulting
    %   $Author: rjackey $
    %   $Revision: 324 $  $Date: 2019-04-23 08:05:17 -0400 (Tue, 23 Apr 2019) $
    % ---------------------------------------------------------------------
    
    
    %% Properties
    properties (Abstract, Constant)
        LoggerName char %Name of the logger this class should use - MUST be set in subclass
    end
    
    properties (Transient, SetAccess=protected)
        Logger uiw.tool.Logger %Logger reference for this class
    end
    
    
    %% Constructor
    methods
        function obj = HasLogger(tf)
            % Construct an instance of this class
            
            % Connect the logger
            obj.Logger = uiw.tool.Logger(obj.LoggerName);
            
            % Start debugging if indicated
            if nargin
                obj.debug(tf);
            end
            
        end %constructor
    end %constructor
    
    
    %% Public Methods
    methods (Sealed)
        
        function debug(obj,tf)
            % Toggle debugging via Logger levels
            
            log = obj.getScalarLogger();
            if isempty(log)
                error('Logger is empty.');
            end
            
            if nargin<2 || tf
                log.DisplayLevel = uiw.enum.LogLevel.DEBUG;
                log.FileLevel = uiw.enum.LogLevel.DEBUG;
            else
                log.DisplayLevel = uiw.enum.LogLevel.WARNING;
                log.FileLevel = uiw.enum.LogLevel.WARNING;
            end
            
        end %function
        
        
        function setLogLevel(obj,displayLevel,fileLevel)
            
            log = obj.getScalarLogger();
            if isempty(log)
                return
            end
            
            % Check inputs
            narginchk(2,3)
            validateattributes(displayLevel,{'uiw.enum.LogLevel'},{'scalar'});
            
            % Set the DisplayLevel
            log.DisplayLevel = displayLevel;
            
            % Set the FileLevel, if provided
            if nargin>=3
                validateattributes(fileLevel,{'uiw.enum.LogLevel'},{'scalar'});
                log.FileLevel = uiw.enum.LogLevel.DEBUG;
            end
            
        end %function
        
        
        function notify(obj,eventName,eventData)
            % Override any event notification to enable logging the events
            
            log = obj.getScalarLogger();
            
            % If logging at least EVENT level, log this event first
            if ~isempty(log) && log.isLevelLogged('EVENT')
                
                % Log the event
                methodName = obj.getCallerName();
                if ~isempty(eventData) && isa(eventData,'uiw.event.EventData')
                    log.write('event','%s    (Interaction: %s    Source: %s)',...
                        eventName, eventData.Interaction, methodName);
                else
                    log.write('event','%s    (Source: %s)',...
                        eventName, methodName);
                end
                
            end %if ~log.isLevelLogged('EVENT')
            
            % Now call the real notify
            obj.notify@handle(eventName,eventData);
            
        end %function
        
        
        function logMethod(obj,eventData,varargin)
            % Log the caller method/function
            
            log = obj.getScalarLogger();
            if isempty(log)
                return
            end
            
            % If we're not logging at least this level, exit out now
            if ~( log.isLevelLogged('DEBUG') )
                return
            end
            
            % Get the display text for the called method
            methodName = obj.getCallerName();
            
            % What inputs were provided?
            if nargin<2 || isempty(eventData)
                % None - just show the method name
                
                log.write('DEBUG','%s',methodName);
                
            elseif isa(eventData,'uiw.event.EventData')
                
                log.write('CALLBACK','%s (EventName: %s    Interaction: %s)',...
                    methodName, eventData.EventName, eventData.Interaction);
                
            elseif isstruct(eventData) && isscalar(eventData) && isfield(eventData,'Interaction')
                % eventData is a structure with an Interaction field
                
                interaction = eventData.Interaction;
                log.write('CALLBACK','%s (Interaction: %s)',methodName, interaction);
                
            elseif isa(eventData,'event.EventData')
                
                if isempty(varargin)
                    customStr = '';
                else
                    customStr = sprintf(varargin{:});
                end
                log.write('CALLBACK','%s (EventName: %s) %s',...
                    methodName, eventData.EventName, customStr);
                
            elseif ischar(eventData) || ( isscalar(eventData) && isstring(eventData) )
                % eventData is just text to display
                
                eventStr = sprintf(eventData, varargin{:});
                log.write('DEBUG','%s (%s)',methodName, eventStr);
                
            else
                % No interpretable eventData to display
                
                log.write('DEBUG','%s',methodName);
                
            end %if
            
        end %function
        
        
        function msg = logError(obj,message,varargin)
            % Log an error
            
            log = obj.getScalarLogger();
            
            % Are we logging this level?
            if ~isempty(log) && log.isLevelLogged('ERROR')
                
                methodName = obj.getCallerName();
                if nargin<2 || isempty(message)
                    
                    msg = log.write('error', '[%s]', methodName);
                    
                else
                    if ~isempty(varargin) && isa(varargin{end},'MException')
                        
                        % Include the stack
                        %RAJ - this is cut/paste from Logger - improve later
                        errObj = varargin{end};
                        varargin(end) = [];
                        if ~isempty(errObj.stack)
                            msgInputs = [{errObj.stack.name};{errObj.stack.line}];
                            stackText = sprintf('\n\t\t> %s (line %d)',msgInputs{:});
                            message = [message newline errObj.message stackText];
                        end
                        
                    end %if nargin<2 || isempty(message
                    
                    msg = log.write('ERROR', ['[%s]: ' message], methodName, varargin{:});
                end
                
            end %if log.isLevelLogged('ERROR')
            
            
            % Always throw a dialog, regardless of logging settings
            msg.toDialog();
            
        end %function
        
        
        function msg = logWarning(obj,message,varargin)
            % Log a warning
            
            log = obj.getScalarLogger();
            if isempty(log)
                return
            end
            
            % Are we logging this level?
            if log.isLevelLogged('WARNING')
                
                methodName = obj.getCallerName();
                if nargin<2 || isempty(message)
                    msg = log.write('WARNING', '[%s]', methodName);
                else
                    msg = log.write('WARNING', ['[%s]: ' message], methodName, varargin{:});
                end
                
            end %if log.isLevelLogged('WARNING')
            
        end %function
        
        
        function logUnhandledEvent(obj,eventData,varargin)
            
            log = obj.getScalarLogger();
            if isempty(log)
                return
            end
            
            % Are we logging this level?
            if log.isLevelLogged('WARNING')
                
                methodName = obj.getCallerName();
                
                if nargin<2 || isempty(eventData)
                    
                    log.write('warning','%s\tUnhandled Event',methodName);
                    
                elseif isa(eventData,'uiw.event.EventData')
                    
                    log.write('warning','%s\tUnhandled Event [Type: %-13s]',...
                        methodName, eventData.EventType);
                    
                elseif ischar(eventData) || ( isscalar(eventData) && isstring(eventData) )
                    
                    log.write('warning','%s\tUnhandled Event: %s',methodName, eventData, varargin{:});
                    
                else
                    
                    log.write('warning','%s\tUnhandled Event',methodName);
                    
                end
                
            end %if log.isLevelLogged('WARNING')
            
        end %function
        
        
        function msg = logUnhandledControl(obj,eventData,varargin)
            
            log = obj.getScalarLogger();
            if isempty(log)
                return
            end
            
            % Are we logging this level?
            if log.isLevelLogged('WARNING')
                
                methodName = obj.getCallerName();
                
                if nargin<2 || isempty(eventData)
                    
                    msg = log.write('WARNING','%s\tUnhandled Control',methodName);
                    
                elseif isa(eventData,'matlab.ui.eventdata.ActionData') &&...
                        isprop(eventData,'Source') && ~isempty(eventData.Source)
                    
                    if isempty(eventData.Source.Tag)
                        msg = log.write('WARNING','[%s\tUnhandled Control: %s',methodName, class(eventData.Source));
                    else
                        msg = log.write('WARNING','%s\tUnhandled Control: %s',methodName, eventData.Source.Tag);
                    end
                    
                elseif ischar(eventData) || ( isscalar(eventData) && isstring(eventData) )
                    
                    msg = log.write('WARNING','%s\tUnhandled Control: %s',methodName, eventData, varargin{:});
                    
                else
                    
                    msg = log.write('WARNING','%s\tUnhandled Control',methodName);
                    
                end
                
            end %if log.isLevelLogged('WARNING')
            
        end %function
        
    end %methods
    
    
    %% Private Methods
    methods (Access=private)
        
        function log = getScalarLogger(obj)
            
            if isempty(obj)
                error('Invalid logger.');
            else
                try
                    log = obj(1).Logger;
                catch
                    log = uiw.tool.Logger.empty(0);
                end
            end
            
        end %function
        
        function name = getCallerName(~)
            % Get the name and hyperlink to the calling function/method
            
            stack = dbstack(2,'-completenames');
            thisFile = stack(1).file;
            thisName = stack(1).name;
            thisLine = stack(1).line;
            pathPackageNames = regexp(thisFile, '\+(\w+)', 'tokens');
            pathClassName = regexp(thisFile, '@(\w+)', 'tokens', 'once');
            nameParts = regexp(thisName, '\w+', 'match');
            
            if isempty(nameParts)
                className = [pathClassName{:}];
                methodName = '';
            elseif isscalar(nameParts)
                className = [pathClassName{:}];
                methodName = nameParts{end};
            else
                className = strjoin(nameParts(1:end-1),'.');
                methodName = nameParts{end};
            end
            
            
            packagePath = strjoin([pathPackageNames{:}],'.');
            
            % What type of method is it?
            switch methodName
                
                case ''
                    % It's not a method??
                    
                    methodPath = '';
                    suffix = '';
                    
                case className
                    %It's a constructor
                    
                    methodPath = [packagePath '.' className '()'];
                    suffix = '(Constructor)';
                    
                case 'delete'
                    % It's a destructor
                    
                    methodPath = [packagePath '.' className '.delete()'];
                    suffix = '(Destructor)';
                    
                otherwise
                    % It's an ordinary method
                    
                    methodPath = [packagePath '.' className '.' methodName '()'];
                    suffix = '';
                    
            end %
            
            % Prepare a hyperlink to the location
            name = sprintf('<a href = "matlab: opentoline(''%s'',%d,0);">%s</a> %s',...
                thisFile, thisLine, methodPath, suffix);
            
        end %function
        
    end %methods
    
    
end % classdef