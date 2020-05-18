function [fileName, cdata, srcFileName] = createThumbnail(srcFileName,thumbSize)
% CreateThumbnail Creates a thumbnail image for an image file
% -------------------------------------------------------------------------
% 
% [fileName, cdata, srcFileName] = createThumbnail(srcFileName,thumbSize)
% creates a thumbnail for the given image file srcFileName with the square
% pixel size thumbSize.
%

%   Copyright 2005-2019 The MathWorks Inc.
%   $Revision: 324 $
%   $Date: 2019-04-23 08:05:17 -0400 (Tue, 23 Apr 2019) $

% Verify inputs
if nargin<2
    thumbSize = 200;
end

% Verify the file exists
fInfo = dir( srcFileName );
if ~isscalar( fInfo )
    warning( 'Unable to scan file: %s', srcFileName );
    fileName = '';
    cdata(thumbSize, thumbSize, 3) = uint8(0);
    return
end

% Load the full image.
[p,f,e] = fileparts( srcFileName ); %#ok<ASGLU>

% We will try a variety of readers, but first let's try DICOM. We have
% to handle the fact that this may error, so place inside a try. We
% don't need a catch.
isdcm = false;
try %#ok<TRYNC>
    isdcm = isdicom( srcFileName );
end
if isdcm
    % Treat as DICOM. Thanks to Matt Whitaker for this bit!
    header = dicominfo(srcFileName);
    [cdata,map] = squeeze(dicomread(header)); %squeeze out 4D
    if ndims(cdata) == 3
        cdata = cdata(:,:,1);
    end %if
    if isempty( cdata )
        cdata = zeros( thumbSize );
    else
        cdata = mat2gray(cdata); %the raw cdata can be in all sorts of formats
    end
    
elseif any(strcmpi(e,{'.MPG','.MPEG','.MP4','.AVI'}))
    % Treat as video
    mmr = VideoReader( srcFileName );
    cdata = mmr.readFrame();
    map = [];
    
else
    % Treat as standard image
    info = imfinfo(srcFileName);
    [cdata,map] = imread( srcFileName );
    
    % Review info
    if ~isempty(info)
        
        % Check for an orientation flag in Exif
        if isfield(info,'Orientation')
            % Rotate/flip if called for in Exif
            cdata = iRotateFlip( cdata, info(1).Orientation );
        end
        
    end %if ~isempty(info)
    
    % Check special cases
    if islogical(cdata)
        % Logical bits must be replaced with 8 bit
        cdata = double(cdata);
        cdata = repmat(cdata,1,1,3);
    elseif ~isempty(map)
        % Convert colormap
        cdata = ind2rgb(cdata,map);
    elseif ismatrix(cdata)
        % Check for B/W or Grayscale
        cdata = repmat(cdata,1,1,3);
    end
        
end %if isdcm

% Scale down and store for later
imgSize = max(size(cdata,1),size(cdata,2));
scale = thumbSize / imgSize;
cdata = imresize( cdata, scale );

% Make cdata square
imgSize = size( cdata );
if imgSize(1) < thumbSize
    cdata( thumbSize, thumbSize, end ) = 0;
    x0 = floor( (thumbSize - imgSize(1)) / 2 ) + 1;
    x1 = x0 + imgSize(1) - 1;
    cdata( x0:x1, :, : ) = cdata( 1:imgSize(1), :, : );
    cdata( 1:(x0-1) , :, : ) = 0;
elseif imgSize(2) < thumbSize
    cdata( thumbSize, thumbSize, end ) = 0;
    y0 = floor( (thumbSize - imgSize(2)) / 2 ) + 1;
    y1 = y0 + imgSize(2) - 1;
    cdata( :, y0:y1, : ) = cdata( :, 1:imgSize(2), : );
    cdata( :, 1:(y0-1) , : ) = 0;
end

% Store the thumbnail
fileName = sprintf('%s_thumb_%d.png', tempname, thumbSize);
if isempty(map)
    imwrite( cdata, fileName );
else
    imwrite( cdata, map, fileName );
end


%-------------------------------------------------------------------------%
function cdata = iRotateFlip( cdata, orientation )
% Rotate/flip per exif orientation flag
%http://jpegclub.org/exif_orientation.html

switch orientation
    case 2
        cdata = fliplr(cdata);
    case 3
        cdata = rot90(cdata, 2);
    case 4
        cdata = flipud(cdata);
    case 5
        cdata = rot90(cdata,-1);
        cdata = fliplr(cdata);
    case 6
        cdata = rot90(cdata,-1);
    case 7
        cdata = rot90(cdata, 1);
        cdata = fliplr(cdata);
    case 8
        cdata = rot90(cdata, 1);
    otherwise
        % leave as-is
end
