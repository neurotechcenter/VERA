classdef HasEditableTextField < uiw.mixin.HasEditableText
    % HasEditableTextField - Mixin for controls with a single editable text field
    %

%   Copyright 2017-2019 The MathWorks Inc.
    %
    % Auth/Revision:
    %   MathWorks Consulting
    %   $Author: rjackey $
    %   $Revision: 324 $  $Date: 2019-04-23 08:05:17 -0400 (Tue, 23 Apr 2019) $
    % ---------------------------------------------------------------------


    %% Properties
    properties (AbortSet)
        FieldType char {mustBeMember(FieldType,{'text','number','matrix','eval'})} = 'text' % Type of text entry for validation (['text'],'number','matrix','eval')
        Validator function_handle = function_handle.empty(0,0) % Custom validation function for text entry
        ShowDialogOnError (1,1) logical = true; % Should a dialog be presented on an invalid entry?
    end


    %% Protected methods
    methods (Access=protected)

        function StatusOk = checkValue(obj,value)
            % Return true if the value is valid

            if isempty(obj.Validator)
                % No validator - use FieldType to verify

                switch obj.FieldType

                    case 'text'

                        StatusOk = (ischar(value) && size(value,1)<=1) ||...
                            (( isscalar(value) && isstring(value) ));

                    case 'number'

                        StatusOk = (isnumeric(value) || islogical(value)) ...
                            && isscalar(value);

                    case 'matrix'

                        StatusOk = (isnumeric(value) || islogical(value));

                    case 'eval'

                        StatusOk = true;

                    otherwise
                        error('Unhandled FieldType');

                end %switch obj.FieldType

            else
                % Use validator

                try
                    obj.Validator(value);
                        StatusOk = true;
                catch err
                    StatusOk = false;
                    if obj.ShowDialogOnError
                        if isprop(obj,'LabelString')
                            title = obj.labelString;
                        else
                            title = 'Error';
                        end
                        hDlg = errordlg(err.message,title,'modal');
                        uiwait(hDlg);
                    end
                end

            end %if isempty(obj.Validator)

        end %function


        function value = interpretStringAsValue(obj,str)
            % Convert entered text to stored data type

            switch obj.FieldType
                case 'text'
                    value = char(str);
                case {'number','matrix'}
                    value = str2num(char(str)); %#ok<ST2NM>
                case 'eval'
                    value = eval(str);
            end

        end %function


        function str = interpretValueAsString(obj,value)
            % Convert stored data to displayed text

            switch obj.FieldType
                case 'text'
                    str = char(value);
                case 'number'
                    str = num2str(value);
                case 'matrix'
                    str = mat2str(value);
                case 'eval'
                    str = char(value);
            end

        end %function

    end % Protected methods


    %% Get/Set methods
    methods

        function set.FieldType(obj,value)
            value = validatestring(value,{'text','number','matrix','eval'});
            obj.FieldType = value;
        end

        function set.ShowDialogOnError(obj,value)
            validateattributes(value,{'logical'},{'scalar'});
            obj.ShowDialogOnError = value;
        end

    end % Get/Set methods

end % classdef