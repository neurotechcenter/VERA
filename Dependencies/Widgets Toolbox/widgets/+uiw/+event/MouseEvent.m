classdef MouseEvent < uiw.event.EventData
    % MouseEvent - Class for eventdata for mouse actions
    % 
    % This class provides storage of data for a mouse event
    %
    % Syntax:
    %           obj = uiw.event.MouseEvent
    %           obj = uiw.event.MouseEvent('Property','Value',...)
    %
    
%   Copyright 2017-2019 The MathWorks Inc.
    %
    % Auth/Revision:
    %   MathWorks Consulting
    %   $Author: rjackey $
    %   $Revision: 324 $  $Date: 2019-04-23 08:05:17 -0400 (Tue, 23 Apr 2019) $
    % ---------------------------------------------------------------------
    
    
    %% Properties
    properties
        HitObject matlab.graphics.Graphics
        MouseSelection matlab.graphics.Graphics
        Axes matlab.graphics.axis.AbstractAxes
        AxesPoint double
        Figure matlab.ui.Figure
        FigurePoint double
        ScreenPoint double
    end %properties
  
    
    %% Constructor / destructor
    methods
        
        function obj = MouseEvent(varargin)
            % Construct the event
            
            % Call superclass constructors
            obj@uiw.event.EventData(varargin{:});
            
        end %constructor
        
    end %methods
    
end % classdef