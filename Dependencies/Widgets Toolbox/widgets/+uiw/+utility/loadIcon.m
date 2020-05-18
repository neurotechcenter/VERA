function [cData, filePath] = loadIcon(imageFile,backgroundColor,varargin)
% loadIcon - Utility to load an icon file
% 
% Abstract: Finds an icon file in this toolbox resource folder, and returns
% the icon data
%
% Syntax:
%           [cData, filePath] = loadIcon(imageFileName,backgroundColor,'p1',v1,...)
%
% Inputs:
%           imageFile - file name of the image, or function handle to load 
%           backgroundColor - specify background color of loaded image
%           'p1',v1,... - additional parameters to imread
%
% Outputs:
%           cData - image data
%           filePath - path to the icon
%
% Examples:
%           none
%
% Notes: 
%   If the icon is a PNG file with transparency then
%   transparent pixels are set to NaN. If not, then any pixel that is pure
%   green is set to transparent (i.e. "green screen"). The resulting CDATA
%   is an RGB double array.
%
%   If bgcol is provided, attempt to merge partially transparent pixels
%   with the background.
%

%   Copyright 2018-2019 The MathWorks Inc.
%
% Auth/Revision:
%   MathWorks Consulting
%   $Author: rjackey $
%   $Revision: 324 $  $Date: 2019-04-23 08:05:17 -0400 (Tue, 23 Apr 2019) $
% ---------------------------------------------------------------------

% Validate inputs
narginchk( 1, inf );
validateattributes(imageFile,{'char','function_handle'},{'nonempty'});
if nargin < 2 || isempty(backgroundColor)
    backgroundColor = get( 0, 'DefaultUIControlBackgroundColor' );
end

% First try normally
icon_dir = fullfile( widgetsRoot, 'resource' );

% Was an image on path or a full path provided?
if isa(imageFile,'function_handle') && contains(char(imageFile),'imread')
    
    % This use case is because creating a function handle with imread to an
    % icon can trigger dependency analysis to find the image file:
    %   fcn = @()imread('add_24.png'); %would add the dependency
    [cData,map,alpha] = imageFile(varargin{:});
    
else
    if exist(imageFile,'file')
        % Yes - use it
        
        filePath = which(imageFile);
        
    elseif exist(fullfile(icon_dir, imageFile),'file')
        % No - but it was found in the resource folder
        
        filePath = fullfile( icon_dir, imageFile );
        
    else
        % Not found at all
        warning('uiw:utility:loadIcon:BadFile','file not found: ''%s''',imageFile);
        filePath = '';
    end
    
    % Load the image
    if isempty(filePath)
        cData = [];
        return
    else
        [cData,map,alpha] = imread( filePath, varargin{:} );
    end
    
end

    
% Was a map provided?
if ~isempty( map )
    cData = ind2rgb( cData, map );
end

% Convert to double before applying transparency
cData = convertToDouble( cData );

[rows,cols,~] = size( cData );
if ~isempty( alpha )
    alpha = convertToDouble( alpha );
    f = find( alpha==0 );
    if ~isempty( f )
        cData(f) = nan;
        cData(f + rows*cols) = nan;
        cData(f + 2*rows*cols) = nan;
    end
    
    % Now blend partial alphas
    f = find( alpha(:)>0 & alpha(:)<1 );
    %f = find( alpha(:)<1 );
    if ~isempty(f)
        cData(f) = cData(f).*alpha(f) + backgroundColor(1)*(1-alpha(f));
        cData(f + rows*cols) = cData(f + rows*cols).*alpha(f) + backgroundColor(2)*(1-alpha(f));
        cData(f + 2*rows*cols) = cData(f + 2*rows*cols).*alpha(f) + backgroundColor(3)*(1-alpha(f));
    end
    
else
    % Instead do a "green screen", treating anything pure-green as transparent
    f = find((cData(:,:,1)==0) & (cData(:,:,2)==1) & (cData(:,:,3)==0));
    cData(f) = nan;
    cData(f + rows*cols) = nan;
    cData(f + 2*rows*cols) = nan;
    
end


%-------------------------------------------------------------------------%
function cdata = convertToDouble( cdata )
% Convert an image to double precision in the range 0 to 1
switch lower( class( cdata ) )
    case 'double'
    % Do nothing
    case 'single'
        cdata = double( cdata );
    case 'logical'
        cdata = double( ~cdata );
    case 'uint8'
        cdata = double( cdata ) / 255;
    case 'uint16'
        cdata = double( cdata ) / 65535;
    case 'int8'
        cdata = ( double( cdata ) + 128 ) / 255;
    case 'int16'
        cdata = ( double( cdata ) + 32768 ) / 65535;
    otherwise
        error( 'uiw:utility:loadIcon:BadCData', 'Image type ''%s'' is not supported', class( cdata ) );
end