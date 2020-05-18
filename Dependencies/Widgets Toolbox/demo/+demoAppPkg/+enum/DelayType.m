classdef DelayType
    % DelayType - enumeration of different delay types
    % ---------------------------------------------------------------------
    %
    
%   Copyright 2018-2019 The MathWorks Inc.
    %
    % Auth/Revision:
    %   MathWorks Consulting
    %   $Author: rjackey $
    %   $Revision: 324 $  $Date: 2019-04-23 08:05:17 -0400 (Tue, 23 Apr 2019) $
    % ---------------------------------------------------------------------
    
    %% Enumerations
    
    enumeration
        Departure('Departure')
        Arrival('Arrival')
    end %enumeration
    
    
    %% Properties
    
    properties (Transient, SetAccess='immutable')
        String char
    end %properties
    
    
    %% Constructor
    methods
        function obj = DelayType(str)
            
            obj.String = str;
            
        end %function
    end %methods
    
end % classdef