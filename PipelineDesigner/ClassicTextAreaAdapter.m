classdef ClassicTextAreaAdapter < handle
    % ClassicTextAreaAdapter - wraps a classic uicontrol('Style','edit')
    % in multiline mode to mimic uitextarea's Value/ValueChangedFcn/
    % Editable interface, so code written against uitextarea needs no
    % changes at any call site beyond how the widget itself is constructed
    % (uitextarea(...) -> ClassicTextAreaAdapter(...)).
    %
    % See ClassicListboxAdapter for why this exists (a real crash report
    % confirmed uifigure's underlying CEF renderer is broken in at least
    % one deployment environment).

    properties (Dependent)
        Value
        Editable
    end

    properties
        ValueChangedFcn = []
    end

    properties (SetAccess = private)
        Control % a classic uicontrol('Style','edit') handle
    end

    methods
        function obj = ClassicTextAreaAdapter(parent, varargin)
            [initValue, initEditable, initStyle, uicontrolArgs] = ClassicTextAreaAdapter.extractSpecialArgs(varargin);
            obj.Control = uicontrol(parent, 'Style', initStyle, 'Max', 2, 'Min', 0, ...
                'HorizontalAlignment', 'left', uicontrolArgs{:});
            obj.Control.Callback = @(~,~) obj.handleCallback();
            if ~isempty(initValue)
                obj.Value = initValue;
            end
            if ~isempty(initEditable)
                obj.Editable = initEditable;
            end
        end

        function v = get.Value(obj)
            % uitextarea.Value is documented as a cell array of lines -
            % match that regardless of whether the underlying uicontrol
            % currently holds a char row (single line) or cell array.
            v = obj.Control.String;
            if ischar(v)
                v = cellstr(v);
            end
        end

        function set.Value(obj, v)
            obj.Control.String = v;
        end

        function v = get.Editable(obj)
            if strcmp(obj.Control.Enable, 'inactive')
                v = 'off';
            else
                v = 'on';
            end
        end

        function set.Editable(obj, v)
            if strcmpi(v, 'off')
                obj.Control.Enable = 'inactive'; % read-only but not greyed out, matching uitextarea's Editable=off look
            else
                obj.Control.Enable = 'on';
            end
        end
    end

    methods (Access = private)
        function handleCallback(obj)
            if ~isempty(obj.ValueChangedFcn)
                obj.ValueChangedFcn(obj, struct('Value', obj.Value));
            end
        end
    end

    methods (Static, Access = private)
        function [value, editable, style, remaining] = extractSpecialArgs(args)
            % Pulls 'Value'/'Editable'/'Style' name-value pairs out of a
            % varargin list (the first two aren't real uicontrol
            % properties, so forwarding them unfiltered would error; Style
            % is real but is intercepted so it can default to 'edit')
            % and returns whatever's left to pass straight through to
            % uicontrol().
            value     = '';
            editable  = '';
            style     = 'edit';
            remaining = {};
            i = 1;
            while i <= numel(args)
                key = args{i};
                if ischar(key) && i < numel(args) && strcmpi(key, 'Value')
                    value = args{i+1};
                    i = i + 2;
                elseif ischar(key) && i < numel(args) && strcmpi(key, 'Editable')
                    editable = args{i+1};
                    i = i + 2;
                elseif ischar(key) && i < numel(args) && strcmpi(key, 'Style')
                    style = args{i+1};
                    i = i + 2;
                else
                    remaining(end+1) = {key}; %#ok<AGROW>
                    i = i + 1;
                end
            end
        end
    end
end
