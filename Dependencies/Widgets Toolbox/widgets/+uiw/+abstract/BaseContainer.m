classdef (Abstract) BaseContainer < uix.Container & uiw.mixin.HasContainer
    % BaseContainer - Base class for a container
    %
    % This class provides a container and sizing utilities for
    % widgets, dialogs, etc.
    %
    
%   Copyright 2017-2019 The MathWorks Inc.
    %
    % Auth/Revision:
    %   MathWorks Consulting
    %   $Author: rjackey $
    %   $Revision: 324 $  $Date: 2019-04-23 08:05:17 -0400 (Tue, 23 Apr 2019) $
    % ---------------------------------------------------------------------
    
    %% Properties
    properties (Access=private)
        DestroyedListener %Listener for container destroyed
        VisibleChangedListener %Listener for visibility changes
        SizeChangedListener %Listener for resize of container
        StyleChangedListener %Listener for container style changes
    end
    
    
    
    %% Abstract Methods
    methods (Abstract, Access=protected) %Must be defined in subclass
        onContainerResized(obj) %Triggered on resize of the container
        onStyleChanged(obj,evt) %Handle updates to style changes - subclass must implement
    end %methods
    
    
    
    %% Constructor / destructor
    methods
        
        function obj = BaseContainer()
            % Construct the container
            
            % Attach listeners and callbacks
            obj.DestroyedListener = event.listener(obj,...
                'ObjectBeingDestroyed',@(h,e)onContainerBeingDestroyed(obj));
            obj.SizeChangedListener = event.listener(obj,...
                'SizeChanged',@(h,e)onContainerResized(obj));
            obj.StyleChangedListener = event.proplistener(obj,...
                findprop(obj,'BackgroundColor'),'PostSet',@(h,e)onStyleChanged(obj,e));
            obj.VisibleChangedListener = event.proplistener(obj,...
                findprop(obj,'Visible'),'PostSet',@(h,e)onVisibleChanged(obj));
            
        end %constructor
        
    end %methods
    
    
    
    %% Sealed Protected methods
    methods (Sealed, Access=protected)
        
        function pos = getPixelPosition(obj,recursive)
            % Return the container's pixel position
            
            if strcmp(obj.Units,'pixels') && (nargin<2 || ~recursive)
                pos = obj.Position;
            else
                pos = getpixelposition(obj, recursive);
                pos = ceil(pos);
            end
            
        end %function
        
        
        function [w,h] = getPixelSize(obj)
            % Return the container's outer pixel size
            
            if strcmp(obj.Units,'pixels')
                pos = obj.Position;
            else
                pos = getpixelposition(obj,false);
            end
            w = max(pos(3), 10);
            h = max(pos(4), 10);
        end %function
        
    end %methods
    
    
    
    %% Protected methods
    methods (Access=protected)
        
        function onVisibleChanged(~)
            % Handle updates to Visible state - subclass may override
            
        end %function
        
        
        function onContainerBeingDestroyed(obj)
            % Triggered on container destroyed - subclass may override
            
            delete(obj);
            
        end %function
        
    end %methods
    
end % classdef