classdef ClassicHyperlinkAdapter < handle
    % ClassicHyperlinkAdapter - wraps a classic uicontrol('Style',
    % 'pushbutton') styled to look like a link, mimicking uihyperlink's
    % Text/URL/Tooltip interface so code written against uihyperlink needs
    % no changes beyond how the widget itself is constructed (uihyperlink(...)
    % -> ClassicHyperlinkAdapter(...)). A pushbutton (rather than a static
    % text control) is used deliberately for reliable click handling -
    % classic static text's ButtonDownFcn is inconsistent across platforms.
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
        Control % a classic uicontrol('Style','pushbutton') handle
    end

    methods
        function obj = ClassicHyperlinkAdapter(parent, varargin)
            obj.Control = uicontrol(parent, 'Style', 'pushbutton', ...
                'ForegroundColor', [0 0 0.9], 'HorizontalAlignment', 'left', varargin{:});
            obj.Control.Callback = @(~,~) obj.handleClick();
        end

        function v = get.Text(obj)
            v = obj.Control.String;
        end

        function set.Text(obj, v)
            obj.Control.String = v;
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
end
