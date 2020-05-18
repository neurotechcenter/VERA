classdef (Hidden) FixedText < uiw.widget.Text
    % FixedText - For Backward Compatibility Only
    %
    % FixedText has been renamed to Text to accurately reflect its
    % functionality. This class is only for backward compatibility. Please
    % use Text instead.
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
    % Please see uiw.widget.Text instead.
    
    
    %% Constructor / Destructor
    methods
        
        function obj = FixedText(varargin)
            obj@uiw.widget.Text(varargin{:});
        end %constructor
        
    end %methods - constructor/destructor
    
end % classdef
