function clearMessages(obj)
% clearMessages - clear the log messages in memory
% -------------------------------------------------------------------------
% Abstract: Clears the log messages currently stored in memory within the
% Logger object's buffer. Does not clear the log file.
%
% Syntax:
%           logObj.clearMessages();
%           clearMessages(logObj);
%
% Examples:
%           logObj = Logger.getInstance('MyLogger');
%           write(logObj,'warning','My warning message')
%           logObj.clearMessages();

%   Copyright 2018-2019 The MathWorks Inc.
%
% Auth/Revision:
%   MathWorks Consulting
%   $Author: rjackey $
%   $Revision: 324 $  $Date: 2019-04-23 08:05:17 -0400 (Tue, 23 Apr 2019) $
% ---------------------------------------------------------------------

obj.MessageBuffer(obj.BufferSize,1) = uiw.tool.LogMessage();
obj.BufferIndex = 0;
obj.BufferIsWrapped = false;