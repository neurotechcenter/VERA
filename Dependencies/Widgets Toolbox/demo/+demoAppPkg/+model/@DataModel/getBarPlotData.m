function [x,y] = getBarPlotData(obj)
% getBarPlotData - prepares the bar plot data
% -------------------------------------------------------------------------
%
% Notes: none
%

%   Copyright 2018-2019 The MathWorks Inc.
%
% Auth/Revision:
%   MathWorks Consulting
%   $Author: rjackey $
%   $Revision: 324 $  $Date: 2019-04-23 08:05:17 -0400 (Tue, 23 Apr 2019) $
% ---------------------------------------------------------------------


%% Prepare the data to display

% Get the filtered data
t = obj.FilteredTable;

% Group by carrier
if any(strcmp(t.Properties.VariableNames, 'Carrier'));
    [carrierIdx,carrierNames] = findgroups(t.Carrier);
else
    carrierIdx = [];
end

% What carriers were found?
if isempty(carrierIdx)
    
    % No data to plot
    y = [];
    x = categorical.empty(0,0);
    
else
    
    % Which data column?
    switch obj.DelayType
        
        case demoAppPkg.enum.DelayType.Arrival
            
            delayData = t.ArrDelay;
            
        case demoAppPkg.enum.DelayType.Departure
            
            delayData = t.DepDelay;
            
        otherwise
            warning('ExampleApp:UnhandledType',...
                'Unhandled type: %s',obj.DelayType);
            
    end %switch
    
    % Which plot type?
    switch obj.PlotType
        
        case demoAppPkg.enum.PlotType.Fraction
            
            % Calculate the fractional rate of delays longer than 15 minutes
            y = splitapply(@iCalculateFraction, delayData, carrierIdx);
            
        case demoAppPkg.enum.PlotType.Quantity
            
            % Calculate the total number of delays
            y = splitapply(@iCalculateQuantity, delayData, carrierIdx);
            
        case demoAppPkg.enum.PlotType.Mean
            
            % Calculate the mean delay
            y = splitapply(@mean, delayData, carrierIdx);
            
        otherwise
            warning('ExampleApp:UnhandledType',...
                'Unhandled type: %s',obj.PlotType);
            
    end %switch
    
    % Sort largest on top
    [y,ix] = sortrows(y,'ascend');
    x = carrierNames(ix);
    
    % Filter down the category names to show
    x = setcats(x, cellstr(x));
    
end %if isempty(carrierIdx)


%% Nested functions

    function y = iCalculateFraction(x)
        
        y = iCalculateQuantity(x) / size(x,1);
        
    end %function

    function y = iCalculateQuantity(x)
        
        isDelayed = x > obj.DelayTime;
        y = sum(isDelayed);
        
    end %function

end %function