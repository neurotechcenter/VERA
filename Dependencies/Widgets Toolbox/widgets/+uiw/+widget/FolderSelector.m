classdef FolderSelector < uiw.abstract.EditableTextWithButton
    % FolderSelector - A folder selection control with browse button
    %
    % Create a widget that allows you to specify a folder by editable
    % text or by dialog. Optimum height of this control is 25 pixels.
    %
    % Syntax:
    %           w = uiw.widget.FolderSelector('Property','Value',...)
    %
    
%   Copyright 2005-2019 The MathWorks Inc.
    %
    % Auth/Revision:
    %   MathWorks Consulting
    %   $Author: rjackey $
    %   $Revision: 324 $
    %   $Date: 2019-04-23 08:05:17 -0400 (Tue, 23 Apr 2019) $
    % ---------------------------------------------------------------------
    
    
    %% Public properties
    properties
        DefaultDirectory char %Optional default directory to start in when Value does not exist and user clicks the browse button.
        RootDirectory char %Optional root directory. If unspecified, Value uses an absolute path (default). If specified, Value will show a relative path to the root directory. ['']
        RequireSubdirOfRoot logical = true %Indicates whether the Value must be a subdirectory of the RootDirectory. If false, the value could be a directory above RootDirectory expressed with '..\' to go up levels in the hierarchy. [(true)|false].
    end
    
    properties (SetAccess=protected, Dependent = true)
        FullPath % Absolute path to the file. If RootDirectory is used, this equals fullfile(obj.RootDirectory, obj.Value). Otherwise, it is the same as obj.Value.
    end
    
    
    %% Constructor / Destructor
    methods
        
        function obj = FolderSelector(varargin)
            % Construct the control
            
            % Update some details in the GUI elements
            set(obj.hEditBox,  'HorizontalAlignment', 'left', ...
                'Tooltip', 'Edit the path' );
            set(obj.hButton,...
                'CData', uiw.utility.loadIcon( @()imread('folder_24.png') ), ...
                'Tooltip', 'Click to browse' );
            obj.Padding = 0;
            obj.Value = '';
            
            % Set properties from P-V pairs
            obj.assignPVPairs(varargin{:});
            
            % Assign the construction flag
            obj.IsConstructed = true;
            
            % Redraw the widget
            obj.onResized();
            obj.onEnableChanged();
            obj.onStyleChanged();
            obj.redraw();
            
        end % constructor
        
    end %methods - constructor/destructor
    
    
    
    %% Protected methods
    methods (Access=protected)
        
        function StatusOk = checkValue(obj, value)
            % Return true if the value is valid
            
            StatusOk = true;
            
            % Ensure the construction is complete
            if obj.IsConstructed
                
                if ~( ischar(value) || ( isscalar(value) && isstring(value) ) )
                    error( 'uiw:widget:FolderSelector:BadValue',...
                        'Value must be a character array' )
                end
                
                % Update validity by file existance or not
                obj.TextIsValid = checkPathExists(obj,value);
                
            end %if obj.IsConstructed
            
        end %function checkValue
        
        
        
        function onButtonClick(obj)
            % Triggered on button press
            
            if exist(obj.FullPath,'dir')
                StartPath = obj.FullPath;
            elseif exist(obj.DefaultDirectory,'dir')
                StartPath = obj.DefaultDirectory;
            else
                StartPath = pwd;
            end
            
            if strcmpi( obj.Enable, 'ON' )
                foldername = uigetdir( ...
                    StartPath, ...
                    'Select a folder' );
                if isempty( foldername ) || isequal( foldername, 0 )
                    % Cancelled
                else
                    oldValue = obj.Value;
                    obj.FullPath = foldername;
                    
                    % Call callback
                    evt = struct( 'Source', obj, ...
                        'Interaction', 'Dialog', ...
                        'OldValue', oldValue, ...
                        'NewValue', obj.Value );
                    obj.callCallback(evt);
                end
                
            end %if strcmpi(obj.Enable,'ON')
        end % onButtonClick
        
        
        function PathExists = checkPathExists(obj,RelPath)
            % Verify whether the path exists
            
            ThisPath = fullfile(obj.RootDirectory, RelPath);
            PathExists = ~isempty(dir(ThisPath));
            
        end %function checkValidPath
        
    end % Protected methods
    
    
    
    %% Get/Set methods
    methods
        
        
        function set.RootDirectory(obj,value)
            validateattributes(value,{'char'},{},'','RootDirectory')
            obj.RootDirectory = value;
        end
        
        
        function set.RequireSubdirOfRoot(obj,value)
            validateattributes(value,{'logical'},{'scalar'},'','RequireSubdirOfRoot')
            obj.RequireSubdirOfRoot = value;
        end
        
        
        function value = get.FullPath(obj)
            value = fullfile(obj.RootDirectory, obj.Value);
        end
        function set.FullPath(obj,value)
            validateattributes(value,{'char'},{})
            try
                obj.Value = uiw.utility.getRelativeFilePath(value,...
                    obj.RootDirectory, obj.RequireSubdirOfRoot);
            catch err
                hDlg = errordlg(err.message,'File Selection','modal');
                uiwait(hDlg);
            end
        end
        
        
    end % Get/Set methods
    
end % classdef