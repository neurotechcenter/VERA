classdef ListSelector < uiw.abstract.BaseDialog
    % ListSelector - A dialog containing the ListSelector widget
    % 
    % Create a dialog containing the ListSelector widget
    %
    % Syntax:
    %         d = uiw.dialog.ListSelector('Property','Value',...)
    %

    % Copyright 2019 The MathWorks, Inc.
    %
    % Auth/Revision:
    %   MathWorks Consulting
    %   $Author: rjackey $
    %   $Revision: 310 $
    %   $Date: 2019-01-31 14:18:53 -0500 (Thu, 31 Jan 2019) $
    % ---------------------------------------------------------------------
    

    %% Constructor / Destructor
    methods

        function obj = ListSelector(varargin)
            
            % Pull out some inputs to provide right away
            SplitProps = {'DialogSize','Visible'};
            [splitArgs,remainArgs] = uiw.mixin.AssignPVPairs.splitArgs(SplitProps, varargin{:});            

            % Call superclass constructor
            obj = obj@uiw.abstract.BaseDialog('DialogSize',[600 800],splitArgs{:});

            % Add the list widget
            obj.h.ListSelector = uiw.widget.ListSelector(...
                'Parent',obj.hBasePanel,...
                'Units','normalized',...
                'Position',[0 0 1 1]);
            
            % Dynamically add the ListSelector props to this dialog
            obj.addWidgetProps(obj.h.ListSelector);

            % Populate public properties from P-V input pairs
            unmatchedArgs = obj.assignPVPairs('Resize','on','Padding',6,remainArgs{:});
            
            % Set unmatched properties that belong to widget
            % Prioritize the order
            if isfield(unmatchedArgs,'AllItems')
                obj.AllItems = unmatchedArgs.AllItems(:);
                unmatchedArgs = rmfield(unmatchedArgs,'AllItems');
            end
            if isfield(unmatchedArgs,'AddedIndexR')
                obj.AddedIndexR = unmatchedArgs.AddedIndexR(:);
                unmatchedArgs = rmfield(unmatchedArgs,'AddedIndexR');
            end
            set(obj.h.ListSelector,unmatchedArgs)

            % Assign the construction flag
            obj.IsConstructed = true;

            % Redraw the dialog
            obj.redraw();
            obj.onResized();
            obj.onStyleChanged();

        end % constructor

    end %methods - constructor/destructor


    
    %% Protected methods
    methods (Access=protected)

        function onButtonPressed(obj,action)
            
            % Assign output
            obj.Output = obj.AddedIndexR;
            
            % Call superclass method
            obj.onButtonPressed@uiw.abstract.BaseDialog(action);

        end %function
        
    end %methods

end % classdef