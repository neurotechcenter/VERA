classdef Popup < uiw.abstract.WidgetContainer & uiw.mixin.HasCallback
    % Popup - A simple popup control
    %
    % Create a simple popup widget
    %
    % Syntax:
    %           w = uiw.widget.Popup('Property','Value',...)
    %
    
%   Copyright 2005-2019 The MathWorks Inc.
    %
    % Auth/Revision:
    %   MathWorks Consulting
    %   $Author: rjackey $
    %   $Revision: 324 $
    %   $Date: 2019-04-23 08:05:17 -0400 (Tue, 23 Apr 2019) $
    % ---------------------------------------------------------------------
    
    %% Properties
    properties (AbortSet)
        Items cell = cell(0,1) %Cell array of all items in the list [cell of strings]
        SelectedIndex (1,1) double = 1 % The selected index from the list of choices
    end
    
    properties (AbortSet, Dependent)
        Value char % The selected choice
    end
    
    
    %% Constructor / Destructor
    methods
        
        function obj = Popup(varargin)
            % Construct the widget
            
            % Create the controls
            obj.h.Popup = uicontrol(...
                'Parent',obj.hBasePanel,...
                'Style','popup',...
                'String',{''},...
                'Units','normalized',...
                'Position',[0 0 1 1],...
                'Callback', @(h,e)onSelectionChanged(obj,e) );
            
            % These args must be set last
            [lastArgs,firstArgs] = obj.splitArgs({'SelectedIndex','Value'},varargin{:});
            
            % Populate public properties from P-V input pairs
            obj.assignPVPairs(firstArgs{:},lastArgs{:});
            
            % Assign the construction flag
            obj.IsConstructed = true;
            
            % Redraw the widget
            obj.onResized();
            obj.onEnableChanged();
            obj.redraw();
            obj.onStyleChanged();
            
        end % constructor
        
    end %methods - constructor/destructor
    
    
    
    %% Protected methods
    methods (Access=protected)
        
        function redraw(obj)
            
            % Ensure the construction is complete
            if obj.IsConstructed
                
                if isempty(obj.Items)
                    obj.h.Popup.String = {''};
                    obj.h.Popup.Value = 1;
                    obj.h.Popup.Enable = 'off';
                else
                    uiw.utility.setPropsIfDifferent(obj.h.Popup,'Enable',obj.Enable);
                    obj.SelectedIndex = min(numel(obj.Items),obj.SelectedIndex);
                    obj.h.Popup.String = obj.Items;
                    obj.h.Popup.Value = obj.SelectedIndex;
                end
                
            end %if obj.IsConstructed
            
        end % function
        
        function onSelectionChanged(obj,~)
            % Triggered on interaction with the control
            
            % Ensure the construction is complete
            if obj.IsConstructed
                
                newIndex = obj.h.Popup.Value;
                if ~isequal(obj.SelectedIndex, newIndex)
                    evt = struct('Source', obj, ...
                        'Interaction', 'Selection', ...
                        'OldSelectedIndex', obj.SelectedIndex, ...
                        'NewSelectedIndex', newIndex,...
                        'OldValue', obj.Value, ...
                        'NewValue', obj.Items{newIndex});
                    obj.SelectedIndex = newIndex;
                    obj.callCallback(evt);
                end
                
            end %if obj.IsConstructed
        end % onSelectionChanged
        
    end % protected methods
    
    
    %% Get/Set methods
    methods
        
        function set.Items(obj,newItems)
            
            validateattributes(newItems,{'cell','string'},{})
            if ~all(cellfun(@(x)ischar(x),newItems))
                error('Expected a string or cellstr array.');
            end
            
            % Try to retain value selected, in case it moved on the list
            oldValue = obj.Value; %#ok<MCSUP>
            if isempty(oldValue) || isempty(newItems)
                newIdxForValue = [];
            else
                newIdxForValue = find(strcmp(newItems, oldValue),1);
            end
            
            % Set the new set of items
            obj.Items = newItems;
            
            % Set the selected index to retain if possible
            if isempty(newIdxForValue)
                obj.SelectedIndex = 1; %#ok<MCSUP>
            else
                obj.SelectedIndex = newIdxForValue; %#ok<MCSUP>
            end
            
            % Redraw contents
            obj.redraw();
            
        end
        
        function value = get.Value(obj)
            if isempty(obj.Items)
                value = '';
            else
                value = obj.Items{obj.SelectedIndex};
            end
        end
        function set.Value(obj, value)
            selIdx = find(strcmp(obj.Items, value),1);
            if isempty(selIdx)
                selIdx = 1;
                warning('uiw:widget:Popup:BadValue',...
                    ['Value ''%s'' is not valid in popup widget with '...
                    'choices ''%s''. Defaulting to first entry.'],...
                    value, strjoin(obj.Items,', ') );
            end
            obj.SelectedIndex = selIdx;
        end
        
        function set.SelectedIndex(obj,value)
            maxVal = max(numel(obj.Items),1); %#ok<MCSUP>
            validateattributes(value,{'numeric'},{'positive','finite','scalar','<=',maxVal})
            obj.SelectedIndex = value;
            obj.redraw();
        end
        
    end % Get/Set methods
    
end % classdef
