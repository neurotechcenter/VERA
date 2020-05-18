classdef PlotType
    % PlotType - enumeration of different plot types
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
        Fraction('Fraction')
        Quantity('Quantity')
        Mean('Mean')
    end %enumeration
    
    
    %% Properties
    
    properties (Transient, SetAccess='immutable')
        String char
        Label char
    end %properties
    
    
    %% Constructor
    methods
        function obj = PlotType(str)
            
            obj.String = str;
            
            switch str
                case 'Fraction'
                    
                    obj.Label = 'Fraction of flights delayed';
                    
                case 'Quantity'
                    
                    obj.Label = 'Total quantity of flights delayed';
                    
                case 'Mean'
                    
                    obj.Label = 'Mean flight delay';
                    
            end %switch
            
        end %function
    end %methods
    
end % classdef
