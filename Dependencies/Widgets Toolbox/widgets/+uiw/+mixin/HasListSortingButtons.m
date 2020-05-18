classdef HasListSortingButtons < uiw.mixin.HasContainer & uiw.mixin.HasCallback
    % HasListSortingButtons - Mixin to provide list editing and ordering buttons
    %
    % This mixin class provides buttons for editing and ordering a list
    %
    %

%   Copyright 2017-2019 The MathWorks Inc.
    %
    % Auth/Revision:
    %   MathWorks Consulting
    %   $Author: rjackey $
    %   $Revision: 324 $  $Date: 2019-04-23 08:05:17 -0400 (Tue, 23 Apr 2019) $
    % ---------------------------------------------------------------------


    %% Properties
    properties (AbortSet)
        AllowAdd (1,1) logical = true % Flag whether to display add button on the widget. [(true)|false]
        AllowDelete (1,1) logical = true % Flag whether to display delete button on the widget. [(true)|false]
        AllowMove (1,1) logical = false % Flag whether to display up/down buttons on the widget. [true|(false)]
        AllowReverse (1,1) logical = false % Flag whether to display a reverse order button on the widget. [true|(false)]
        AllowCopy (1,1) logical = false % Flag whether to display a copy button on the widget. [true|(false)]
        AllowEdit (1,1) logical = false % Flag whether to display an edit button on the widget. [true|(false)]
        AllowPlot (1,1) logical = false % Flag whether to display a plot button on the widget. [true|(false)]
        AllowRun  (1,1) logical = false % Flag whether to display a run button on the widget. [true|(false)]
        ButtonLocation char {mustBeMember(ButtonLocation,{'left','right','top','bottom'})} = 'right' % Location of the buttons. ['left'|('right')|'top'|'bottom']
        ButtonSize (1,1) {mustBeNumeric, mustBePositive} = 30; % Size of the square buttons in pixels
    end


    %% Abstract Methods
    methods (Access=protected)
        onButtonPressed(obj,h,e) %Triggered on list button pressed - subclass must implement
    end %methods


    %% Constructor and Destructor
    methods

        % Constructor
        function obj = HasListSortingButtons()
            % Create the buttons

            % Buttons (unparented - subclass must place them)
            bInfo = obj.getButtonInfo();
            for idx = size(bInfo,1):-1:1
                obj.h.Button(idx) = uicontrol( ...
                    'Parent',[],...
                    'Style', 'pushbutton', ...
                    'CData', bInfo{idx,2}, ...
                    'TooltipString', bInfo{idx,3},...
                    'Tag',bInfo{idx,1},...
                    'Callback', @(h,e)onButtonPressed(obj,h,e) );
            end

        end %function

    end %methods
    
    
    %% Static private methods
    methods (Static, Access=private)
        
        function bInfoOut = getButtonInfo()
            
            persistent bInfo
            
            if isempty(bInfo)
                
                bInfo = {
                    'Add',      uiw.utility.loadIcon( @()imread('add_24.png') ),         'Add a new item to the list.'
                    'Delete',   uiw.utility.loadIcon( @()imread('delete_24.png') ),      'Delete the selected item from the list.'
                    'MoveUp',   uiw.utility.loadIcon( @()imread('arrow_up_24.png') ),    'Move the selected item up.'
                    'MoveDown', uiw.utility.loadIcon( @()imread('arrow_down_24.png') ),  'Move the selected item down.'
                    'Reverse',  uiw.utility.loadIcon( @()imread('arrows_up_down_24.png') ),'Reverses the order of all items.'
                    'Copy',     uiw.utility.loadIcon( @()imread('copy_24.png') ),        'Copy the selected item.'
                    'Edit',     uiw.utility.loadIcon( @()imread('edit_24.png') ),        'Edit the selected item.'
                    'Plot',     uiw.utility.loadIcon( @()imread('plot_24.png') ),        'Plot the selected item.'
                    'Run',      uiw.utility.loadIcon( @()imread('play_24.png') ),         'Run the selected item.'
                    };
                
            end %if isempty(bInfo)
            
            bInfoOut = bInfo;
            
        end %function
        
    end %methods


    %% Protected Methods
    methods (Access=protected)

        function [remX, remY, remW, remH] = positionButtons(obj,w,h)
            % Handle updates to the button positions, and return remaining space

            % This method positions the buttons, given the width and height
            % of the space to position in. It returns the x, y ,w ,h
            % of the remaining space not used by the buttons.

            % Get padding/spacing
            pad = obj.Padding;
            spc = obj.Spacing;

            % Position buttons
            ButtonVis = strcmp( {obj.h.Button.Visible}, 'on' );
            nbut = numel(obj.h.Button);
            nbutVis = sum(ButtonVis);
            butSz = obj.ButtonSize;
            butSpc = butSz + spc;

            switch obj.ButtonLocation

                case 'left'

                    butX = 1+pad;
                    butY = h - pad - butSz;
                    for idx = 1:nbut
                        if ButtonVis(idx)
                            set(obj.h.Button(idx), 'Position', [butX butY butSz butSz]);
                            butY = butY - butSpc;
                        end
                    end
                    remX = 1+pad+butSpc;
                    remY = 1+pad;
                    remW = max(w - pad - remX,1);
                    remH = max(h - 2*pad,1);

                case 'right'

                    numRowsFit = max( floor( (h - 2*pad + spc) / (butSpc) ), 1);
                    numCols = ceil(nbutVis / numRowsFit);
                    butX0 = w - pad + spc - numCols*butSpc;
                    butY0 = h - pad - butSz;
                    butX = butX0;
                    butY = butY0;
                    nextRow = 1;
                    for idx = 1:nbut
                        if ButtonVis(idx)
                            obj.h.Button(idx).Position = [butX butY butSz butSz];
                            nextRow = nextRow + 1;
                            if nextRow > numRowsFit
                                nextRow = 1;
                                butX = butX + butSpc;
                                butY = butY0;
                            else
                                butY = butY - butSpc;
                            end

                        end
                    end
                    remX = 1+pad;
                    remY = 1+pad;
                    remW = max(butX0 - spc - pad,1);
                    remH = max(h - 2*pad,1);

                case 'top'
                    butX = 1+pad;
                    butY = h - pad - butSz;
                    for idx = 1:nbut
                        if ButtonVis(idx)
                            set(obj.h.Button(idx), 'Position', [butX butY butSz butSz]);
                            butX = butX + butSpc;
                        end
                    end
                    remX = 1+pad;
                    remY = 1+pad;
                    remW = max(w - 2*pad,1);
                    remH = max(butY - spc - pad,1);

                case 'bottom'
                    butX = 1+pad;
                    butY = 1+pad;
                    for idx = 1:nbut
                        if ButtonVis(idx)
                            set(obj.h.Button(idx), 'Position', [butX butY butSz butSz]);
                            butX = butX + butSpc;
                        end
                    end
                    remX = 1+pad;
                    remY = 1+pad+butSpc;
                    remW = max(w - 2*pad,1);
                    remH = max(h - pad - remY,1);

            end %switch obj.ButtonLocation

        end %function positionButtons(obj)


        function redrawButtons(obj,selRows,numRows)
            % Handle changes to the button enable states

            % Ensure the construction is complete
            if obj.IsConstructed

                % If Enabled, set individual enables
                if strcmp(obj.Enable,'on')

                    % How many are selected?
                    numSel = numel(selRows);

                    % Button Enables and Visibilities
                    set(obj.h.Button(1), ... %Add
                        'Visible', uiw.utility.tf2onoff(obj.AllowAdd), ...
                        'Enable', 'on' );
                    set(obj.h.Button(2), ... %Delete
                        'Visible', uiw.utility.tf2onoff(obj.AllowDelete), ...
                        'Enable', uiw.utility.tf2onoff(numSel>0) );
                    set(obj.h.Button(3), ... %MoveUp
                        'Visible', uiw.utility.tf2onoff(obj.AllowMove),...
                        'Enable', uiw.utility.tf2onoff(numSel>0 && selRows(end)>numSel) );
                    set(obj.h.Button(4), ... %MoveDown
                        'Visible', uiw.utility.tf2onoff(obj.AllowMove),...
                        'Enable', uiw.utility.tf2onoff(numSel>0 && selRows(1)<=(numRows-numSel)) );
                    set(obj.h.Button(5), ... %Reverse
                        'Visible', uiw.utility.tf2onoff(obj.AllowReverse),...
                        'Enable', uiw.utility.tf2onoff(numRows>1) );
                    set(obj.h.Button(6), ... %Copy
                        'Visible', uiw.utility.tf2onoff(obj.AllowCopy),...
                        'Enable', uiw.utility.tf2onoff(numSel>0) );
                    set(obj.h.Button(7), ... %Edit
                        'Visible', uiw.utility.tf2onoff(obj.AllowEdit),...
                        'Enable', uiw.utility.tf2onoff(numSel==1) );
                    set(obj.h.Button(8), ... %Plot
                        'Visible', uiw.utility.tf2onoff(obj.AllowPlot),...
                        'Enable', uiw.utility.tf2onoff(numSel==1) );
                    set(obj.h.Button(9), ... %Run
                        'Visible', uiw.utility.tf2onoff(obj.AllowRun),...
                        'Enable', uiw.utility.tf2onoff(numSel==1) );

                else
                    % Disabled
                    set(obj.h.Button,'Enable','off')

                end %if strcmp(obj.Enable,'on')

            end %if obj.IsConstructed

        end %function

    end %methods



    %% Static Methods
    methods (Static, Access=protected)

        function [idxNew, idxMovedTo] = shiftIndexInList(idxShift, nItems, shift)
            % Shift indices within a list
            %
            % Syntax:
            %       [idxNew, idxMovedTo] = obj.shiftIndexInList(idxShift, nItems, shift)
            %
            % Inputs:
            %       idxShift - indices to shift
            %       nItems - number of items in the list (can't move past this limit)
            %       shift - positions to shift the indicated items, positive integer
            %               for forward, negative for back
            %
            % Outputs:
            %       idxNew - new indices for the whole list, from 1:nItems
            %       idxMovedTo - new indices in the list for the items that just moved
            %
            % Examples:
            %
            %     >> idxShift = [5 6 9 10];
            %     >> nItems = 10;
            %     >> shift = 1;
            %     >> [idxNew, idxMovedTo] = obj.shiftIndexInList([5 6 9 10], 10, 1)
            %
            %     idxNew =
            %          1     2     3     4     7     5     6     8     9    10
            %
            %     idxMovedTo =
            %          6     7     9    10
            %
            % Notes:
            %       If the end of the list is hit, items hitting that limit will not be
            %       moved.
            %

            % Validate inputs
            validateattributes(nItems,{'numeric'},{'finite','nonnegative','integer'});
            validateattributes(idxShift,{'numeric'},{'vector','finite','positive','integer','increasing','<=',nItems});
            validateattributes(shift,{'numeric'},{'integer','scalar'});

            % Make indices to all items as they are now
            idxNew = 1:nItems;

            % Prepare the indices of the shifted items
            idxShift = sort(idxShift);

            % Find the last stable item that doesn't move
            [~,idxStable] = setdiff(idxNew, idxShift, 'stable');
            if ~isempty(idxStable)
                idxFirstStable = idxStable(1);
                idxLastStable = idxStable(end);
            else
                idxFirstStable = inf;
                idxLastStable = 0;
            end

            % Track the new positions
            idxMovedTo = idxShift;

            % Which way do we loop?
            if shift > 0 %Shift to end

                for idxToMove=numel(idxShift):-1:1

                    % Calculate if there's room to move this item
                    idxThisBefore = idxShift(idxToMove);
                    ThisShift = max( min(idxLastStable-idxThisBefore, shift), 0 );

                    % Where does this item move from/to
                    idxThisAfter = idxThisBefore + ThisShift;
                    idxMovedTo(idxToMove) = idxThisAfter;

                    % Where do other items move from/to
                    idxOthersBefore = idxShift(idxToMove)+1:1:idxThisAfter;
                    idxOthersAfter = idxOthersBefore - ThisShift;

                    % Move the items
                    idxNew([idxThisAfter idxOthersAfter]) = idxNew([idxThisBefore idxOthersBefore]);

                end

            elseif shift < 0 %Shift to start

                for idxToMove=1:numel(idxShift)

                    % Calculate if there's room to move this item
                    idxThisBefore = idxShift(idxToMove);
                    ThisShift = min( max(idxFirstStable-idxThisBefore, shift), 0 );

                    % Where does this item move from/to
                    idxThisAfter = idxThisBefore + ThisShift;
                    idxMovedTo(idxToMove) = idxThisAfter;

                    % Where do other items move from/to
                    idxOthersBefore = idxThisAfter:1:idxShift(idxToMove)-1;
                    idxOthersAfter = idxOthersBefore - ThisShift;

                    % Move the items
                    idxNew([idxThisAfter idxOthersAfter]) = idxNew([idxThisBefore idxOthersBefore]);

                end


            else % No shift

                % Do nothing

            end %if shift > 0

        end %function

    end %methods



    %% Get/Set Methods
    methods

        function set.ButtonLocation(obj,value)
            value = validatestring(value, {'top','right','left','bottom'});
            obj.ButtonLocation = value;
            obj.redraw();
            obj.onResized();
        end

        function set.ButtonSize(obj,value)
            obj.ButtonSize = value;
            obj.onResized();
        end

        function set.AllowAdd(obj,value)
            obj.AllowAdd = value;
            obj.redraw();
            obj.onResized();
        end

        function set.AllowDelete(obj,value)
            obj.AllowDelete = value;
            obj.redraw();
            obj.onResized();
        end

        function set.AllowMove(obj,value)
            obj.AllowMove = value;
            obj.redraw();
            obj.onResized();
        end

        function set.AllowReverse(obj,value)
            obj.AllowReverse = value;
            obj.redraw();
            obj.onResized();
        end

        function set.AllowCopy(obj,value)
            obj.AllowCopy = value;
            obj.redraw();
            obj.onResized();
        end

        function set.AllowEdit(obj,value)
            obj.AllowEdit = value;
            obj.redraw();
            obj.onResized();
        end

        function set.AllowPlot(obj,value)
            obj.AllowPlot = value;
            obj.redraw();
            obj.onResized();
        end

        function set.AllowRun(obj,value)
            obj.AllowRun = value;
            obj.redraw();
            obj.onResized();
        end

    end %methods


end % classdef