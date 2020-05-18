classdef (HandleCompatible) DisplayNonScalarObjectAsTable < matlab.mixin.CustomDisplay
    % DisplayNonScalarObjectAsTable -
    % ---------------------------------------------------------------------
    % Abstract: This mixin class overrides displayNonScalarObject() to
    % display an array of objects as a table.
    %
    
    %   Copyright 2018-2019 The MathWorks, Inc.
    %
    % Auth/Revision:
    %   MathWorks Consulting
    %   $Author: rjackey $
    %   $Revision: 348 $  $Date: 2018-03-02 15:51:54 -0500 (Fri, 02 Mar 2018) $
    % ---------------------------------------------------------------------
    
    
    %% Public Methods
    methods (Sealed)
        
        function t = toDisplayTable(obj)
            % Convert the object to a table
            
            % Prepare the table
            t = array2table(zeros(numel(obj),0));
            
            % Check for any invalid handle objects
            if ishandle(obj)
                isOk = isvalid(obj);
            else
                isOk = true(size(obj));
            end
            
            % Get the property list
            props = properties(obj);
            
            % Populate the table variables
            if verLessThan('matlab','9.5')
                % For R2017b compatibility
                for pIdx = 1:numel(props)
                    thisProp = props{pIdx};
                    thisValues = {obj(isOk).(thisProp)}';
                    t(isOk,end+1) = array2table(thisValues); %#ok<AGROW>
                end
                t.Properties.VariableNames = props;
            else
                % Faster implementation for later releases
                for thisProp = string(props)'
                    thisValues = {obj(isOk).(thisProp)}';
                    t.(thisProp)(isOk) = thisValues;
                end
            end
            
            % Prepare indices as row names
            if isrow(obj)
                indices = string(1:numel(obj))';
            else
                varargout = cell(1,ndims(obj));
                [varargout{:}] = ind2sub(size(obj),1:numel(obj));
                indices = string(vertcat(varargout{:})');
                indices = join(indices,',',2);
            end
            rowNames = "(" + indices + ")";
            rowNames(~isOk) = rowNames(~isOk) + "deleted handle";
            if verLessThan('matlab','9.5')
                % For R2017b compatibility
                t.Properties.RowNames = cellstr(rowNames);
            else
                % Faster implementation for later releases
                t.Properties.RowNames = rowNames;
            end

            
        end %function
        
    end %methods
    
    
    %% Protected Methods
    methods (Sealed, Access=protected)
        
        function displayNonScalarObject(obj)
            
            % Format text to display
            className = matlab.mixin.CustomDisplay.getClassNameForHeader(obj);
            dimStr = matlab.mixin.CustomDisplay.convertDimensionsToString(obj);
            
            % Display the header
            if isa(obj,'matlab.mixin.Heterogeneous')
                fprintf('  %s Heterogeneous %s with common properties:\n\n',dimStr,className);
            else
                fprintf('  %s %s with properties:\n\n',dimStr,className);
            end
            
            % Show the group list in a table
            disp( obj.toDisplayTable() );
            
        end %function
        
    end %methods
    
    
end % classdef
