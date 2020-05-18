classdef CheckboxTreeNode < uiw.widget.TreeNode
    % CheckboxTreeNode - Node for a checkbox tree control
    %
    % Create a checkboxtree node object to be placed on a
    % uiw.widget.CheckboxTree control.
    %
    % Syntax:
    %   nObj = uiw.widget.CheckboxTreeNode
    %   nObj = uiw.widget.CheckboxTreeNode('Property','Value',...)
    %
    % Notes:
    %   - The CheckboxTreeNode may be also used on a uiw.widget.Tree
    %   control, but the checkboxes will not be visible. This may be useful
    %   if you are mixing regular trees with checkbox trees, and want to
    %   use a uniform type of TreeNode or need to be able to drag and drop
    %   from one tree to another.
    %
    % See also: uiw.widget.Tree, uiw.widget.CheckboxTree,
    %           uiw.widget.TreeNode,
    %
    %
    
%   Copyright 2012-2019 The MathWorks Inc.
    %
    % Auth/Revision:
    %   MathWorks Consulting
    %   $Author: rjackey $
    %   $Revision: 324 $  $Date: 2019-04-23 08:05:17 -0400 (Tue, 23 Apr 2019) $
    % ---------------------------------------------------------------------
    
    
    %% Properties
    properties (Dependent)
        CheckboxEnabled %Indicates whether checkbox on this node may be selected with the mouse
        CheckboxVisible %Indicates whether checkbox on this node is visible
        Checked %Indicates whether checkbox on this node is checked
    end
    
    properties (Dependent)
        PartiallyChecked %Indicates whether checkbox on this node is partially checked (read-only, used only in DigIn mode)
    end
    
    
    %% Constructor / Destructor
    methods
        
        function nObj = CheckboxTreeNode(varargin)
            % Construct the node
            
            % Call superclass constructor
            nObj = nObj@uiw.widget.TreeNode(varargin{:});
            
        end
        
    end %methods - constructor/destructor
    
    
    
    %% Public Methods
    methods
        
        function nObjCopy = copy(nObj,NewParent)
            % copy - Copy a TreeNode object
            % -------------------------------------------------------------------------
            % Abstract: Copy a TreeNode object
            %
            % Syntax:
            %           nObj.copy()
            %
            % Inputs:
            %           nObj - TreeNode object to copy
            %           NewParent - new parent TreeNode object
            %
            % Outputs:
            %           nObjCopy - copy of TreeNode object
            %
            
            % Call the superclass copy
            nObjCopy = copy@uiw.widget.TreeNode(nObj,NewParent);
            
            % Copy the CheckboxTreeNode properties
            for idx = 1:numel(nObj)
                nObjCopy(idx).CheckboxEnabled = nObj(idx).CheckboxEnabled;
                nObjCopy(idx).CheckboxVisible = nObj(idx).CheckboxVisible;
                nObjCopy(idx).Checked = nObj(idx).Checked;
            end
        end
        
    end %public methods
    
    
    
    %% Get/Set methods
    methods
        
        % CheckboxEnabled
        function value = get.CheckboxEnabled(nObj)
            value = nObj.JNode.CheckBoxEnabled;
        end
        function set.CheckboxEnabled(nObj,value)
            validateattributes(value,{'numeric','logical'},{'scalar'});
            nObj.JNode.CheckBoxEnabled = logical(value);
            nodeChanged(nObj.Tree, nObj)
        end
        
        % CheckboxVisible
        function value = get.CheckboxVisible(nObj)
            value = nObj.JNode.CheckBoxVisible;
        end
        function set.CheckboxVisible(nObj,value)
            validateattributes(value,{'numeric','logical'},{'scalar'});
            nObj.JNode.CheckBoxVisible = logical(value);
            nodeChanged(nObj.Tree, nObj)
        end
        
        % Checked
        function value = get.Checked(nObj)
            value = true(1,0);
            if ~isempty(nObj.Tree) && isa(nObj.Tree,'uiw.widget.CheckboxTree')
                value = isNodeChecked(nObj.Tree,nObj);
            end
        end
        function set.Checked(nObj,value)
            validateattributes(value,{'numeric','logical'},{'scalar'});
            setChecked(nObj.Tree,nObj,value);
        end
        
        % PartiallyChecked
        function value = get.PartiallyChecked(nObj)
            value = true(1,0);
            if ~isempty(nObj.Tree) && isa(nObj.Tree,'uiw.widget.CheckboxTree')
                value = isNodePartiallyChecked(nObj.Tree,nObj);
            end
        end
        
    end %get/set methods
    
end %classdef
