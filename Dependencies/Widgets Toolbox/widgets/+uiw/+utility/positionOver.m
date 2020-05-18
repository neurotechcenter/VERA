function varargout = positionOver(hFigOver,hFigUnder)
% positionOver - Reposition figure centered over another figure
% -------------------------------------------------------------------------

%   Copyright 2017-2019 The MathWorks, Inc.
%
% Auth/Revision:
%   MathWorks Consulting
%   $Author: rjackey $
%   $Revision: 445 $  $Date: 2019-03-26 10:56:10 -0400 (Tue, 26 Mar 2019) $
% ---------------------------------------------------------------------

% Get positions
figOverPosition = getpixelposition(hFigOver,true);
figUnderPos = getpixelposition(hFigUnder,true);

% Position the new figure at the center of the app
szFigUnder = figUnderPos([3 4]);
szFigOver = figOverPosition([3 4]);
offset = floor( (szFigUnder-szFigOver)/2 );
figOverPosition([1 2]) = figUnderPos([1 2]) + offset;

% Output args?
if nargout
    varargout{1} = figOverPosition;
else
    setpixelposition(hFigOver,figOverPosition);
end

