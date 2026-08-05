classdef ClassicHyperlinkAdapter < handle
    % ClassicHyperlinkAdapter - wraps a classic uicontrol('Style',
    % 'pushbutton') styled to look like a link, mimicking uihyperlink's
    % Text/URL/Tooltip interface so code written against uihyperlink needs
    % no changes beyond how the widget itself is constructed (uihyperlink(...)
    % -> ClassicHyperlinkAdapter(...)). A pushbutton (rather than a static
    % text control) is used deliberately for reliable click handling -
    % a plain-text/ButtonDownFcn version was tried and confirmed unreliable
    % (clicks stopped registering), so this is back to a pushbutton/Callback.
    %
    % Text auto-sizes the control's width to fit whatever's set (capped
    % at MaxWidth, if given) so the full text is always visible instead
    % of being clipped to a fixed box size.
    %
    % See ClassicListboxAdapter for why this exists (a real crash report
    % confirmed uifigure's underlying CEF renderer is broken in at least
    % one deployment environment).

    properties (Dependent)
        Text
        Tooltip
    end

    properties
        URL = ''
    end

    properties (SetAccess = private)
        Control  % a classic uicontrol('Style','pushbutton') handle
        MaxWidth % cap on the auto-sized Control width, in pixels (Inf = uncapped)
    end

    methods
        function obj = ClassicHyperlinkAdapter(parent, varargin)
            [maxWidth, uicontrolArgs] = ClassicHyperlinkAdapter.extractSpecialArgs(varargin);
            obj.MaxWidth = maxWidth;
            obj.Control = uicontrol(parent, 'Style', 'pushbutton', ...
                'ForegroundColor', [0 0 0.9], 'HorizontalAlignment', 'left', uicontrolArgs{:});
            obj.Control.Callback = @(~,~) obj.handleClick();
        end

        function v = get.Text(obj)
            v = obj.Control.String;
        end

        function set.Text(obj, v)
            obj.Control.String = v;
            % Shrink-or-grow the control to exactly fit v (up to
            % MaxWidth), so the full text is always visible rather than
            % silently truncated by a fixed-width box - Extent gives the
            % pixel size the current String actually needs to render.
            ext = get(obj.Control, 'Extent');
            pos = get(obj.Control, 'Position');
            pos(3) = min(ext(3), obj.MaxWidth);
            set(obj.Control, 'Position', pos);
        end

        function v = get.Tooltip(obj)
            v = obj.Control.TooltipString;
        end

        function set.Tooltip(obj, v)
            obj.Control.TooltipString = v;
        end
    end

    methods (Access = private)
        function handleClick(obj)
            if ~isempty(obj.URL)
                web(obj.URL, '-browser');
            end
        end
    end

    methods (Static, Access = private)
        function [maxWidth, remaining] = extractSpecialArgs(args)
            % Pulls the 'MaxWidth' name-value pair out of a varargin list
            % (not a real uicontrol property, so forwarding it unfiltered
            % would error) and returns whatever's left to pass straight
            % through to uicontrol().
            maxWidth  = Inf;
            remaining = {};
            i = 1;
            while i <= numel(args)
                key = args{i};
                if ischar(key) && i < numel(args) && strcmpi(key, 'MaxWidth')
                    maxWidth = args{i+1};
                    i = i + 2;
                else
                    remaining(end+1) = {key}; %#ok<AGROW>
                    i = i + 1;
                end
            end
        end
    end
end
