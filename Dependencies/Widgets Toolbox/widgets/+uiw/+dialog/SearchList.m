classdef SearchList < uiw.abstract.BaseDialog
    % SearchList - A dialog for searching from a list of text items
    % ---------------------------------------------------------------------
    % Create a dialog that helps search from a list of text items
    %
    % Syntax:
    %         d = uiw.dialog.SearchList('Property','Value',...)
    %
    % Examples:
    %
    %         d = uiw.dialog.SearchList(...
    %             'Title','My Dialog',...
    %             'DialogSize',[250 600],...
    %             'Visible','on',...
    %             'List',{'USA','Canada','Mexico','Argentina'},...
    %             'SearchText','a',...
    %             'SelectedIndex',4);
    %
    %         [Out,Action] = d.waitForOutput()
    %

%   Copyright 2017-2019 The MathWorks Inc.
    %
    % Auth/Revision:
    %   MathWorks Consulting
    %   $Author: rjackey $
    %   $Revision: 324 $
    %   $Date: 2019-04-23 08:05:17 -0400 (Tue, 23 Apr 2019) $
    % ---------------------------------------------------------------------


    %% Public properties
    properties (AbortSet)
        List (:,1) string %List of items to choose from (string)
        SelectedIndex (1,:) double {mustBeInteger,mustBePositive} %Numeric indices of currently selected/highlighted items from List
    end
    
    properties (AbortSet, Dependent)
        SearchText char %current search/filter text
        MultiSelect (1,1) logical %indicates whether multiple items may be selected [true|false]
    end
    
    properties (SetAccess=protected)
        FilteredIndex %(read-only) index of which List items are currently displayed
        FilteredList %(read-only) currently displayed list
    end


    %% Constructor / Destructor
    methods

        function obj = SearchList(varargin)
            
            % Specify some default args:
            firstArgs = {'DialogSize',[300 700],'Resize','on'};
            
            % Pull out some inputs to provide right away
            SplitProps = {'Resize','Position','DialogSize','Visible'};
            [splitArgs,remainArgs] = uiw.mixin.AssignPVPairs.splitArgs(SplitProps, varargin{:});            

            % Call superclass constructor
            obj = obj@uiw.abstract.BaseDialog('Padding',6,firstArgs{:},splitArgs{:});

            % Create the base graphics
            obj.create();

            % Populate public properties from P-V input pairs
            [splitArgs,remainArgs] = uiw.mixin.AssignPVPairs.splitArgs('SelectedIndex', remainArgs{:});     
            obj.assignPVPairs(remainArgs{:});
            obj.assignPVPairs(splitArgs{:});

            % Assign the construction flag
            obj.IsConstructed = true;

            % Redraw the dialog
            obj.onResized();
            obj.redraw();
            obj.onStyleChanged();

        end % constructor

    end %methods - constructor/destructor



    %% Protected methods
    methods (Access=protected)

        function create(obj)
            
            % Add the search controls
            obj.h.SearchText = uicontrol(...
                'Parent',obj.hBasePanel,...
                'Style','edit',...
                'String','',...
                'HorizontalAlignment','left',...
                'TooltipString','Enter search text',...
                'FontSize',10,...
                'Callback',@(h,e)redraw(obj));
            
            obj.h.SearchButton = uicontrol(...
                'Parent', obj.hBasePanel,...
                'Style', 'pushbutton',...
                'Units', 'pixels',...
                'CData', uiw.utility.loadIcon('search_24.png'),...
                'Callback', @(h,e)redraw(obj) );
            
            obj.h.List = uicontrol(...
                'Parent', obj.hBasePanel,...
                'Style', 'list',...
                'FontSize', 10,...
                'Units', 'pixels',...
                'String', {''},...
                'Callback', @(h,e)onListSelection(obj) );

        end %function create

        
        function redraw(obj)
            % Ensure the construction is complete
            if obj.IsConstructed
                
                % Perform search and filter
                if isempty(obj.SearchText)
                    obj.FilteredIndex = 1:numel(obj.List);
                else
                    SearchResult = regexpi(obj.List, obj.SearchText);
                    obj.FilteredIndex = ~cellfun('isempty',SearchResult);
                end
                obj.FilteredList = obj.List(obj.FilteredIndex);
                
                % Get the listbox selection indices
                idxFilt = find(obj.FilteredIndex);
                [~,SelIdx] = intersect(idxFilt, obj.SelectedIndex);
                
                % Update listbox
                if ~obj.MultiSelect && isempty(SelIdx)
                    SelIdx = 1;
                    obj.SelectedIndex = SelIdx;
                end
                set(obj.h.List,'String',obj.FilteredList,'Value',SelIdx)
                
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

                % Calculate positions
                butSz = 25;
                pad = obj.Padding;
                spc = obj.Spacing;
                
                % Search Text and Button
                y0bs = h - butSz - pad;
                x0b = w - pad - butSz;
                set(obj.h.SearchText,'Position',[pad+1 y0bs x0b-spc-pad butSz]);
                set(obj.h.SearchButton,'Position',[x0b y0bs butSz butSz]);
                
                % List
                set(obj.h.List,'Position',[pad+1 pad+1 w-2*pad y0bs-spc-pad]);

            end %if obj.IsConstructed
            
        end %function
        
        
        
        function onListSelection(obj)
            SelIdx = obj.h.List.Value;
            idxFilt = find(obj.FilteredIndex);
            obj.SelectedIndex = idxFilt(SelIdx);
        end
        
        
        function onButtonPressed(obj,action)
            
            % Assign output
            obj.Output = obj.SelectedIndex;
            
            % Call superclass method
            obj.onButtonPressed@uiw.abstract.BaseDialog(action);

        end %function
        

    end % Protected methods



    %% Get/Set methods
    methods
        
        % List
        function set.List(obj,value)
            obj.List = value;
            obj.redraw();
        end
        
        % SelectedIndex
        function set.SelectedIndex(obj,value)
            validateattributes(value,{'numeric'},{'<=',max(1,numel(obj.List))}) %#ok<MCSUP>
            obj.SelectedIndex = value;
            obj.redraw();
        end
        
        % SearchText
        function value = get.SearchText(obj)
            value = obj.h.SearchText.String;
        end
        function set.SearchText(obj,value)
            obj.h.SearchText.String = value;
            obj.redraw();
        end
        
        % MultiSelect
        function value = get.MultiSelect(obj)
            value = obj.h.List.Max > 1;
        end
        function set.MultiSelect(obj,value)
            obj.h.List.Max = 1 + value;
            obj.redraw();
        end

    end % Get/Set methods

end % classdef