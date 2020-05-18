classdef (Hidden, Abstract) HasKeyEvents < handle
    % HasKeyEvents - Mixin to provide key events for a widget
    % ---------------------------------------------------------------------
    % This is a mixin class. It provides key event handling for a widget.
    %
    % This class may change in the future.
    
%   Copyright 2018-2019 The MathWorks Inc.
    %
    % Auth/Revision:
    %   MathWorks Consulting
    %   $Author: rjackey $
    %   $Revision: 324 $  $Date: 2019-04-23 08:05:17 -0400 (Tue, 23 Apr 2019) $
    % ---------------------------------------------------------------------
    
    
    %% Events
    events
        KeyPress %Triggered on key release within the control
        KeyRelease %Triggered on key release within the control
    end
    
    
    
    %% Properties
    properties (Hidden, AbortSet)
        KeyPressFcn function_handle = function_handle.empty(0,1) %function handle to call when a key is pressed in the widget
        KeyReleaseFcn function_handle = function_handle.empty(0,1) %function handle to call when a key is released in the widget
    end
    
    
    %% Methods
    
    methods (Hidden, Access=protected)
        
        function onKeyPressed(obj,evt)
            % Triggered on key pressed
            
            % Trigger this event
            notify(obj,'KeyPress',evt);
            
            % Call the callback
            if ~isempty(obj.KeyPressFcn)
                obj.KeyPressFcn(obj, evt);
            end
            
        end %function
        
        
        function onKeyReleased(obj,evt)
            % Triggered on key pressed
            
            % Trigger this event
            notify(obj,'KeyRelease',evt);
            
            % Call the callback
            if ~isempty(obj.KeyReleaseFcn)
                obj.KeyReleaseFcn(obj, evt);
            end
            
        end %function
        
    end %methods
    
end %classdef