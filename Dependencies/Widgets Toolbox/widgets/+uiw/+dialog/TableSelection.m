classdef TableSelection < uiw.abstract.BaseDialog
    % TableSelection - A dialog for selecting from a table list of items
    % ---------------------------------------------------------------------
    % Create a dialog for selecting from a table list of items
    %
    % Syntax:
    %         d = uiw.dialog.TableSelection('Property','Value',...)
    %
    % Examples:
    %
    %         d = uiw.dialog.TableSelection(...
    %             'Title','My Dialog',...
    %             'DialogSize',[250 600],...
    %             'Visible','on',...
    %             'ColumnName',{'Country','State','Rank'},...
    %             'Data',{'USA','Alabama',1; 'USA','Maine',2; 'Canada','Quebec',5},...
    %             'SelectedRows',2);
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
    properties (Dependent)
        DataTable
        SelectedRows
        MultiSelect
    end


    %% Constructor / Destructor
    methods

        function obj = TableSelection(varargin)
            
            % Specify some default args:
            firstArgs = {'Resize','on'};
            
            % Pull out some inputs to provide right away
            SplitProps = {'Resize','Position','DialogSize','Visible'};
            [splitArgs,remainArgs] = uiw.mixin.AssignPVPairs.splitArgs(SplitProps, varargin{:});            

            % Call superclass constructor
            obj = obj@uiw.abstract.BaseDialog('Padding',6,firstArgs{:},splitArgs{:});

            % Create the table
            obj.h.Table = uiw.widget.Table(...
                'Units', 'pixels',...
                'Editable',false,...
                'Parent', obj.hBasePanel);

            % Populate public properties from P-V input pairs
            obj.assignPVPairs(remainArgs{:});

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
        
        function onResized(obj,~,~)
            
            % Call superclass method
            obj.onResized@uiw.abstract.BaseDialog();
            
            % Ensure the construction is complete
            if obj.IsConstructed
                
                % What space do we have?
                [w,h] = obj.getInnerPixelSize();
                pad = obj.Padding;
                %spc = obj.Spacing;
                
                obj.h.Table.Position = [pad+1 pad+1 w-2*pad h-2*pad];

            end %if obj.IsConstructed
        end %functio

        function onButtonPressed(obj,action)
            
            % Assign output
            obj.Output = obj.SelectedRows;
            
            % Call superclass method
            obj.onButtonPressed@uiw.abstract.BaseDialog(action);

        end %function
        

    end % Protected methods



    %% Get/Set methods
    methods
        
        function value = get.DataTable(obj)
            value = obj.h.Table.DataTable;
        end
        function set.DataTable(obj,value)
            obj.h.Table.DataTable = value;
            obj.h.Table.sizeColumnsToData();
        end
        
        function value = get.SelectedRows(obj)
            value = obj.h.Table.SelectedRows;
        end
        function set.SelectedRows(obj,value)
            obj.h.Table.SelectedRows = value;
        end
        
        function value = get.MultiSelect(obj)
            value = ~strcmp(obj.h.Table.SelectionMode,'single');
        end
        function set.MultiSelect(obj,value)
            if value
                obj.h.Table.SelectionMode = 'discontiguous';
            else
                obj.h.Table.SelectionMode = 'single';
            end
        end
        
    end % Get/Set methods

end % classdef