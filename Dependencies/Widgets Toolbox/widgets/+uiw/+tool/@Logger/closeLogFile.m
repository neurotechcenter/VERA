function closeLogFile(obj)
% closeLogFile - close the log file for writing
% -------------------------------------------------------------------------

%   Copyright 2018-2019 The MathWorks Inc.
%
% Auth/Revision:
%   MathWorks Consulting
%   $Author: rjackey $
%   $Revision: 324 $  $Date: 2019-04-23 08:05:17 -0400 (Tue, 23 Apr 2019) $
% ---------------------------------------------------------------------


% If a log file was open, close it
if ~isempty(fopen(obj.FileId))
    if fclose(obj.FileId)
        warning('Logger:CloseLogFile',...
            'Unable to close log file ''%s''.\n',...
            obj.LogFile);
        return;
    end
end

% Return FileId to none
obj.FileId = -1;