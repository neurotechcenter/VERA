function col = interpretColor(str)
% interpretColor - Utility to interpret a color as an RGB triple
% 
% Interpret various forms of color input and return the equivalent RGB
% triple.
%
% Syntax:
%       rgb = uiw.interpretColor(col)
%
% Inputs:
%       col - the input color, which can be one of these formats:
%           * RGB triple of floating point numbers in the range 0 to 1
%           * RGB triple of UINT8 numbers in the range 0 to 255
%           * single character: 'r','g','b','m','y','c','k','w'
%           * string: one of 'red','green','blue','magenta','yellow',
%                     'cyan','black','white'
%           * HTML-style string (e.g. '#FF23E0')
%
% Outputs:
%       rgb - resulting RGB triple
%
% Examples:
%
%   >> uiw.interpretColor( 'r' )
%   ans =
%        1   0   0
%
%   >> uiw.interpretColor( 'cyan' )
%   ans =
%        0   1   1
%
%   >> uiw.interpretColor( '#FF23E0' )
%   ans =
%        1.0000    0.1373    0.8784
% 
%

%   Copyright 2005-2019 The MathWorks Inc.
%
% Auth/Revision:
%   MathWorks Consulting
%   $Author: rjackey $
%   $Revision: 324 $
%   $Date: 2019-04-23 08:05:17 -0400 (Tue, 23 Apr 2019) $
% ---------------------------------------------------------------------

if ischar( str ) || ( isscalar(str) && isstring(str) )
    str = strtrim(str);
    str = dequote(str);
    if str(1)=='#'
        % HTML-style string
        if numel(str)==4
            col = [hex2dec( str(2) ), hex2dec( str(3) ), hex2dec( str(4) )]/15;
        elseif numel(str)==7
            col = [hex2dec( str(2:3) ), hex2dec( str(4:5) ), hex2dec( str(6:7) )]/255;
        else
            error( 'uiw:utility:interpretColor:BadColor', 'Invalid HTML color %s', str );
        end
    elseif all( ismember( str, '1234567890.,; []' ) )
        % Try the '[0 0 1]' thing first
        col = str2num( str ); %#ok<ST2NM>
        if numel(col) == 3
            % Conversion worked, so just check for silly values
            col(col<0) = 0;
            col(col>1) = 1;
        end
    else
        % that didn't work, so try the name
        switch upper(str)
            case {'R','RED'}
                col = [1 0 0];
            case {'G','GREEN'}
                col = [0 1 0];
            case {'B','BLUE'}
                col = [0 0 1];
            case {'C','CYAN'}
                col = [0 1 1];
            case {'Y','YELLOW'}
                col = [1 1 0];
            case {'M','MAGENTA'}
                col = [1 0 1];
            case {'K','BLACK'}
                col = [0 0 0];
            case {'W','WHITE'}
                col = [1 1 1];
            case {'N','NONE'}
                col = [nan nan nan];
            otherwise
                % Failed
                error( 'uiw:utility:interpretColor:BadColor', 'Could not interpret color %s', num2str( str ) );
        end
    end
elseif isfloat(str) || isdouble(str)
    % Floating point, so should be a triple in range 0 to 1
    if size(str,2)==3
        col = double( str );
        col(col<0) = 0;
        col(col>1) = 1;
    else
        error( 'uiw:utility:interpretColor:BadColor', 'Could not interpret color %s', num2str( str ) );
    end
elseif isa(str,'uint8')
    % UINT8, so range is implicit
    if size(str,2)==3
        col = double( str )/255;
        col(col<0) = 0;
        col(col>1) = 1;
    else
        error( 'uiw:utility:interpretColor:BadColor', 'Could not interpret color %s', num2str( str ) );
    end
else
    error( 'uiw:utility:interpretColor:BadColor', 'Could not interpret color %s', num2str( str ) );
end


function str = dequote(str)
str(str=='''') = [];
str(str=='"') = [];
str(str=='[') = [];
str(str==']') = [];
