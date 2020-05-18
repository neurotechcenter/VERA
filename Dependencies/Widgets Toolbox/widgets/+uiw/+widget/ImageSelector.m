classdef ImageSelector < uiw.abstract.WidgetContainer & uiw.mixin.HasCallback
    % ImageSelector - A widget for selecting an image or media file
    % ---------------------------------------------------------------------
    % Create a widget that allows you to select an image by browsing
    % thumbnails.
    %
    % Syntax:
    %           w = uiw.widget.ImageSelector('Property','Value',...)
    %
    
%   Copyright 2005-2019 The MathWorks Inc.
    %
    % Auth/Revision:
    %   MathWorks Consulting
    %   $Author: rjackey $
    %   $Revision: 324 $
    %   $Date: 2019-04-23 08:05:17 -0400 (Tue, 23 Apr 2019) $
    % ---------------------------------------------------------------------
    
    
    %% Public properties
    properties (AbortSet)
        Value (1,1) double {mustBeNonnegative,mustBeInteger} = 0 %Index of selected image
        ImageFiles string %Array of full paths to image files to display
        Captions string %Array of image captions
        Orientation char {mustBeMember(Orientation,{'vertical','horizontal'})} = 'vertical' %Orientation
        SliderWidth (1,1) double = 16 %SliderWidth
        DefSize (1,1) double {mustBePositive,mustBeFinite}  = 200 %DefSize
        TimerPeriod (1,1) double {mustBePositive,mustBeFinite} = 0.2; %TimerPeriod
        ImagesPerBatch (1,1) double {mustBePositive,mustBeFinite} = 10; %ImagesPerBatch
        UseParallel(1,1) logical = false; %UseParallel
    end
    
    %% Calculated properties
    properties (Dependent = true)
        HighlightColor  % Color of the highlight around the selected image
    end % Calculated properties
    
    %% Private properties
    properties (SetAccess='private', GetAccess='private')
        IsLoaded (1,:) logical %indicates if each thumbnail is loaded from cache
        IsQueued (1,:) logical %indicates if each thumbnail is queued as a future
        WrappedCaptions string
        ThumbCacheFile char = '';
        ThumbCacheMap (1,1) struct = struct();
        ThumbTimer % Timer for background scanning of thumbnails
        ThumbFutures % parallel futures for thumbnail creation
        GridSize (1,2) double = [1 1]
        GridSizeFit (1,2) double = [1 1]
        GridPixels (1,2) double = [1 1]
        NeedSlider( 1,1) logical = true
    end % Private properties
    
    
    %% Constant properties
    properties (Constant, GetAccess='private')
        PngReadPath = fullfile(matlabroot,'toolbox','matlab','imagesci','private');
    end % Constant properties
    
    
    %% Constructor / Destructor
    methods
        
        function obj = ImageSelector(varargin)
            
            % Set modified defaults
            obj.FontSize = 8;
            obj.ForegroundColor = [0.8 0.8 0.8];
            
            % Create the base graphics
            obj.create();
            
            % Populate public properties from P-V input pairs
            obj.assignPVPairs(varargin{:});
            
            % Prep thumbnail caching
            obj.initiateThumbCache();
            
            % Assign the construction flag
            obj.IsConstructed = true;
            
            % Redraw the widget
            obj.onResized();
            obj.onEnableChanged();
            %obj.redraw(); %called by onResized
            obj.onStyleChanged();
            
            % Start timer to update thumbnails
            start(obj.ThumbTimer);
            
        end % constructor
        
        
        function delete(obj)
            % Destroy the ThumbTimer
            if ~isempty(obj.ThumbTimer) && isvalid(obj.ThumbTimer)
                stop(obj.ThumbTimer);
                delete(obj.ThumbTimer);
            end
            
            % Store the thumbnail map cache file
            thumbMap = obj.ThumbCacheMap;
            save( obj.ThumbCacheFile, '-struct', 'thumbMap' );
        end
        
    end %constructor/destructor methods
    
    
    %% Public methods
    methods
        
        function scrollToValue( obj, value )
            % Move the viewed area to ensure a given value is in view
            narginchk( 2, 2 ) ;
            N = numel( obj.ImageFiles );
            if ~isscalar( value ) ...
                    || value<1 || value > N
                error( 'uiw:widget:ImageSelector:BadValue', 'scrollToValue requires a valid value to be specified.' );
            end
            
            imgspacing = obj.DefSize + obj.Spacing;
            SliderMax = obj.h.Slider.Max;
            if strcmpi( get( obj.h.Slider, 'Enable' ), 'on' ) && N > 0
                if strcmpi( obj.Orientation, 'vertical' )
                    SliderValue = SliderMax - floor(value / obj.GridSizeFit(2) - 1) * imgspacing;
                else
                    SliderValue = floor(value / obj.GridSizeFit(1) - 1) * imgspacing;
                end
                % Keep value in range
                SliderValue = min( max(0,SliderValue), SliderMax);
                set(obj.h.Slider,'Value',SliderValue);
                obj.redraw();
            end
        end % scrollToValue
        
    end % Private methods
    
    
    
    
    %% Protected methods
    methods (Access=protected)
        
        function initiateThumbCache(obj)
            
            % Define the thumbnail cache
            filename = sprintf('ImageSelectorThumbnails_%d.mat',obj.DefSize);
            obj.ThumbCacheFile = fullfile( tempdir(), filename );
            
            % Grab the thumbnail map cache file, if one exists
            MakeNewMap = true;
            if exist( obj.ThumbCacheFile, 'file' ) == 2
                thumbMap = load( obj.ThumbCacheFile );
                if isstruct(thumbMap) &&...
                        isfield(thumbMap,'ThumbFile') && isa(thumbMap.ThumbFile,'containers.Map') &&...
                        isfield(thumbMap,'Size') && isa(thumbMap.Size,'containers.Map') &&...
                        isfield(thumbMap,'Date') && isa(thumbMap.Size,'containers.Map')
                    obj.ThumbCacheMap = thumbMap;
                    MakeNewMap = false;
                end
            end
            if MakeNewMap
                obj.ThumbCacheMap = struct(...
                    'ThumbFile', containers.Map('KeyType','char','ValueType','char'),...
                    'Date', containers.Map('KeyType','char','ValueType','double'),...
                    'Size', containers.Map('KeyType','char','ValueType','double') );
            end
            
            % Create the thumbnail timer, which scans for thumbnails as a
            % periodic background task
            obj.ThumbTimer = timer(...
                'Name', 'ImageSelectorThumbnailUpdateTimer', ...
                'ExecutionMode', 'fixedSpacing', ...
                'BusyMode', 'Drop', ...
                'TimerFcn', @(t,s)getThumbnails(obj,t,s), ...
                'ObjectVisibility', 'off', ...
                'StartDelay', obj.TimerPeriod, ...
                'Period', obj.TimerPeriod);
                %'ErrorFcn', @(h,e)assignin('base','errInfo',e),...
            
        end
        
        
        
        function create(obj)
            
            obj.Padding = 10;
            obj.Spacing = 10;
            
            % Create base graphics objects
            obj.h.Axes = axes( ...
                'Parent', obj.hBasePanel, ...
                'Clipping', 'off', ...
                'Units', 'pixels', ...
                'HitTest', 'off', ...
                'XTick', [], ...
                'YTick', [], ...
                'YDir', 'Reverse', ...
                'Box', 'off', ...
                'NextPlot','add',...
                'Visible', 'on', ...
                'Tag', 'uiw:widget:ImageSelector:Axes' );
            obj.h.DummyText = text( 0, 0, '', ...
                'Parent', obj.h.Axes, ...
                'Color', [0.9 0.9 1.0], ...
                'FontSize', 8, ...
                'HorizontalAlignment', 'Center', ...
                'VerticalAlignment', 'Top', ...
                'Interpreter', 'none', ...
                'Clipping', 'off', ...
                'Tag', 'uiw:widget:ImageSelector:DummyCaptionText', ...
                'Units','pixels',...
                'Visible', 'off');
            
            setappdata( obj.h.Axes, 'Enable', 'on' );
            obj.h.Slider = uicontrol( ...
                'Parent', obj.hBasePanel, ...
                'style', 'slider', ...
                'min', -1, 'max', 1, 'value', -1, ...
                'Callback', @(h,e)redraw(obj), ...
                'Tag', 'uiw:widget:ImageSelector:ScrollBar' );
            obj.h.Highlight(1) = line( 'Parent', obj.h.Axes, ...
                'XData', nan(1,5), ...
                'YData', nan(1,5), ...
                'Tag', 'uiw:widget:ImageSelector:Highlight', ...
                'Color', [1 1 0.3] );
            obj.h.Highlight(2) = line( 'Parent', obj.h.Axes, ...
                'XData', nan(1,5), ...
                'YData', nan(1,5), ...
                'Tag', 'uiw:widget:ImageSelector:Highlight', ...
                'Color', [0 0 0] );
            
            % Store the default highlight color
            setappdata( obj.h.Highlight(1), 'Color', [1 1 0.3] );
            
            % Create empty spots for these:
            obj.h.Images = gobjects(0);
            obj.h.Texts = gobjects(0);
            
        end %function create
        
        
        function redraw(obj)
            % Ensure the construction is complete
            if obj.IsConstructed
                
                % Get widget dimensions
                [w,h] = obj.getInnerPixelSize;
                %pad = obj.Padding;
                %spc = obj.Spacing;
                
                % Default to the starting coordinates
                xLim = [1 w];
                yLim = [1 h];
                
                % Adjust axes and slider
                if obj.NeedSlider
                    % We can only see part of the axes, so work out which part
                    if strcmpi( obj.Orientation, 'horizontal' )
                        xLim = xLim + obj.h.Slider.Value;
                    else
                        yLim = yLim + obj.h.Slider.Max - obj.h.Slider.Value;
                    end
                end
                set(obj.h.Axes,'XLim',xLim,'YLim',yLim);
                
                % Set highlight color to text label
                if strcmp(obj.Enable,'on') && obj.Value > 0
                    col = getappdata( obj.h.Highlight(1), 'Color' );
                    set( obj.h.Texts(obj.Value), 'Color', col );
                end
                
            end %if obj.IsConstructed
        end %function redraw
        
        
        function onResized(obj,~,~)
            % Ensure the construction is complete
            if obj.IsConstructed
                
                % Get widget dimensions
                [w,h] = obj.getInnerPixelSize;
                pad = obj.Padding;
                spc = obj.Spacing;
                
                % Get the size of the whole panel
                if strcmpi( obj.Orientation, 'horizontal' )
                    h = max(h - obj.SliderWidth, 100);
                else
                    w = max(w - obj.SliderWidth, 100);
                end
                
                % Set axes and slider position on the panel
                if strcmpi( obj.Orientation, 'horizontal' )
                    set( obj.h.Axes, 'Position', [1, obj.SliderWidth+1, w, h] )
                    set( obj.h.Slider, 'Position', [1 1 w obj.SliderWidth] );
                else %vertical
                    set( obj.h.Axes, 'Position', [1, 1, w, h] )
                    set( obj.h.Slider, 'Position', [w+1 1 obj.SliderWidth h] );
                end
                
                % Calculate the image space needs
                numimages = numel( obj.h.Images );
                imgsz = obj.DefSize; %Image size (square)
                imgspacing = obj.DefSize + spc; %Image spacing with border
                
                % How many rows and columns can we fit in the space?
                numColsFit = max( floor( (w-2*pad+spc) / imgspacing ) , 1 );
                numRowsFit = max( floor( (h-2*pad+spc) / imgspacing ) , 1 );
                
                % And how many are needed to fit the images
                if strcmpi( obj.Orientation, 'horizontal' )
                    numrows = numRowsFit;
                    numcols = ceil(numimages/numrows);
                else
                    numcols = numColsFit;
                    numrows = ceil(numimages/numcols);
                end
                
                % Do we need the slider?
                obj.NeedSlider = numimages > numColsFit*numRowsFit;
                set(obj.h.Slider,'Visible',uiw.utility.tf2onoff(obj.NeedSlider));
                
                % Get the starting locations for all images in the grid. There
                % may be more locations calculated than there are images
                x0 = repmat(imgspacing*(0:numcols-1)' + pad + 1, [1 numrows]);
                y0 = repmat(imgspacing*(0:numrows-1) + pad + 1, [numcols 1]);
                
                % Calculate the complete grid size
                obj.GridSize = [numrows numcols];
                obj.GridSizeFit = [numRowsFit numColsFit];
                obj.GridPixels = 2*pad + imgspacing*[numrows numcols] - spc;
                
                % Get the caption text positions, centered near lower image
                xt = x0 + imgsz/2;
                yt = y0 + imgsz*0.8;
                
                % Get the image data array (axes data values where image goes)
                xydata = (1:imgsz); %add to x0 or y0 for each image
                
                % Set slider step
                if obj.NeedSlider
                    SliderValue = obj.h.Slider.Value;
                    if strcmpi(obj.Orientation,'horizontal')
                        SliderMax = obj.GridPixels(2) - w;
                        SliderStep = imgspacing * [1 numColsFit] / SliderMax;
                        if SliderValue == -1
                            SliderValue = 0;
                        end
                    else
                        SliderMax = obj.GridPixels(1) - h;
                        SliderStep = imgspacing * [1 numRowsFit] / SliderMax;
                        if SliderValue == -1
                            SliderValue = SliderMax;
                        end
                    end
                    % Keep value in range
                    SliderValue = min( max(0,SliderValue), SliderMax);
                    set(obj.h.Slider,...
                        'Min',0,...
                        'Max',SliderMax,...
                        'SliderStep',SliderStep,...
                        'Value',SliderValue);
                end
                
                % Now position the images and texts
                for ii=1:numimages
                    
                    % Position the images
                    set( obj.h.Images(ii), ...
                        'XData', x0(ii) + xydata, ...
                        'YData', y0(ii) + xydata );
                    
                    % Position captions
                    set( obj.h.Texts(ii), ...
                        'String', obj.WrappedCaptions{ii}, ...
                        'Position', [xt(ii), yt(ii)] );
                    
                    % Position highlight
                    if ii == obj.Value
                        x = x0(ii)+[0 imgsz+1 imgsz+1 0 0];
                        y = y0(ii)+[0 0 imgsz+1 imgsz+1 0];
                        set( obj.h.Highlight(1), 'XData', x, 'YData', y );
                        x = x - [1 -1 -1  1 1];
                        y = y - [1  1 -1 -1 1];
                        set( obj.h.Highlight(2), 'XData', x, 'YData', y );
                        if strcmpi(obj.Enable,'on')
                            set( obj.h.Texts(ii), 'Color', obj.HighlightColor );
                        end
                    end
                    
                end %for ii=1:numimages
                
                % Set all text colors to the current setting. The highlighted
                % one will be updated afterwards.
                if strcmpi(obj.Enable,'on')
                    set( obj.h.Texts, 'Color', obj.ForegroundColor );
                end
                
                % Make sure the highlight is the highest thing on the HG stack
                ch = get( obj.h.Axes, 'Children' );
                IsHighlight = iIsEqualMember( ch, obj.h.Highlight );
                ch = [ch(IsHighlight) ; ch(~IsHighlight)];
                set( obj.h.Axes, 'Children', ch )
                
                % Now redraw to position the slider
                obj.redraw();
                
            end %if obj.IsConstructed
        end %function onResized(obj)
        
        
        function onEnableChanged(obj,~,~)
            % Ensure the construction is complete
            if obj.IsConstructed
                
                if strcmpi( obj.Enable, 'on' )
                    % Turn on any disabled widgets
                    set( obj.h.Slider, 'Enable', 'on' );
                    % For each image we get the CData from the appdata
                    for ii=1:numel( obj.h.Images )
                        cdata = getappdata( obj.h.Images(ii), 'CData' );
                        if ~isempty( cdata )
                            set( obj.h.Images(ii), 'CData', cdata );
                        end
                    end
                    % For texts, set to foreground color
                    newtextcol = obj.ForegroundColor;
                    for ii=1:numel( obj.h.Images )
                        set( obj.h.Texts(ii), 'Color', newtextcol );
                    end
                    % For highlight, set to value in appdata
                    col = getappdata( obj.h.Highlight(1), 'Color' );
                    set( obj.h.Highlight(1), 'Color', col );
                    if obj.Value > 0
                        set( obj.h.Texts(obj.Value), 'Color', col );
                    end
                else
                    % Turn off any widgets
                    set( obj.h.Slider, 'Enable', 'off' );
                    % For each image we put its CData into appdata then set to
                    % grey
                    bgcol = obj.BackgroundColor;
                    for ii=1:numel( obj.h.Images )
                        cdata = getappdata( obj.h.Images(ii), 'CData' );
                        % Move color towards background
                        cdata(:,:,1) = 0.5*bgcol(1) + 0.5*cdata(:,:,1);
                        cdata(:,:,2) = 0.5*bgcol(2) + 0.5*cdata(:,:,2);
                        cdata(:,:,3) = 0.5*bgcol(3) + 0.5*cdata(:,:,3);
                        set( obj.h.Images(ii), 'CData', cdata );
                    end
                    % For texts, move color towards background
                    newtextcol = 0.5*bgcol + 0.5*obj.ForegroundColor;
                    for ii=1:numel( obj.h.Images )
                        set( obj.h.Texts(ii), 'Color', newtextcol );
                    end
                    % For highlight, set towards background
                    hcol = getappdata( obj.h.Highlight(1), 'Color' );
                    set( obj.h.Highlight(1), 'Color', 0.5*bgcol+0.5*hcol );
                end
                
            end %if obj.IsConstructed
        end %function onEnableChanged(obj)
        
        
        function onStyleChanged(obj,~)
            % Handle updates to style and value validity changes
            if obj.IsConstructed
                
                % Call superclass methods
                onStyleChanged@uiw.abstract.WidgetContainer(obj);
                
                % Set additional background colors
                if ~isequal(obj.h.Axes.Color, obj.BackgroundColor)
                    obj.h.Axes.Color = obj.BackgroundColor;
                    obj.h.Axes.XColor = obj.BackgroundColor;
                    obj.h.Axes.YColor = obj.BackgroundColor;
                    %obj.getThumbnails();
                    %RAJ - need to redo thumbnails here, if we want a
                    %non-black background?
                    %set(obj.h.Images,'BackgroundColor',obj.BackgroundColor);
                end
                %set(obj.h.Texts,'BackgroundColor','none')
                set(obj.h.Texts,'BackgroundColor',[0 0 0])
                
                % Set additional foreground colors
                if ~isequal(obj.h.DummyText.Color, obj.ForegroundColor) && ~isempty(obj.h.Texts)
                    set(obj.h.DummyText,'Color',obj.ForegroundColor);
                    set(obj.h.Texts,'Color',obj.ForegroundColor);
                    %for ii=1:numel( obj.h.Texts )
                    %    set( obj.h.Texts(ii), 'Color', obj.ForegroundColor );
                    %end
                end
                
            end %if obj.IsConstructed
        end %function
        
        
        function onClicked( obj, src, evt ) %#ok<INUSD>
            if strcmp(obj.Enable,'on')
                % work out what was clicked
                idx = find( obj.h.Images == src );
                obj.Value = idx;
                thisFilePath = obj.ImageFiles{idx};
                [~,name,ext] = fileparts(thisFilePath);
                thisFileName = [name ext];
                evt = struct( ...
                    'Source', obj, ...
                    'Interaction','ImageSelected',...
                    'SelectedIndex',idx,...
                    'SelectedFileName',thisFileName,...
                    'SelectedFilePath',thisFilePath);
                obj.callCallback(evt);
            end
        end
        
        
        function getThumbnails( obj, thisTimer, ~ )
            
            % Check whether construction is complete and there are
            % remaining thumbnails to load
            if obj.IsConstructed && all(obj.IsLoaded)
                
                % We can stop the timer now - everything is loaded
                stop(thisTimer);
                
            elseif obj.IsConstructed
                
                % First, check for any PCT futures that completed
                if ~isempty(obj.ThumbFutures)
                    
                    IsComplete = strcmp({obj.ThumbFutures.State}, 'finished');
                    idxToFetch = find(IsComplete);
                    
                    for idx = 1:numel(idxToFetch)
                        
                        % Get the result
                        [thumbFileName, cdata, srcFileName] = obj.ThumbFutures(idxToFetch(idx)).fetchOutputs();
                        
                        % Match up the index of this image
                        idxThisImage = strcmp( obj.ImageFiles, srcFileName );
                        
                        % Update the thumbnail map
                        if ~isempty(thumbFileName)
                            obj.ThumbCacheMap.ThumbFile(srcFileName) = thumbFileName;
                            obj.IsLoaded(idxThisImage) = true;
                            obj.IsQueued(idxThisImage) = false;
                        end
                        
                        % Store original CData in appdata (for enable/disable)
                        setappdata( obj.h.Images(idxThisImage), 'CData', cdata );
                        
                        % If widget disabled, move color towards background
                        if strcmpi( obj.Enable, 'off' )
                            bgcol = obj.BackgroundColor;
                            cdata(:,:,1) = 0.5*bgcol(1) + 0.5*cdata(:,:,1);
                            cdata(:,:,2) = 0.5*bgcol(2) + 0.5*cdata(:,:,2);
                            cdata(:,:,3) = 0.5*bgcol(3) + 0.5*cdata(:,:,3);
                        end
                        
                        % Update the image cdata to display it
                        set( obj.h.Images(idxThisImage), 'CData', cdata );
                        
                    end %for idx = 1:numel(idxToFetch)
                    
                    % Remove these futures
                    delete( obj.ThumbFutures(IsComplete) );
                    obj.ThumbFutures(IsComplete) = [];
                    
                end %if ~isempty(obj.ThumbFutures)
                
                % Which next N number of thumbnails should be loaded?
                NumThisBatch = obj.ImagesPerBatch - sum(obj.IsQueued);
                if NumThisBatch <= 0
                    return
                end
                CheckToLoad = ~obj.IsLoaded & ~obj.IsQueued;
                idxToLoad = find(CheckToLoad, NumThisBatch);
                
                % Quickest way to load existing PNG thumbnails is to call the
                % mex file pngreadc directly. But we need to cd to the private
                % folder to be able to call it.
                currentDir = pwd;
                cd(obj.PngReadPath);
                
                % Are any of these thumbnails cached already?
                IsCached = false(size(idxToLoad));
                for idx = 1:numel(idxToLoad)
                    
                    ii = idxToLoad(idx);
                    srcFileName = obj.ImageFiles{ii};
                    
                    % Confirm date and size
                    fInfo = dir(srcFileName);
                    if isscalar(fInfo)
                        srcFileSize = fInfo.bytes;
                        srcFileDate = fInfo.datenum;
                    else
                        warning('Unable to scan thumbnail image: %s',srcFileName);
                        srcFileSize = 0;
                        srcFileDate = 0;
                    end
                    
                    % Is it cached?
                    IsCached(idx) = ( ...
                        obj.ThumbCacheMap.ThumbFile.isKey(srcFileName) &&...
                        exist(obj.ThumbCacheMap.ThumbFile(srcFileName),'file')==2 &&...
                        obj.ThumbCacheMap.Size(srcFileName) == srcFileSize &&...
                        obj.ThumbCacheMap.Date(srcFileName) == srcFileDate );
                    
                    % Depending on cache, we load or create it
                    if IsCached(idx)
                        
                        % Load an existing thumbnail
                        thumbname = obj.ThumbCacheMap.ThumbFile(obj.ImageFiles{ii});
                        
                        % Load the thumbnail cache. Use internal mex file pngreadc
                        % for speed, since we know the format.
                        cdata = pngreadc(thumbname, [], false);
                        cdata = permute(cdata, ndims(cdata):-1:1);
                        obj.IsLoaded(ii) = true;
                        
                        % Store original CData in appdata (for enable/disable)
                        setappdata( obj.h.Images(ii), 'CData', cdata );
                        
                        % If widget disabled, move color towards background
                        if strcmpi( obj.Enable, 'off' )
                            bgcol = obj.BackgroundColor;
                            cdata(:,:,1) = 0.5*bgcol(1) + 0.5*cdata(:,:,1);
                            cdata(:,:,2) = 0.5*bgcol(2) + 0.5*cdata(:,:,2);
                            cdata(:,:,3) = 0.5*bgcol(3) + 0.5*cdata(:,:,3);
                        end
                        
                        % Update the image cdata to display it
                        set( obj.h.Images(ii), 'CData', cdata );
                        
                    else
                        % If not cached yet, we will cache it but we also
                        % need to store the source file's size and date to
                        % check if it changes later
                        obj.ThumbCacheMap.Size(srcFileName) = srcFileSize;
                        obj.ThumbCacheMap.Date(srcFileName) = srcFileDate;
                        
                    end %if IsCached(idx)
                    
                end %for ii = idxToLoad
                
                % Navigate back to the user's current directory
                cd(currentDir);
                
                % Do we need to create thumbnails from this set?
                if any(~IsCached)
                    
                    % Which ones should be created?
                    idxToCreate = idxToLoad(~IsCached);
                    
                    % Can we use PCT?
                    if obj.UseParallel
                        
                        % Use parfeval to create thumbnails as background tasks
                        for idx = 1:numel(idxToCreate)
                            srcFileName = obj.ImageFiles{idxToCreate(idx)};
                            if isempty(obj.ThumbFutures)
                                obj.ThumbFutures = parfeval(@uiw.utility.createThumbnail, 3, srcFileName, obj.DefSize);
                            else
                                obj.ThumbFutures(end+1) = parfeval(@uiw.utility.createThumbnail, 3, srcFileName, obj.DefSize);
                            end
                        end
                        
                        % Mark them as queued in a future
                        obj.IsQueued(idxToCreate) = true;
                        
                    else
                        
                        % NO - create just one thumbnail now in this timer loop
                        idx = 1;
                        ii = idxToCreate(idx);
                        srcFileName = obj.ImageFiles{idxToCreate(idx)};
                        
                        % Create the thumbnail
                        try
                            [thumbFileName, cdata] = uiw.utility.createThumbnail( srcFileName, obj.DefSize );
                        catch err
                            obj.IsLoaded(ii) = true;
                            warning('ImageSelector:createThumbnailError',...
                                'Unable to create thumbnail for ''%s''. Error: %s',...
                                srcFileName, err.message);
                            return
                        end
                        
                        % Update the thumbnail map
                        if ~isempty(thumbFileName) && isscalar(fInfo)
                            obj.ThumbCacheMap.ThumbFile(srcFileName) = thumbFileName;
                            obj.IsLoaded(ii) = true;
                        end
                        
                        % Store original CData in appdata (for enable/disable)
                        setappdata( obj.h.Images(ii), 'CData', cdata );
                        
                        % If widget disabled, move color towards background
                        if strcmpi( obj.Enable, 'off' )
                            bgcol = obj.BackgroundColor;
                            cdata(:,:,1) = 0.5*bgcol(1) + 0.5*cdata(:,:,1);
                            cdata(:,:,2) = 0.5*bgcol(2) + 0.5*cdata(:,:,2);
                            cdata(:,:,3) = 0.5*bgcol(3) + 0.5*cdata(:,:,3);
                        end
                        
                        % Update the image cdata to display it
                        set( obj.h.Images(ii), 'CData', cdata );
                        
                    end %if obj.UseParallel
                    
                end %if any(~IsCached)
                
            end %if obj.IsConstructed && ~all(obj.IsLoaded)
            
        end % getThumbnails
        
    end % Protected methods
    
    
    
    
    
    %% Private methods
    methods (Access='private')
        
        function pRemoveWidgets(obj,toremove)
            % Delete all graphics related to an entry
            if islogical(toremove)
                toremove = find( toremove );
            end
            for ii=1:numel(toremove)
                if toremove(ii)<=numel( obj.h.Images ) ...
                        && ishandle( obj.h.Images(toremove(ii)) )
                    delete( obj.h.Images(toremove(ii)) );
                end
                if toremove(ii)<=numel( obj.h.Texts ) ...
                        && ishandle( obj.h.Texts(toremove(ii)) )
                    delete( obj.h.Texts(toremove(ii)) );
                end
            end
            % Clear the arrays
            obj.h.Images(toremove) = [];
            obj.h.Texts(toremove) = [];
        end % pRemoveWidgets
        
        
        
        function addImage( obj, filename, caption )
            %addImage: add a new image to the list
            %
            %   obj.addImage(FILENAME,CAPTION)
            if nargin<3
                caption = repmat("",size(filename));
            end
            numAdds = numel(filename);
            
            % For blank thumbnails
            cdata(obj.DefSize, obj.DefSize, 3) = uint8(0);
            
            % Note the new indices that will need thumbnails
            idxThumbnails = numel(obj.h.Images) + (1:numAdds);
            
            % Get the state of files and captions
            imageFiles = obj.ImageFiles;
            captions = obj.Captions;
            
            % Append items to lists, and create the UI components
            for ii=1:numAdds
                
                % Get the index of the next image
                idx = idxThumbnails(ii);
                
                % Append the image and caption to the list, if not already
                % done
                if numel(imageFiles)<idx || isempty(imageFiles{idx})
                    imageFiles{idx} = filename{ii};
                end
                if numel(captions)<idx || isempty(captions{idx})
                    captions{idx} = caption{ii};
                end
                
                % Mark the image as not cached or queued yet
                obj.IsLoaded(idx) = false;
                obj.IsQueued(idx) = false;
                
                % Create the components for displaying the image
                if numel(obj.h.Images)<idx || ~ishandle(obj.h.Images(idx))
                    
                    % Create the UI components
                    obj.h.Images(idx) = image( nan, ...
                        'Parent', obj.h.Axes, ...
                        'CData', cdata, ...
                        'Tag', 'uiw:widget:ImageSelector:Image', ...
                        'UIContextMenu', obj.UIContextMenu, ...
                        'ButtonDownFcn', @obj.onClicked );
                    obj.h.Texts(idx) = text( 0, 0, cellstr(caption), ...
                        'Parent', obj.h.Axes, ...
                        'HorizontalAlignment', 'Center', ...
                        'VerticalAlignment', 'Top', ...
                        'BackgroundColor','none',...
                        'Interpreter', 'none', ...
                        'Clipping', 'on', ...
                        'UIContextMenu', obj.UIContextMenu, ...
                        'Tag', 'uiw:widget:ImageSelector:CaptionText' );
                    
                    % Store original CData in appdata (for enable/disable)
                    setappdata( obj.h.Images(idx), 'CData', cdata );
                    
                end %if numel(obj.h.Images)<idx || ~ishandle(obj.h.Images(idx))
                
            end %for ii=1:numAdds
            
            % Set the state of files and captions
            obj.ImageFiles = imageFiles;
            obj.Captions = captions;
            
            % Redo the sizing
            obj.onResized();
            
            % Start timer to update thumbnails
            if obj.IsConstructed
                IsTimerRunning = strcmpi(obj.ThumbTimer.Running, 'on');
                if ~IsTimerRunning
                    start(obj.ThumbTimer);
                end
            end
            
        end % addImage
        
        
        function obj = clearImages( obj, filenames )
            %clearImages: remove one or more images from the list
            %
            %   THIS = CLEARICONS(THIS) removes all icons from the list
            %
            %   THIS = CLEARICONS(THIS,FILENAMES) removes the specified icons from the
            %   list, where FILENAMES is a string or a cell array of strings.
            if nargin<2
                filenames = obj.ImageFiles;
            else
                if ischar(filenames)
                    filenames = {filenames};
                end
            end
            
            % Stop the timer
            IsTimerRunning = false;
            if obj.IsConstructed
                IsTimerRunning = strcmpi(obj.ThumbTimer.Running, 'on');
                if IsTimerRunning
                    stop(obj.ThumbTimer);
                    wait(obj.ThumbTimer);
                end
            end
            
            % Find those on our list that are specified
            obj.ImageFiles = setdiff( obj.ImageFiles, filenames );
            % set method for ImageFiles does cleanup
            
            % Update and redraw
            obj.onResized();
            
            % Restart timer to update thumbnails
            if obj.IsConstructed && IsTimerRunning
                start(obj.ThumbTimer);
            end
            
        end % clearImages
        
        
        function wrapCaptions(obj,newcappos)
            
            numcaps = numel(newcappos);
            obj.WrappedCaptions = repmat("",1,numcaps);
            maxwidth = obj.DefSize - 20;
            for ii=1:numcaps
                if numel(newcappos{ii})>15
                    set(obj.h.DummyText, 'String', newcappos{ii});
                    extent = get( obj.h.DummyText, 'extent' );
                    ratio = extent(3)/maxwidth;
                    if ratio >= 1
                        cap = newcappos{ii};
                        rowlength = floor(numel(cap)/ratio) - 4;
                        cap1 = cap(1:rowlength);
                        if length(cap)>(2*rowlength)
                            cap2 = [cap(rowlength+1:2*rowlength-2),'...'];
                        else
                            cap2 = cap(rowlength+1:end);
                        end
                        obj.WrappedCaptions{ii} = [cap1,newline,cap2];
                    else
                        obj.WrappedCaptions{ii} = newcappos{ii};
                    end
                else
                    obj.WrappedCaptions{ii} = newcappos{ii};
                end
            end %for ii=1:numcaps
            
        end %wrapCaptions
        
    end % Private methods
    
    
    
    
    
    
    %% Data access methods
    methods
        function set.Value(obj,value)
            if value > numel(obj.ImageFiles) %#ok<MCSUP>
                value = 0;
            end
            if value < 1
                value = 0;
            end
            if ~isequal( obj.Value, value )
                obj.Value = value;
                obj.onResized();
            end
        end % set.Value
        
        function set.ImageFiles(obj,names)
            % Find those on our list that are no longer required
            
            % Which ones should be removed?
            toremove = ~iStrIsMember(obj.ImageFiles,names);
            
            obj.pRemoveWidgets( toremove );
            % Clear the arrays
            obj.ImageFiles(toremove) = [];
            obj.Captions(toremove) = []; %#ok<MCSUP>
            obj.IsLoaded(toremove) = []; %#ok<MCSUP>
            obj.IsQueued(toremove) = []; %#ok<MCSUP>
            
            % Now add the new ones
            toadd = ~iStrIsMember( names, obj.ImageFiles );
            obj.ImageFiles = horzcat(obj.ImageFiles, names(toadd));
            obj.addImage( names(toadd) );
            
        end % set.ImageFiles
        
        function set.Captions(obj,captions)
            % Change an existing caption
            wrapCaptions(obj,captions); %set wrapped captions
            obj.Captions = captions;
            obj.onResized();
        end % set.Captions
        
        function set.Orientation(obj,value)
            obj.Orientation = value;
            % Flip scrollbar value during toggle, or if setting to
            % Vertical if during construction
            if obj.IsConstructed || strcmpi(value,'vertical')
                set( obj.h.Slider, 'Value', 1 - get( obj.h.Slider, 'Value' ) );
            end
            obj.onResized();
        end % set.Orientation
        
        function set.SliderWidth(obj,value)
            validateattributes(value,{'numeric'},{'positive','integer','finite'});
            obj.SliderWidth = value;
            obj.onResized();
        end % set.SliderWidth
        
        function value = get.HighlightColor(obj)
            value = getappdata( obj.h.Highlight(1), 'Color' );
        end % get.HighlightColor
        
        function set.HighlightColor(obj,value)
            if strcmpi( obj.Enable, 'on' )
                set( obj.h.Highlight(1), 'Color', value );
            end
            % Store normal color in case it is disabled
            setappdata( obj.h.Highlight(1), 'Color', value );
        end % set.HighlightColor
        
    end % Data access methods
    
    
    
end % classdef





%% Now some helper functions

%-------------------------------------------------------------------------%
function tf = iStrIsMember( strsToLookFor, strSet )
% This is faster than ismember
n = numel(strsToLookFor);
tf = false(size(strsToLookFor));
for idx=1:n
    tf(idx) = any(strcmp(strsToLookFor{idx},strSet));
end
end %iStrIsMember

%-------------------------------------------------------------------------%
function tf = iIsEqualMember( itemsToLookFor, fullSet )
% This is faster than ismember
n = numel(itemsToLookFor);
tf = false(size(itemsToLookFor));
for idx=1:n
    tf(idx) = any(itemsToLookFor(idx) == fullSet);
end
end %iIsEqualMember
