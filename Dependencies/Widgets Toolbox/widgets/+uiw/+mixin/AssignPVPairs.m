classdef (Abstract) AssignPVPairs < handle & matlab.mixin.SetGet
    % AssignPVPairs - Mixin to assign PV pairs to public properties
    % ---------------------------------------------------------------------
    % This mixin class provides a method to assign PV pairs to populate
    % public properties of a handle object. This is typically performed in
    % a constructor.
    %
    % The class must inherit this object to access the method. Call the
    % protected method like this to assign properties:
    %
    %     % Assign PV pairs to properties
    %     obj.assignPVPairs(varargin{:});
    %
    %       or
    %
    %     % Assign PV pairs to properties and return non-matches
    %     UnmatchedPairs = obj.assignPVPairs(varargin{:});
    %
    % Methods of uiw.abstract.AssignPVPairs:
    %
    %   varargout = assignPVPairs(obj,varargin) - assigns the
    %   property-value pairs to matching properties of the object
    %
    
%   Copyright 2015-2019 The MathWorks Inc.
    %
    % Auth/Revision:
    %   MathWorks Consulting
    %   $Author: rjackey $
    %   $Revision: 324 $  $Date: 2019-04-23 08:05:17 -0400 (Tue, 23 Apr 2019) $
    % ---------------------------------------------------------------------
    
    % This class is similar to
    % matlab.io.internal.mixin.HasPropertiesAsNVPairs, but this one
    % generally performs faster.
    
    %% Protected Methods
    
    methods (Access=protected)
        
        function varargout = assignPVPairs(obj,varargin)
            % Assign the specified property-value pairs
            
            if nargin > 1
                
                % Get a singleton parser for this class
                keepUnmatched = nargout > 0;
                p = getParser(obj, keepUnmatched);
                
                % Parse the P-V pairs
                p.parse(varargin{:});
                
                % Set just the parameters the user passed in
                ParamNamesToSet = varargin(1:2:end);
                ParamsInResults = fieldnames(p.Results);
                
                % Assign properties
                for ThisName = ParamNamesToSet
                    isSettable = any(strcmpi(ThisName,ParamsInResults));
                    if isSettable && ~any(strcmpi(ThisName,p.UsingDefaults))
                        obj.(ThisName{1}) = p.Results.(ThisName{1});
                    end
                end
                
                % Return unmatched pairs
                if nargout
                    varargout{1} = p.Unmatched;
                end
                
            elseif nargout
                
                varargout{1} = struct;
                
            end %if nargin > 1
            
        end %function
        
    end %methods
        
        
    %% Static, Sealed Methods
    methods (Static, Sealed)
        
        function  [splitArgs,remArgs] = splitArgs(argnames,varargin)
            % Separate specified P-V arguments from the rest of P-V pairs
            
            narginchk(1,inf) ;
            splitArgs = {};
            remArgs = {};
            
            if nargin>1
                props = varargin(1:2:end);
                values = varargin(2:2:end);
                if ( numel( props ) ~= numel( values ) ) || any( ~cellfun( @ischar, props ) )
                    error( 'uiw:utility:splitArgs:BadSyntax', 'Arguments must be supplied as property-value pairs' );
                end
                ToSplit = ismember(props,argnames);
                ToSplit = reshape([ToSplit; ToSplit],1,[]);
                splitArgs = varargin(ToSplit);
                remArgs = varargin(~ToSplit);
            end
            
        end %function
        
        
        function [remaningArgs,removedArgValue] = removeArg(argname, varargin )
            % Remove specified argument from the rest of P-V pairs
            
            narginchk( 1, inf ) ;
            removedArgValue = [];
            remaningArgs = {};
            
            if nargin>1
                props = varargin(1:2:end);
                values = varargin(2:2:end);
                if ( numel( props ) ~= numel( values ) ) || any( ~cellfun( @ischar, props ) )
                    error('Arguments must be supplied as property-value pairs' );
                end
                ToSplit = strcmpi(props,argname);
                ToSplit = reshape([ToSplit; ToSplit],1,[]);
                splitArgs = varargin(ToSplit);
                if ~isempty(splitArgs)
                    removedArgValue = splitArgs{end};
                end
                remaningArgs = varargin(~ToSplit);
            end
        end %function
        
    end %methods
    
    
    %% Private methods
    methods (Access=private)
        
        function thisParser = getParser(obj,keepUnmatched)
            
            % What class is this?
            className = class(obj);
            
            % Keep a list of reusable parsers for each class
            persistent allParsers
            if isempty(allParsers)
                allParsers = containers.Map('KeyType','char','ValueType','any');
            end
            
            % Get or make a custom parser for this class
            try
                
                thisParser = allParsers(className);
                
            catch
                
                % Get a list of public properties
                metaObj = metaclass(obj);
                isSettableProp = strcmp({metaObj.PropertyList.SetAccess}','public');
                settableProps = metaObj.PropertyList(isSettableProp);
                publicPropNames = {settableProps.Name}';
                hasDefault = [settableProps.HasDefault]';
                defaultValues = repmat({[]},size(hasDefault));
                defaultValues(hasDefault) = {settableProps(hasDefault).DefaultValue};
                
                % Create custom parser for this class
                thisParser = inputParser;
                thisParser.KeepUnmatched = keepUnmatched;
                thisParser.FunctionName = className;
                
                % Add each public property to the parser
                for pIdx = 1:numel(publicPropNames)
                    thisParser.addParameter(publicPropNames{pIdx}, defaultValues{pIdx});
                end
                
                % Add this parser to the map
                allParsers(className) = thisParser;
                
            end %if allParsers.isKey(className)
            
        end %function
        
    end %methods
        
    
end %classdef