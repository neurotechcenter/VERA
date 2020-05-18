classdef ListSelector < uiw.abstract.WidgetContainer & uiw.mixin.HasListSortingButtons
    % ListSelector - A widget for adding/removing items from a list
    %
    % Create a widget that allows you to add/remove items from a listbox
    %
    % Syntax:
    %           w = uiw.widget.ListSelector('Property','Value',...)
    %
    % Examples:
    %
    %     AllItems = {'Alpha';'Bravo';'Charlie';'Delta';'Echo';'Foxtrot'};
    %     AddedIndexR = 2:numel(AllItems);
    %     fig = figure;
    %     w = uiw.widget.ListSelector('Parent',fig,'AllItems',AllItems,'AddedIndexR',AddedIndexR);
    %
    
    % Copyright 2016-2019 The MathWorks, Inc.
    %
    % Auth/Revision:
    %   MathWorks Consulting
    %   $Author: rjackey $
    %   $Revision: 312 $
    %   $Date: 2019-02-04 11:21:40 -0500 (Mon, 04 Feb 2019) $
    % ---------------------------------------------------------------------
    
    %RAJ - TO DO:
    % Make a better dialog for selection
    % Write updateSelectionForNewItems method
    % Make an optional copy button callback for customization
    
    %% Properties
    properties (AbortSet)
        AllItems (:,1) = cell(0,1) % Cell array of all items to select from [cell of strings]
        AddedIndexR (:,1) = zeros(0,1) % Numeric indices of added items from AllItems [column matrix]
    end
    properties (Dependent, SetAccess=private)
        ItemsL
        ItemsR % Cell array of current added items, based on AllItems and AddedIndexR [cell of strings]
    end
    properties
        AllowDuplicatesR (1,1) logical = false % Allow items to be selected multiple times in the widget? [true|(false)]
        AllowSearch (1,1) logical = false % Allow search box
    end
    properties (Dependent, AbortSet)
        SelectedIndexL
        SelectedIndexR % Numeric indices of currently selected (highlighted) items in the list [column matrix]
    end
    properties (Dependent, SetAccess=private)
        SelectedItemsL
        SelectedItemsR % Cell array of current added and highlighted items, based on AllItems, AddedIndexR and SelectedIndexR [cell of strings]
    end
    
    
    %% Constructor / Destructor
    methods
        
        function obj = ListSelector(varargin)
            % Construct the control
            
            % Call supercalss constructors
            obj@uiw.abstract.WidgetContainer();
            obj@uiw.mixin.HasListSortingButtons();
            
            % Update button icons, etc.
            obj.h.Button(1).CData = uiw.utility.loadIcon( @()imread('arrow_right_24.png') );
            obj.h.Button(2).CData = uiw.utility.loadIcon( @()imread('arrow_left_24.png') );
            
            % Parent the buttons
            set(obj.h.Button,'Parent',obj.hBasePanel);
            
            % List
            obj.h.ListLeft = uicontrol( ...
                'Parent', obj.hBasePanel, ...
                'Tag','ListLeft', ...
                'Units','pixels',...
                'Style', 'listbox', ...
                'FontSize', 10, ...
                'Max', 2, ... %multiselect
                'KeyReleaseFcn', @(h,e)onListKeyRelease(obj,e), ...
                'Callback', @(h,e)onListSelection(obj,e));
            
            obj.h.ListRight = uicontrol( ...
                'Parent', obj.hBasePanel, ...
                'Tag','ListRight', ...
                'Units','pixels',...
                'Style', 'listbox', ...
                'FontSize', 10, ...
                'Max', 2, ... %multiselect
                'KeyReleaseFcn', @(h,e)onListKeyRelease(obj,e), ...
                'Callback', @(h,e)onListSelection(obj,e));
            
            %             obj.h.SearchBox = uicontrol( ...
            %                 'Parent', obj.hBasePanel, ...
            %                 'Style', 'edit', ...
            %                 'FontSize', 10, ...
            %                 'Callback', @(h,e)onSearchEdited(obj,h,e));
            
            % The search box uses Java and is added on demand in redraw, to
            % maximize performance when not needed
            obj.h.SearchBox = gobjects(0);
            
            % Populate public properties from P-V input pairs
            obj.assignPVPairs(varargin{:});
            
            % Do the following only if obj is a ListSelector and not a
            % subclass of ListSelector
            if strcmp(class(obj), 'uiw.widget.ListSelector') %#ok<STISA>
                
                % Assign the construction flag
                obj.IsConstructed = true;
                
                % Redraw the widget
                obj.redraw();
                obj.onResized();
                obj.onEnableChanged();
                obj.onStyleChanged();
                
            end
            
        end %constructor
        
    end %methods - constructor/destructor
    
    
    
    %% Protected Methods
    methods (Access=protected)
        
        function redraw(obj)
            % Handle state changes that may need UI redraw
            
            % Does search box need to be added?
            if obj.AllowSearch && isempty(obj.h.SearchBox)
                obj.h.SearchBox = uiw.widget.EditableTextWithHistory(...
                'Parent',obj.hBasePanel,...
                'Units','pixels',...
                'ValueChangingFcn',@(h,e)obj.onSearchEdited(e),... %undocumented, may change
                'Callback',@(h,e)obj.onSearchEdited(e));
            else
                % Toggle the search box on or off
                set(obj.h.SearchBox,'Visible',uiw.utility.tf2onoff( obj.AllowSearch ));
            end
            
            % Ensure the construction is complete
            if obj.IsConstructed
                
                % Update the listbox text and selection
                itemsL = obj.ItemsL;
                newSelIdxL = obj.SelectedIndexL;
                if isempty(itemsL)
                    newSelIdxL = [];
                elseif ~isempty(newSelIdxL)
                    newSelIdxL = newSelIdxL( newSelIdxL <= numel(itemsL) );
                    if isempty(newSelIdxL)
                        newSelIdxL = numel(itemsL);
                    end
                end
                set(obj.h.ListLeft, 'String', itemsL, 'Value', newSelIdxL);
                
                % Validate AddedIndexR
                obj.AddedIndexR( obj.AddedIndexR > numel(obj.AllItems) ) = [];
                
                % Update the listbox text and selection
                itemsR = obj.ItemsR;
                newSelIdxR = obj.SelectedIndexR;
                if isempty(itemsR)
                    newSelIdxR = [];
                elseif ~isempty(newSelIdxR)
                    newSelIdxR = newSelIdxR( newSelIdxR <= numel(itemsR) );
                    if isempty(newSelIdxR)
                        newSelIdxR = numel(itemsR);
                    end
                end
                set(obj.h.ListRight, 'String', itemsR, 'Value', newSelIdxR);
                
                % Update button enable states
                obj.redrawButtons();
                
                % Almost all actions require checking enables, so just call
                % it here:
                obj.onEnableChanged();
                
            end %if obj.IsConstructed
            
        end %function redraw
        
        
        function redrawButtons(obj)
            % Handle changes to the button enable states
            
            % Ensure the construction is complete
            if obj.IsConstructed
                
                % Call superclass method
                obj.redrawButtons@uiw.mixin.HasListSortingButtons(...
                    obj.SelectedIndexR, numel(obj.AddedIndexR) );
                
                % Add button depends on left selection
                leftHasSelection = ~isempty(obj.SelectedIndexL);
                obj.h.Button(1).Enable = uiw.utility.tf2onoff(leftHasSelection);
                
            end %if obj.IsConstructed
            
        end %function
        
        
        function onResized(obj,~,~)
            % Handle changes to widget size
            
            % Ensure the construction is complete
            if obj.IsConstructed
                
                % Get widget dimensions
                [w,h] = obj.getInnerPixelSize;
                pad = obj.Padding;
                spc = obj.Spacing;
                
                % Button Size
                butW = 28;
                butH = 28;
                
                % Search or lower buttons enabled?
                buttonVis = strcmp( {obj.h.Button.Visible}, 'on' );
                if obj.AllowSearch || any(buttonVis(3:end))
                    listY = 1+pad+2*spc+butH;
                else
                    listY = 1+pad;
                end
                
                % Position Left listbox
                srchY = 1+pad;
                listLX = 1+pad;
                listW = max((w - (2*pad+2*spc+butW))/2,0);
                listH = max(h - pad - listY,0);
                set(obj.h.ListLeft, 'Position', [listLX listY listW listH])
                
                % Position Right listbox
                listRX = pad+2*spc+butW+listW;
                set(obj.h.ListRight, 'Position', [listRX listY listW listH])
                
                % Position search bar
                set(obj.h.SearchBox, 'Position', [listLX srchY listW butH])
                
                % Position middle buttons
                butX = listLX + listW + spc;
                butAddY = listY + listH/2 + spc/2;
                butDelY = butAddY - butH - spc;
                set(obj.h.Button(1), 'Position', [butX butAddY butW butH]);
                set(obj.h.Button(2), 'Position', [butX butDelY butW butH]);
                
                % Position visible lower buttons
                nbut = numel(buttonVis);
                butX = listRX;
                for idx = 3:nbut
                    if buttonVis(idx)
                        set(obj.h.Button(idx), 'Position', [butX srchY butW butH]);
                        butX = butX + butW + spc;
                    end
                end
                
            end %if obj.IsConstructed
            
        end %function onResized(obj)
        
        
        function onEnableChanged(obj,~)
            % Handle updates to Enable state
            
            obj.onEnableChanged@uiw.abstract.WidgetContainer();
            
            if strcmp(obj.Enable,'on')
                % Update button enable states
                obj.redrawButtons();
            end
            
        end %function onEnableChanged(obj)
        
        
        function onButtonPressed(obj,h,e)
            % Triggered on button press
            
            % Prepare event data
            evt = struct('Source',obj,'Interaction',e.Source.Tag);
            
            % Which button was pressed?
            switch h.Tag
                
                case 'Add'
                    
                    % What AllItems indices are shown on left?
                    if obj.AllowDuplicatesR % Duplicates
                        tf = true(size(obj.AllItems));
                        idxL = find(tf);
                    else % No Duplicates
                        tf = true(size(obj.AllItems));
                        tf(obj.AddedIndexR) = false;
                        idxL = find(tf);
                    end
                    
                    % Insert the new indices
                    idxAdd = idxL(obj.SelectedIndexL);
                    obj.insertIndices(idxAdd); %triggers redraw
                    evt.Items = obj.AllItems(idxAdd);
                    
                case 'Delete'
                    
                    % What AllItems indices are highlighted on right?
                    selIdxR = obj.SelectedIndexR;
                    
                    % Remove these items
                    evt.Items = obj.AllItems( obj.AddedIndexR(selIdxR,:) );
                    obj.AddedIndexR(selIdxR,:) = [];
                    
                    
                case 'MoveDown'
                    [idxNew, idxDest] = obj.shiftIndexInList(...
                        obj.SelectedIndexR, numel(obj.AddedIndexR), 1);
                    obj.SelectedIndexR = idxDest;
                    obj.AddedIndexR = obj.AddedIndexR(idxNew);
                    evt.NewOrder = idxNew;
                    evt.DestIndex = idxDest;
                    
                case 'MoveUp'
                    [idxNew, idxDest] = obj.shiftIndexInList(...
                        obj.SelectedIndexR, numel(obj.AddedIndexR), -1);
                    obj.SelectedIndexR = idxDest;
                    obj.AddedIndexR = obj.AddedIndexR(idxNew);
                    evt.NewOrder = idxNew;
                    evt.DestIndex = idxDest;
                    
                case 'Reverse'
                    obj.AddedIndexR = flip(obj.AddedIndexR);
                    obj.SelectedIndexR = numel(obj.AddedIndexR) - obj.SelectedIndexR + 1;
                    
                otherwise
                    
                    
            end %switch
            
            % Call the callback
            obj.callCallback(evt);
            
        end %function
        
        
        function onSearchEdited(obj,e)
            % Triggered on search text changing
            
            % Find search matches in the left list
            if isfield(e,'NewString')
                searchStr = e.NewString;
            else
                searchStr = e.Value;
            end
            isMatch = ~cellfun(@isempty, regexpi(obj.ItemsL, searchStr));
            idxMatch = find(isMatch);
            
            % Select the items in the left list
            obj.h.ListLeft.Value = idxMatch;
            
        end %function
        
        
        
        function onListKeyRelease(obj,e)
            % Triggered on key press on list
            
            % If return/enter was pressed on a list, perform add/delete
            if strcmp(e.Key,'return')
                
                switch e.Source.Tag
                    
                    case 'ListLeft'
                        if ~isempty(obj.SelectedIndexL)
                            s.Tag = 'Add';
                            obj.onButtonPressed(s,e);
                        end
                        
                    case 'ListRight'
                        if ~isempty(obj.SelectedIndexR)
                            s.Tag = 'Delete';
                            obj.onButtonPressed(s,e);
                        end
                        
                end %switch
                
            end %if strcmp(e.Key,'return')
            
        end %function
        
        function onCopyButtonPressed(obj,~,~)
            % Triggered on button press
            
            % What is currently highlighted in the listbox?
            SelIdx = obj.h.ListRight.Value;
            
            % What indices are they?
            NewSelection = obj.AddedIndexR(SelIdx);
            
            % Insert the new indices
            obj.insertIndices(NewSelection); %triggers redraw
            
            % Call the callback
            Items = obj.AllItems(NewSelection);
            evt = struct('Source',obj,'Interaction','Copy','Items',Items);
            obj.callCallback(evt);
            
        end %function
        
        
        function onListSelection(obj,e)
            % Triggered on selection change
            
            % Update button enable states
            obj.redrawButtons();
            
            % Which button was pressed?
            switch e.Source.Tag
                
                case 'ListLeft'
                    
                    % Clear any search
                    if ~isempty(obj.h.SearchBox)
                        obj.h.SearchBox.Value = '';
                    end
                    
                case 'ListRight'
                    
                    % Call the callback
                    evt = struct('Source',obj,'Interaction',e.Source.Tag);
                    evt.Indices = obj.SelectedIndexR;
                    evt.Items = obj.SelectedItemsR;
                    obj.callCallback(evt);
                    
            end %switch
            
        end %function
        
        
        function insertIndices(obj,idxNew)
            
            % Where to insert?
            if ~obj.AllowMove
                %RAJ - improve this to sort the list
                InsertIdx = numel(obj.AddedIndexR);
            elseif isempty(obj.SelectedIndexR)
                InsertIdx = numel(obj.AddedIndexR);
            else
                InsertIdx = obj.SelectedIndexR(end);
            end
            
            % Update the selection
            NewIndex = [
                obj.AddedIndexR(1:InsertIdx)
                idxNew(:)
                obj.AddedIndexR((InsertIdx+1):end)];
            if ~obj.AllowMove
                NewIndex = sort(NewIndex);
            end
            obj.AddedIndexR = NewIndex;
            
        end
        
    end
    
    
    %% Get/Set methods
    methods
        
        % AllItems
        function set.AllItems(obj,value)
            if ~isequal(obj.AllItems, value)
                validateattributes(value,{'cell','string'},{'column'})
                obj.AllItems = value;
                obj.redraw();
            end
        end
        
        % AddedIndexR
        function set.AddedIndexR(obj,value)
            value = value(:);
            if ~isequal(obj.AddedIndexR, value)
                maxVal = numel(obj.AllItems); %#ok<MCSUP>
                validateattributes(value,{'numeric'},...
                    {'column', 'integer', 'positive', '<=', maxVal})
                obj.AddedIndexR = value;
                obj.redraw();
            end
        end
        
        % ItemsL
        function value = get.ItemsL(obj)
            if obj.AllowDuplicatesR % Duplicates
                value = obj.AllItems;
            else % No Duplicates
                tf = true(size(obj.AllItems));
                tf(obj.AddedIndexR) = false;
                value = obj.AllItems(tf);
            end
        end
        
        % ItemsR
        function value = get.ItemsR(obj)
            value = obj.AllItems( obj.AddedIndexR );
        end
        
        % AllowDuplicatesR
        function set.AllowDuplicatesR(obj,value)
            obj.AllowDuplicatesR = value;
            obj.redraw();
        end
        
        % AllowSearch
        function set.AllowSearch(obj,value)
            obj.AllowSearch = value;
            obj.redraw();
            obj.onResized();
        end
        
        % SelectedIndexL
        function value = get.SelectedIndexL(obj)
            if obj.IsConstructed
                value = get( obj.h.ListLeft, 'Value' );
            else
                value = zeros(0,1);
            end
        end
        function set.SelectedIndexL(obj,value)
            if obj.IsConstructed
                value(value > numel(obj.ItemsL)) = [];
                set( obj.h.ListLeft, 'Value', value );
            end
        end
        
        % SelectedIndexR
        function value = get.SelectedIndexR(obj)
            if obj.IsConstructed
                value = get( obj.h.ListRight, 'Value' );
            else
                value = zeros(0,1);
            end
        end
        function set.SelectedIndexR(obj,value)
            if obj.IsConstructed
                value(value > numel(obj.ItemsR)) = [];
                set( obj.h.ListRight, 'Value', value );
            end
        end
        
        % SelectedItemsL
        function value = get.SelectedItemsL(obj)
            %RAJ - probably wrong
            value = obj.AllItems( obj.SelectedIndexL );
        end
        
        % SelectedItemsR
        function value = get.SelectedItemsR(obj)
            value = obj.AllItems( obj.AddedIndexR(obj.SelectedIndexR) );
        end
        
    end % Get/Set methods
    
    
end %classdef