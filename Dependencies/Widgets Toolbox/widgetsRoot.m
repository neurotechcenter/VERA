function out = widgetsRoot()
% widgetsRoot - Return root folder where +uiw widgets package resides
%

%   Copyright 2018-2019 The MathWorks Inc.
%
% Auth/Revision:
%   MathWorks Consulting
%   $Author: rjackey $
%   $Revision: 324 $  $Date: 2019-04-23 08:05:17 -0400 (Tue, 23 Apr 2019) $
% ---------------------------------------------------------------------

out = fileparts(mfilename('fullpath'));
