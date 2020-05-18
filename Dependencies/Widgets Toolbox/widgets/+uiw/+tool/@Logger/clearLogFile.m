function clearLogFile(obj)
% clearLogFile - clear the log messages in the log file
% -------------------------------------------------------------------------
% Abstract: Clears the log messages currently stored in the log file.
%
% Syntax:
%           logObj.clearLogFile();
%           clearLogFile(logObj);
%
% Examples:
%           logObj = Logger.getInstance('MyLogger');
%           write(logObj,'warning','My warning message')
%           logObj.clearLogFile();

%   Copyright 2018-2019 The MathWorks Inc.
%
% Auth/Revision:
%   MathWorks Consulting
%   $Author: rjackey $
%   $Revision: 324 $  $Date: 2019-04-23 08:05:17 -0400 (Tue, 23 Apr 2019) $
% ---------------------------------------------------------------------


% Close the log file
obj.closeLogFile();

% Open the log file again and overwrite
openLogFile(obj,obj.LogFile,'w');