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

% Can only run if app construction is complete
if ~obj.IsConstructed
    return
end


%% Set the current model to each component

obj.h.BarChart.DataModel = obj.Session;
obj.h.PlotSelector.DataModel = obj.Session;
obj.h.DisplayTable.DataModel = obj.Session;