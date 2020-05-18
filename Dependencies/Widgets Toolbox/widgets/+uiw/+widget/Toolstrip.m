classdef (Hidden) Toolstrip < uiw.widget.Toolbar
    % Toolstrip - For Backward Compatibility Only
    %
    % Toolstrip has been renamed to Toolbar to accurately reflect its
    % functionality. This class is only for backward compatibility. Please
    % use Toolbar instead.
    %
    
%   Copyright 2017-2019 The MathWorks Inc.
    %
    % Auth/Revision:
    %   MathWorks Consulting
    %   $Author: rjackey $
    %   $Revision: 324 $
    %   $Date: 2019-04-23 08:05:17 -0400 (Tue, 23 Apr 2019) $
    % ---------------------------------------------------------------------
    
    % This class is only for backward compatibility. 
    % Please see uiw.widget.Toolbar instead.
    
    
    %% Constructor / Destructor
    methods
        
        function obj = Toolstrip(varargin)
            obj@uiw.widget.Toolbar(varargin{:});
        end %constructor
        
    end %methods - constructor/destructor
    
end %classdef