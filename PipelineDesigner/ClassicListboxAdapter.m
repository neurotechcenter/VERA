classdef ClassicListboxAdapter < handle
    % ClassicListboxAdapter - wraps a classic uicontrol('Style','listbox')
    % to mimic uilistbox's Items/ItemsData/Value/ValueChangedFcn interface
    % (including the ValueChanged event addlistener() can hook into), so
    % code written against uilistbox needs no changes at any call site
    % beyond how the widget itself is constructed (uilistbox(...) ->
    % ClassicListboxAdapter(...)).
    %
    % Written specifically to avoid uifigure/uilistbox, which depend on
    % MATLAB's CEF-based rendering engine (MATLABWindow/matlabwindowhelper)
    % - confirmed via a real crash report (EXC_BREAKPOINT/SIGTRAP inside
    % Chromium Embedded Framework's CrRendererMain, responsibleProc
    % "PipelineDesigner") to be broken in at least one real deployment
    % environment (a VM using Apple's Virtualization framework). Classic
    % uicontrol renders via Java Swing instead, with no CEF dependency -
    % same reasoning as AComponent.VERAMessageBox and MainGUI's own window.

    properties (Dependent)
        Items
        ItemsData
        Value
    end

    properties
        ValueChangedFcn = []
    end

    properties (SetAccess = private)
        Control % a classic uicontrol('Style','listbox') handle
    end

    properties (Access = private)
        pItemsData = {}
    end

    events
        ValueChanged
    end

    methods
        function obj = ClassicListboxAdapter(parent, varargin)
            [initItems, initItemsData, uicontrolArgs] = ClassicListboxAdapter.extractSpecialArgs(varargin);
            obj.Control = uicontrol(parent, 'Style', 'listbox', uicontrolArgs{:});
            obj.Control.Callback = @(~,~) obj.handleCallback();
            if ~isempty(initItems)
                obj.Items = initItems;
            end
            if ~isempty(initItemsData)
                obj.pItemsData = initItemsData;
            end
        end

        function v = get.Items(obj)
            v = cellstr(obj.Control.String);
        end

        function set.Items(obj, v)
            if isempty(v)
                v = {''};
            end
            obj.Control.String = v;
            if obj.Control.Value > numel(v) || obj.Control.Value < 1
                obj.Control.Value = 1;
            end
        end

        function v = get.ItemsData(obj)
            v = obj.pItemsData;
        end

        function set.ItemsData(obj, v)
            obj.pItemsData = v;
        end

        function v = get.Value(obj)
            idx   = obj.Control.Value;
            items = cellstr(obj.Control.String);
            if ~isempty(obj.pItemsData) && idx >= 1 && idx <= numel(obj.pItemsData)
                v = obj.pItemsData{idx};
            elseif idx >= 1 && idx <= numel(items)
                v = items{idx};
            else
                v = '';
            end
        end

        function set.Value(obj, v)
            % uilistbox semantics: Value is matched against ItemsData when
            % set, otherwise against Items (the display strings) directly.
            idx = [];
            if ~isempty(obj.pItemsData)
                for i = 1:numel(obj.pItemsData)
                    if isequaln(obj.pItemsData{i}, v)
                        idx = i;
                        break;
                    end
                end
            end
            if isempty(idx)
                items = cellstr(obj.Control.String);
                match = find(strcmp(items, v), 1);
                if ~isempty(match)
                    idx = match;
                end
            end
            if ~isempty(idx)
                obj.Control.Value = idx;
            end
        end
    end

    methods (Access = private)
        function handleCallback(obj)
            if ~isempty(obj.ValueChangedFcn)
                obj.ValueChangedFcn(obj, struct('Value', obj.Value));
            end
            notify(obj, 'ValueChanged');
        end
    end

    methods (Static, Access = private)
        function [items, itemsData, remaining] = extractSpecialArgs(args)
            % Pulls 'Items'/'ItemsData' name-value pairs out of a varargin
            % list (neither is a real uicontrol property, so forwarding
            % them unfiltered would error) and returns whatever's left to
            % pass straight through to uicontrol().
            items     = {};
            itemsData = {};
            remaining = {};
            i = 1;
            while i <= numel(args)
                key = args{i};
                if ischar(key) && i < numel(args) && strcmpi(key, 'Items')
                    items = args{i+1};
                    i = i + 2;
                elseif ischar(key) && i < numel(args) && strcmpi(key, 'ItemsData')
                    itemsData = args{i+1};
                    i = i + 2;
                else
                    remaining(end+1) = {key}; %#ok<AGROW>
                    i = i + 1;
                end
            end
        end
    end
end
