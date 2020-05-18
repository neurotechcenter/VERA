function table2clipboard(t)
% table2clipboard - place a table on the clipboard for pasting into Excel
% -------------------------------------------------------------------------
%
% Syntax:
%   uiw.utility.table2clipboard(t)
%
%       
%

%   Copyright 2017-2019 The MathWorks, Inc.
%
% Auth/Revision:
%   MathWorks Consulting
%   $Author: rjackey $
%   $Revision: 445 $  $Date: 2019-03-26 10:56:10 -0400 (Tue, 26 Mar 2019) $
% ---------------------------------------------------------------------

if ~isempty(t)
    
    data = table2array(t);
    names = t.Properties.VariableNames;
    
    numCol = size(data,2);
    namesFormat = [ strjoin( repmat({'%s'},1,numCol), '\t'), '\n' ];
    
    dataFormat = [ strjoin( repmat({'%f'},1,numCol), '\t'), '\n' ];
    namesStr = sprintf(namesFormat, names{:});
    dataStr = sprintf(dataFormat, data');
    
    str = [namesStr dataStr];
    clipboard('copy',str)
    
end
