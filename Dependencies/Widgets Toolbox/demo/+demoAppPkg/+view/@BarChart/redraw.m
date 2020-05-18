function redraw(obj)
% redraw - Updates all parts of the viewer display
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


%% Get the plot data
[x,y] = obj.DataModel.getBarPlotData();

plotTitle = sprintf('%s Delays',obj.DataModel.DelayType);
% xTitle = sprintf('%s',obj.DataModel.PlotType);
xTitle = obj.DataModel.PlotType.Label;
yTitle = 'Carrier';


%% Update the view

delete(obj.h.BarPlot);
if ~isempty(x)
    obj.h.BarPlot = barh(obj.h.Axes, x, y);
end

obj.h.Axes.Title.String = plotTitle;
obj.h.Axes.XAxis.Label.String = xTitle;
obj.h.Axes.YAxis.Label.String = yTitle;
