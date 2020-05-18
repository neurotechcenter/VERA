classdef (Hidden) KeyboardEvent < uiw.event.EventData
    % KeyboardEvent - Class for eventdata for keyboard actions
    % 
    % This class provides storage of data for a keyboard event
    %
    % Syntax:
    %           obj = uiw.event.KeyboardEvent
    %           obj = uiw.event.KeyboardEvent('Property','Value',...)
    %
    % This class may change in the future.
    
%   Copyright 2018-2019 The MathWorks Inc.
    %
    % Auth/Revision:
    %   MathWorks Consulting
    %   $Author: rjackey $
    %   $Revision: 324 $  $Date: 2019-04-23 08:05:17 -0400 (Tue, 23 Apr 2019) $
    % ---------------------------------------------------------------------
    
    
    %% Properties
    properties
        Character char
        Modifier cell
        Key char
        %Source
        %EventName
%         HitObject matlab.graphics.Graphics
%         MouseSelection matlab.graphics.Graphics
%         Axes matlab.graphics.axis.Axes
%         AxesPoint double
%         Figure matlab.ui.Figure
%         FigurePoint double
%         ScreenPoint double
    end %properties
  
    
    %% Constructor / destructor
    methods 
        
        function obj = KeyboardEvent(varargin)
            % Construct the event
            
            % Call superclass constructors
            obj@uiw.event.EventData(varargin{:});
            
        end %constructor
        
    end %methods
    
end % classdef