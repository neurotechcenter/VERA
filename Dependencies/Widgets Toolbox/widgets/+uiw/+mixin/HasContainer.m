classdef HasContainer < uiw.mixin.AssignPVPairs & matlab.mixin.SetGet & ...
        matlab.mixin.CustomDisplay
    % HasContainer - Mixin class for a graphical widget container
    %
    % This class provides common properties and methods that are used by a
    % widget, specifically those that may need to be inherited from
    % multiple related classes. They are defined here instead of
    % uiw.abstract.HasContainer, because we don't want the
    % uiw.abstract.HasContainer constructor to run multiple times for an
    % object that is using multiple inheritance.
    %
    
%   Copyright 2017-2019 The MathWorks Inc.
    %
    % Auth/Revision:
    %   MathWorks Consulting
    %   $Author: rjackey $
    %   $Revision: 324 $
    %   $Date: 2019-04-23 08:05:17 -0400 (Tue, 23 Apr 2019) $
    % ---------------------------------------------------------------------
    
    %% Properties
    properties (AbortSet)
        Enable = 'on' %Allow interaction with this widget [(on)|off]
        Padding = 0 %Pixel spacing around the widget (applies to some widgets)
        Spacing = 4 %Pixel spacing between controls (applies to some widgets)
    end %properties
    
    properties (SetAccess=protected)
        h struct = struct() %For widgets to store internal graphics objects
        hLayout struct = struct() %For widgets to store internal layout objects
        IsConstructed logical = false %Indicates widget has completed construction, useful for optimal performance to minimize redraws on launch, etc.
    end %properties
    
    
    %% Abstract Methods
    methods (Abstract, Access=protected)
        redraw(obj) %Handle state changes that may need UI redraw - subclass must override
        onResized(obj) %Handle changes to widget size - subclass must override
        onContainerResized(obj) %Triggered on resize of the widget's container - subclass must override
    end %methods
    
    
    %% Protected methods
    methods (Access=protected)
        
        function onEnableChanged(obj,hAdd)
            % Handle updates to Enable state - subclass may override
            
            % Ensure the construction is complete
            if obj.IsConstructed
                
                % Look for all encapsulated graphics objects in "h" property
                hAll = obj.findHandleObjects();
                
                % Combine them all
                if nargin>1 && ~isempty(hAdd) && all(ishghandle(hAdd))
                    hAll = unique([hAll(:); hAdd(:)]);
                end
                
                % Default behavior: Set all objects with an Enable field
                hHasEnable = hAll( isprop(hAll,'Enable') );
                set(hHasEnable,'Enable',obj.Enable);
                
            end %if obj.IsConstructed
            
        end %function
        
        
        function onVisibleChanged(obj)
            % Handle updates to Visible state - subclass may override
            
            % Ensure the construction is complete
            if obj.IsConstructed
                
            end %if obj.IsConstructed
            
        end %function
        
        
        function onStyleChanged(obj,hAdd)
            % Handle updates to style changes - subclass may override
            
            % Ensure the construction is complete
            if obj.IsConstructed
                
                % Look for all encapsulated graphics objects in "h" property
                hAll = obj.findHandleObjects();
                
                % Combine them all
                if nargin>1 && ~isempty(hAdd)
                    hAll = unique([hAll(:); hAdd(:)]);
                end
                
                % Set all objects that have font props
                if isprop(obj,'FontName')
                    set(hAll( isprop(hAll,'FontName') ),...
                        'FontName',obj.FontName,...
                        'FontSize',obj.FontSize);
                    set(hAll( isprop(hAll,'FontUnits') ),...
                        'FontWeight',obj.FontWeight,...
                        'FontAngle',obj.FontAngle,...
                        'FontUnits',obj.FontUnits);
                end
                
                % Set all objects that have ForegroundColor
                % Exclude boxpanels
                if isprop(obj,'ForegroundColor')
                    isBoxPanel = arrayfun(@(x)isa(x,'uix.BoxPanel'),hAll);
                    set(hAll( isprop(hAll,'ForegroundColor') & ~isBoxPanel ),...
                        'ForegroundColor',obj.ForegroundColor);
                end
                
                % Set all objects that have BackgroundColor
                if isprop(obj,'BackgroundColor')
                    hasBGColor = isprop(hAll,'BackgroundColor');
                    set(hAll( hasBGColor ),...
                        'BackgroundColor',obj.BackgroundColor);
                end
                
            end %if obj.IsConstructed
            
        end %function
        
        
        function hAll = findHandleObjects(obj)
            
            % Look for all encapsulated graphics objects in "h" property
            %hEncapsulatedCell = struct2cell(obj.h);
            hEncapsulatedCell = [struct2cell(obj.h); struct2cell(obj.hLayout)];
            isGraphicsObj = cellfun(@ishghandle,hEncapsulatedCell,'UniformOutput',false);
            isGraphicsObj = cellfun(@all,isGraphicsObj,'UniformOutput',true);
            hAll = [hEncapsulatedCell{isGraphicsObj}]';
            
        end %function
        
    end %methods
    
    
    
    %% Get/Set methods
    methods
        
        % Enable
        function set.Enable(obj,value)
            value = validatestring(value,{'on','off'});
            evt = struct('Property','Enable',...
                'OldValue',obj.Enable,...
                'NewValue',value);
            obj.Enable = value;
            obj.onEnableChanged(evt);
        end
        
        % Padding
        function set.Padding(obj,value)
            validateattributes(value,{'numeric'},{'real','nonnegative','scalar','finite'})
            obj.Padding = value;
            obj.onContainerResized();
        end
        
        % Spacing
        function set.Spacing(obj,value)
            validateattributes(value,{'numeric'},{'real','nonnegative','scalar','finite'})
            obj.Spacing = value;
            obj.onContainerResized();
        end
        
        % IsConstructed
        function value = get.IsConstructed(obj)
            value = isvalid(obj) && obj.IsConstructed;
        end
        
    end % Get/Set methods
    
    
end % classdef
