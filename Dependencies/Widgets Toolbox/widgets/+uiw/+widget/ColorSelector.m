classdef ColorSelector < uiw.abstract.EditableTextWithButton
    % ColorSelector - A color selection control
    %
    % Create a widget that allows you to specify a color.
    %
    % Syntax:
    %           w = uiw.widget.ColorSelector('Property','Value',...)
    %
    
%   Copyright 2005-2019 The MathWorks Inc.
    %
    % Auth/Revision:
    %   MathWorks Consulting
    %   $Author: rjackey $
    %   $Revision: 324 $
    %   $Date: 2019-04-23 08:05:17 -0400 (Tue, 23 Apr 2019) $
    % ---------------------------------------------------------------------
    
    
    %% Constructor / Destructor
    methods
        
        function obj = ColorSelector(varargin)
            % Construct the control
            
            % Call superclass constructor
            obj@uiw.abstract.EditableTextWithButton();
            
            % Update some details in the GUI elements
            set(obj.hEditBox, 'HorizontalAlignment','right',...
                'Tooltip', 'Specify a color by [r,g,b]' );
            set(obj.hButton,'String','','Tooltip','Click to open the color palette');
            obj.Value = [0 0 0];
            
            % Populate public properties from P-V input pairs
            obj.assignPVPairs(varargin{:});
            
            % Assign the construction flag
            obj.IsConstructed = true;
            
            % Redraw the widget
            obj.onResized();
            obj.onEnableChanged();
            obj.redraw();
            obj.onStyleChanged();
            
        end % constructor
        
    end %methods - constructor/destructor
    
    
    %% Protected methods
    methods (Access=protected)
        
        function redraw(obj)
            % Handle state changes that may need UI redraw
            
            % Ensure the construction is complete
            if obj.IsConstructed
                
                % Update the CData of the button
                sz = size(obj.hButton.CData);
                ind = round(linspace(1, size(obj.Value,1), sz(1))');
                cData = ind2rgb(ind,obj.Value);
                cData = repmat(cData, [1 sz(2) 1]);
                obj.hButton.CData = cData;
                
            end %if obj.IsConstructed
            
        end %function
        
        
        function onResized(obj)
            % Handle changes to widget size
            
            % Ensure the construction is complete
            if obj.IsConstructed
                
                % Call superclass methods
                onResized@uiw.abstract.EditableTextWithButton(obj);
                
                % Resize the CData of the button
                sz = max(8, floor(obj.hButton.Position([4 3])) - 10);
                if sz ~= size(obj.hButton.CData,1)
                    obj.hButton.CData(sz(1),sz(2),3) = 0;
                    obj.hButton.CData( (sz(1)+1):end, :, : ) = [];
                    obj.hButton.CData( :, (sz(2)+1):end, : ) = [];
                    obj.redraw();
                end
                
            end %if obj.IsConstructed
            
        end %function
        
        
        function StatusOk = checkValue(~, value)
            % Return true if the value is valid
            
            StatusOk = isnumeric( value ) && size( value,2 )==3 &&...
                ~any(value(:)>1) && ~any(value(:)<0); %Nan ok
            
        end %function
        
        
        function value = interpretStringAsValue(~, str)
            % Convert entered text to stored data type
            
            try
                value = uiw.utility.interpretColor( str );
            catch err %#ok<NASGU>
                value = []; % If it didn't work, return empty
            end
            
        end %function
        
        
        function str = interpretValueAsString(~, value)
            % Convert stored data to displayed text
            
            str = mat2str(value);
            
        end %function
        
        
        function onButtonClick(obj)
            % Triggered on button press
            
            if strcmpi(obj.Enable,'on')
                oldValue = obj.Value;
                if numel(oldValue)==3 && all(oldValue>=0) && all(oldValue<=1)
                    newValue = uisetcolor( oldValue, 'Select a color'  );
                else
                    newValue = uisetcolor( [], 'Select a color' );
                end
                
                if ~isempty(newValue)
                    newValue = roundn(newValue,-2);
                    evt = struct( 'Source', obj, ...
                        'Interaction', 'Dialog', ...
                        'OldValue', obj.Value, ...
                        'NewValue', newValue );
                    obj.Value = newValue;
                    obj.redraw()
                    obj.callCallback(evt);
                end
            end
            
        end % onButtonClick
        
    end % Protected methods
    
end % classdef
