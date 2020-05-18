function varargout = write(obj,level,messageText,varargin)
% write - write a message to the log
% -------------------------------------------------------------------------
% Abstract: Adds a new message to the Logger, with the specified message
% level and text
%
% Syntax:
%       logObj.write(Level,MessageText,varargin)
%       write(logObj,Level,MessageText,varargin)
%
% Inputs:
%       logObj - Logger object
%       level - Message level string ('debug','warning',etc)
%       messageText - Message text to display
%       varargin - additional sprintf inputs
%
% Outputs:
%       newMessage - the resulting LogMessage
%
% Examples:
%           logObj = Logger.getInstance('MyLogger');
%           write(logObj,'warning','My warning message')

%   Copyright 2018-2019 The MathWorks Inc.
%
% Auth/Revision:
%   MathWorks Consulting
%   $Author: rjackey $
%   $Revision: 324 $  $Date: 2019-04-23 08:05:17 -0400 (Tue, 23 Apr 2019) $
% ---------------------------------------------------------------------

% Validate scalar logger
if ~isscalar(obj)
    warning('uiw:tool:Logger:WriteToNonScalarObject',...
        ['Attempted to write a log message to a nonscalar '...
        'Logger object, which is not supported.']);
    return
end

% Should we proceed?
level = uiw.enum.LogLevel(level);
if obj.isLevelLogged(level)
    
    % Format the message
    if isa(messageText,'MException')
        %RAJ - improve this later
        errObj = messageText; %Keep the mexception
        messageText = messageText.message;
        %messageText = errObj.getReport();
        
        % Include the stack
        if ~isempty(errObj.stack)
            msgInputs = [{errObj.stack.name};{errObj.stack.line}];
            stackText = sprintf('\n\t\t> %s (line %d)',msgInputs{:});
            messageText = [messageText stackText];
        end
        
    else
        % Process any additional inputs
        messageText = sprintf(messageText,varargin{:});
    end
    
    % Get the next position in the circular MessageBuffer
    obj.BufferIndex = obj.BufferIndex + 1;
    if obj.BufferIndex > obj.BufferSize
        obj.BufferIndex = 1;
        obj.BufferIsWrapped = true;
    end
    
    % Add the message to the buffer
    obj.MessageBuffer(obj.BufferIndex).Timestamp = datetime;
    obj.MessageBuffer(obj.BufferIndex).Level = level;
    obj.MessageBuffer(obj.BufferIndex).Message = messageText;
    newMessage = obj.MessageBuffer(obj.BufferIndex);
    
    % Prepare the displayed message
    thisMessage = sprintf('%s:\t%s', level, newMessage.Message);
    
    % Indent debug messages more
    if level == uiw.enum.LogLevel.DEBUG
        thisMessage = strcat(char(9), thisMessage);
    end
    
    % Log to display
    if obj.isLevelLoggedToDisplay(level)
        
        fprintf('\t%s Logger:  %s\n', obj.Name, thisMessage);
        
    end %if obj.isLevelLoggedToDisplay(level)
    
    % Log to file
    if obj.isLevelLoggedToFile(level)
        
        % Check that log file is open. If not, try to open it
        statusOk = ~isempty(fopen(obj.FileId)) || obj.openLogFile();
        
        if statusOk
            % Create a comma delimited message, followed by a
            % line terminator
            try
                fprintf(obj.FileId,'%s, %s\r\n',...
                    datestr(newMessage.Timestamp),... %current date & time
                    thisMessage); %message
            catch err
                warning('Logger:InvalidLogFile','Unable to write to the log file:\n%s',err.message);
            end
        else
            warning('Logger:InvalidLogFile','Unable to write to the log file');
        end %if statusOk
        
    end %if obj.isLevelLoggedToFile(level)
    
    % Set the output argument, if any
    if nargout
        varargout{1} = newMessage;
    end
    
    % Call the callback, if one exists
    obj.callCallback(newMessage);
    
    % Fire the event
    obj.notify('NewMessage',newMessage);
    
else
    if nargout
        varargout{1} = uiw.tool.LogMessage.empty(0,0);
    end
end %if obj.isLevelLogged(level)
