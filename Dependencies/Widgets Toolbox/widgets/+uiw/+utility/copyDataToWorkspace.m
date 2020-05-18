function copyDataToWorkspace(data,name)
% copyDataToWorkspace - copy the input data to a workspace variable
% -------------------------------------------------------------------------
%
% Syntax:
%   copyDataToWorkspace(data,name)
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

if nargin<2
    name = inputname(2);
end

% Make a valid variable name
name = matlab.lang.makeValidName(name);
varNames = evalin('base','who');
name = matlab.lang.makeUniqueStrings(name,varNames);

% Export
assignin('base',name,data)

% Display
fprintf('Data was exported to workspace variable ''%s''.\n',name);
