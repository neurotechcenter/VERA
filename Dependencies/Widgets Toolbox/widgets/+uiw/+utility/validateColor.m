function value = validateColor(value)
% validateColor - validates a color string or [r,g,b] input
% -------------------------------------------------------------------------

%   Copyright 2017-2019 The MathWorks, Inc.
%
% Auth/Revision:
%   MathWorks Consulting
%   $Author: rjackey $
%   $Revision: 445 $  $Date: 2019-03-26 10:56:10 -0400 (Tue, 26 Mar 2019) $
% ---------------------------------------------------------------------

if ischar(value)
    validColors = {
        'none'
        'blue'
        'green'
        'red'
        'cyan'
        'magenta'
        'yellow'
        'black'
        'white'
        };
    value = validatestring(lower(value),validColors);
elseif isa(value,'uint8')
    validateattributes(value,{'uint8'},{'size',[1 3],'finite','>=',0,'<=',255});
else
    validateattributes(value,{'double'},{'size',[1 3],'finite','>=',0,'<=',1});
end
