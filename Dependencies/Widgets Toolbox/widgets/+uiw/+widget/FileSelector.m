classdef FileSelector < uiw.widget.FolderSelector
    % FileSelector - A file selection control with browse button
    %
    % Create a widget that allows you to specify a filename by editable
    % text or by dialog. Optimum height of this control is 25 pixels.
    %
    % Syntax:
    %           w = uiw.widget.FileSelector('Property','Value',...)
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
    properties
        Pattern cell = {'*.mat','MATLAB MAT files (*.mat)'} %cell array of all items to select from [{'*.mat';'MATLAB MAT files (*.*)'}]
        Mode char = 'get' %File selection dialog mode: [('get')|'put'] 'get'=uigetfile, 'put'=uiputfile
    end
    
    
    %% Constructor / Destructor
    methods
        
        function obj = FileSelector(varargin)
            % Construct the control
            
            % Call superclass constructors
            obj = obj@uiw.widget.FolderSelector(varargin{:});
            
            % Modifications for file selection
            set(obj.hButton,'CData',uiw.utility.loadIcon(@()imread('folder_file_24.png')))
            
        end % constructor
        
    end %methods - constructor/destructor
    
    
    
    %% Protected methods
    methods (Access=protected)
        
        
        function PathExists = checkPathExists(obj,RelPath)
            % Verify whether the path exists
            
            ThisPath = fullfile(obj.RootDirectory, RelPath);
            ParentDir = fileparts(ThisPath);
            PathExists = ...
                ( strcmpi(obj.Mode,'get') && ~isempty(dir(ThisPath)) )|| ...
                ( strcmpi(obj.Mode,'put') && ~isempty(dir(ParentDir)) );
            % PathExists = ...
            %     ( strcmpi(obj.Mode,'get') && exist(ThisPath,'file')==2 )|| ...
            %     ( strcmpi(obj.Mode,'put') && exist(ParentDir,'dir') );
            
        end %function checkValidPath
        
        
        function onButtonClick(obj,~,~)
            % Triggered on button press
            
            if strcmpi(obj.Enable,'ON')
                
                if exist(obj.FullPath,'file')
                    StartPath = obj.FullPath;
                elseif exist(obj.DefaultDirectory,'dir')
                    StartPath = obj.DefaultDirectory;
                else
                    StartPath = pwd;
                end
                
                if strcmpi( obj.Mode, 'get' )
                    [filename,pathname] = uigetfile( ...
                        obj.Pattern, ...
                        'Select a file', ...
                        StartPath );
                else
                    [filename,pathname] = uiputfile( ...
                        obj.Pattern, ...
                        'Select a file', ...
                        StartPath );
                end
                
                if isempty(filename) || isequal( filename, 0 )
                    % Cancelled
                else
                    oldValue = obj.Value;
                    obj.FullPath = fullfile(pathname,filename);
                    
                    % Call callback
                    evt = struct( 'Source', obj, ...
                        'Interaction', 'Dialog', ...
                        'OldValue', oldValue, ...
                        'NewValue', obj.Value );
                    obj.callCallback(evt);
                end
                
            end %if strcmpi(obj.Enable,'ON')
        end % onButtonClick
        
    end % Protected methods
    
    
    
    %% Get/Set methods
    methods
        
        function set.Pattern(obj,value)
            if ~(iscell( value ) || isstring( value )) ...
                    || isempty( value ) ...
                    || size( value, 2 )>2 ...
                    || any( ~cellfun( @ischar, value(:) ) )
                error( 'uiw:widget:FileSelector:BadFilePattern', 'Property ''Pattern'' must be a valid file filter specification suitable for use with UIGETFILE. See <a href="matlab:doc uigetfile">UIGETFILE documentation</a> for details.' );
            end
            obj.Pattern = value;
        end
        
        function set.Mode(obj,value)
            value = validatestring(value,{'get','put'},'','RootDirectory');
            obj.Mode = value;
        end
        
    end % Get/Set methods
    
end % classdef