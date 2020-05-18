function statusOk = openLogFile(obj,fileName,openType)
% openLogFile - open the log file for writing
% -------------------------------------------------------------------------

%   Copyright 2018-2019 The MathWorks Inc.
%
% Auth/Revision:
%   MathWorks Consulting
%   $Author: rjackey $
%   $Revision: 324 $  $Date: 2019-04-23 08:05:17 -0400 (Tue, 23 Apr 2019) $
% ---------------------------------------------------------------------

% Was a file name passed in?
if nargin<2
    fileName = obj.LogFile;
end
if nargin<3
    openType = 'a';
end

% Is there a filename?
if isempty(fileName)
    
    statusOk = false;
    
else
    % Try to open the new log file
    try
        [fid, message] = fopen(fileName,openType);
        
        % If it failed to open, display a message
        if fid == -1
            message = sprintf('Unable to open log file ''%s'' for writing: %s\n',...
                fileName, message);
            fid = [];
        end
        
    catch err
        % If another error occurred, display a message
        message = sprintf('Unable to set log file ''%s'':\n %s\n',...
            fileName, err.message);
        fid = [];
    end %try
    
    % Were there any errors?
    statusOk = isempty(message);
    if statusOk
        % Set the new file ID
        obj.FileId = fid;
    else
        warning('Logger:OpenLogFile',...
            'Unable to open log file ''%s''.\n',...
            fileName);
    end
    
end %if isempty(fileName)