classdef About < uiw.abstract.BaseDialog
    % About - An About dialog
    % ---------------------------------------------------------------------
    % Create an About dialog
    %
    % Syntax:
    %         d = uiw.dialog.About('Property','Value',...)
    %
    % Examples:
    %
    %         logoFcn = @()imread('mathworks_consulting_banner.png','BackgroundColor', [1 1 1]);
    %         logoBanner = uiw.utility.loadIcon(logoFcn);
    %
    %         d = uiw.dialog.About(...
    %             'Name', 'My App',...
    %             'Version','0.0.1',...
    %             'Date', 'May 5, 2018',...
    %             'Timeout', 10,...
    %             'CustomText', 'This is my favorite app.',...
    %             'ContactInfo', 'For support call 555-1234 or support@myapp.com',...
    %             'LogoCData', logoBanner);
    %
    %         [Out,Action] = d.waitForOutput()
    %
    % Notes: 
    %   1. Timeout may be specified as the number of seconds before the dialog
    %   disappears, as in a splash screen.
    %
    %   2. If Position is provided, it does not override the fixed size of
    %   dialog, and it will be centered in the region indicated. This is
    %   useful to place the dialog in the center of an app, if you provide
    %   the app window's pixel position.

%   Copyright 2017-2019 The MathWorks Inc.
    %
    % Auth/Revision:
    %   MathWorks Consulting
    %   $Author: rjackey $
    %   $Revision: 324 $
    %   $Date: 2019-04-23 08:05:17 -0400 (Tue, 23 Apr 2019) $
    % ---------------------------------------------------------------------


    %% Public properties
    properties (AbortSet, Dependent)
        Name char %Name of the app
        Version char %Version of the app
        Date char %Release date of this version
        CustomText char %Custom text to display
        ContactInfo string %Contact info for support (may be multiline string)
        LogoCData {mustBeNumeric} %CData for the logo/banner to display (450x45 pixels)
    end
    
    properties
        Timeout double = 0; %Timeout before the dialog disappears in seconds
    end


    %% Constructor / Destructor
    methods

        function obj = About(varargin)    
            
            % Call superclass constructor
            obj = obj@uiw.abstract.BaseDialog(...
                'Padding',20,...
                'Spacing',6,...
                'DialogSize',[466, 400],...
                'ShowOk',false,...
                'ShowApply',false,...
                'ShowCancel',false,...
                'Visible','off',...
                'BackgroundColor',[1 1 1]);
            

            % Create the base graphics
            obj.create();
            
            % Defaults
            obj.ContactInfo = {
                'MathWorks Consulting    ·    3 Apple Hill Drive    ·    Natick, MA 01760-2098'
                'consulting@mathworks.com    ·    +1 (508) 647-7000'};
            obj.LogoCData = uiw.utility.loadIcon(@()imread('mathworks_consulting_banner.png', 'BackgroundColor', [1 1 1]));
            
            % Populate public properties from P-V input pairs
            [remaningArgs,visibleIn] = obj.removeArg('Visible', varargin{:});
            [remaningArgs,appPos] = obj.removeArg('Position', remaningArgs{:});
            obj.assignPVPairs(remaningArgs{:});

            % Assign the construction flag
            obj.IsConstructed = true;

            % Redraw the dialog
            obj.onResized();
            obj.redraw();
            obj.onStyleChanged();
            
            % Center the dialog about the position, if specified
            drawnow %Ensure it's finished before moving
            if isempty(appPos)
                movegui(obj.Figure,'center');
            else
                pos = obj.Position;
                newPosXY = appPos(1:2) + (appPos(3:4) - pos(3:4))/2;
                obj.Position(1:2) = newPosXY;          
            end
            
            % Now, set the visibility
            if isempty(visibleIn)
                obj.Visible = 'on';
            else
                obj.Visible = visibleIn;
            end
            
            % Ensure it displays right away
            drawnow
            
            % If a timeout is specified (e.g. for splash screen), apply it
            if obj.Timeout > 0
                t = timer(...
                    'BusyMode','queue',...
                    'StartDelay',obj.Timeout,...
                    'TimerFcn',@(h,e)onDelete(obj),...
                    'ObjectVisibility','off');
                t.StopFcn = @(h,e)delete(t);
                start(t);
            end
            
            function onDelete(obj)
               if isvalid(obj) && strcmp(obj.Figure.BeingDeleted,'off')
                  delete(obj); 
               end
            end

        end % constructor

    end %methods - constructor/destructor



    %% Protected methods
    methods (Access=protected)

        function create(obj)
            
            % Name
            obj.h.Name = uicontrol(...
                'Parent',obj.hBasePanel,...
                'BackgroundColor','white',...
                'FontSize',20,...
                'FontWeight','bold',...
                'Units','pixels',...
                'String','Name',...
                'Style','text');
            
            % Version
            obj.h.Version = uicontrol(...
                'Parent',obj.hBasePanel,...
                'BackgroundColor','white',...
                'FontSize',12,...
                'HorizontalAlignment','right',...
                'Units','pixels',...
                'String','Version ',...
                'Style','text');
            
            % Date
            obj.h.Date = uicontrol(...
                'Parent',obj.hBasePanel,...
                'BackgroundColor','white',...
                'FontSize',12,...
                'HorizontalAlignment','left',...
                'Units','pixels',...
                'String','Date',...
                'Style','text');
            
            % Custom Text
            obj.h.CustomText = uicontrol(...
                'Parent',obj.hBasePanel,...
                'BackgroundColor','white',...
                'FontSize',8,...
                'HorizontalAlignment','left',...
                'Units','pixels',...
                'Max',2,...
                'String','',...
                'Style','text');
            
            % Contact Info
            obj.h.ContactInfo = uicontrol(...
                'Parent',obj.hBasePanel,...
                'BackgroundColor','white',...
                'FontSize',8,...
                'HorizontalAlignment','center',...
                'Units','pixels',...
                'Max',2,...
                'String','',...
                'Style','text');
            
            % Logo
            obj.h.ImageAxes = axes(...
                'Parent',obj.hBasePanel,...
                'DataAspectRatio',[1 1 1],...
                'Visible','off',...
                'YDir','reverse',...
                'Units','pixels');
            obj.h.Image = image(...
                'Parent',obj.h.ImageAxes,...
                'CData',ones(45,450,3));
            axis(obj.h.ImageAxes,'image') %sets to data limits
            

        end %function create

        
        function redraw(obj)
            % Ensure the construction is complete
            if obj.IsConstructed
                
                obj.h.Name.String = obj.Name;
                obj.h.Version.String = ['Version ' obj.Version];
                obj.h.Date.String = obj.Date;
                obj.h.CustomText.String = obj.CustomText;
                obj.h.ContactInfo.String = obj.ContactInfo;
                obj.h.Image.CData = obj.LogoCData;
                
            end %if obj.IsConstructed
        end %function redraw
        
        
        function onResized(obj,~,~)
            
            % Call superclass method
            obj.onResized@uiw.abstract.BaseDialog();
            
            % Ensure the construction is complete
            if obj.IsConstructed
                
                % What space do we have?
                [w,h] = obj.getInnerPixelSize();
                h = max(h,100);
                w = max(w,100);
                pad = obj.Padding;
                spc = obj.Spacing;
                
                % Calculate positions
                imgSz = [450 45];
                wFull = imgSz(1);
                wFig = wFull + 2*pad;
                xCenter = (wFig/2);
                wHalf = xCenter - pad - 0.5*spc;
                x0L = 1+pad;
                x0R = xCenter + 0.5*spc;
                
                yNext = 1+pad;
                
                % ContactInfo (full width)
                thisPos = [x0L yNext wFull 30];
                obj.h.ContactInfo.Position = thisPos;
                yNext = thisPos(2) + thisPos(4) + spc;
                
                % ImageAxes (full width)
                thisPos = [x0L yNext imgSz]; 
                obj.h.ImageAxes.Position = thisPos;
                yNext = thisPos(2) + thisPos(4) + spc;
                
                % Custom Text (full width)
                thisPos = [x0L yNext wFull 70];
                obj.h.CustomText.Position = thisPos;
                yNext = thisPos(2) + thisPos(4) + 2*spc;
                
                % Version (left side), Date (right side)
                thisPos = [x0L yNext wHalf 21];
                obj.h.Version.Position = thisPos;
                thisPos = [x0R yNext wHalf 21];
                obj.h.Date.Position = thisPos;
                yNext = thisPos(2) + thisPos(4) + spc;
                
                % Name
                thisPos = [x0L yNext wFull 35];
                obj.h.Name.Position = thisPos;
                yNext = thisPos(2) + thisPos(4) + pad;
                
                % Figure
                figSizeAdd = [wFig yNext] - [w h];
                obj.DialogSize = obj.DialogSize + figSizeAdd;

            end %if obj.IsConstructed
        end %function
        
        
        function onStyleChanged(obj,~)
            % Ensure the construction is complete
            if obj.IsConstructed
                
                % Set font names only, sizes are fixed
                hHasFontProps = findobj(obj.hBasePanel,'-property','FontName');
                set(hHasFontProps,'FontName',obj.FontName);
                
                % Set all uicontrols that have color props
                hHasFGColorProps = findobj(obj.hBasePanel,'-property','ForegroundColor');
                set(hHasFGColorProps,'ForegroundColor',obj.ForegroundColor);
                
                % Set background of the panel
                hHasBGColorProps = [obj.hBasePanel];
                set(hHasBGColorProps,'BackgroundColor',obj.BackgroundColor);
                
            end %if obj.IsConstructed
        end %function

    end % Protected methods



    %% Get/Set methods
    methods
        
        function value = get.Version(obj)
            value = strrep(obj.h.Version.String, 'Version ', '');
        end
        function set.Version(obj,value)
            obj.h.Version.String = ['Version ' value];
        end
        
        function value = get.Date(obj)
            value = obj.h.Date.String;
        end
        function set.Date(obj,value)
            obj.h.Date.String = value;
        end
        
        function value = get.CustomText(obj)
            value = obj.h.CustomText.String;
        end
        function set.CustomText(obj,value)
            obj.h.CustomText.String = value;
        end
        
        function value = get.ContactInfo(obj)
            value = obj.h.ContactInfo.String;
        end
        function set.ContactInfo(obj,value)
            obj.h.ContactInfo.String = value;
        end
        
        function value = get.LogoCData(obj)
            value = obj.h.Image.CData;
        end
        function set.LogoCData(obj,value)
            obj.h.Image.CData = value;
        end
        
        function value = get.Name(obj)
            value = obj.h.Name.String;
        end
        function set.Name(obj,value)
            obj.h.Name.String = value;
        end
        
        function set.Timeout(obj,value)
            validateattributes(value,{'numeric'},{'scalar','finite','nonnegative'});
            obj.Timeout = value;
        end

    end % Get/Set methods

end % classdef