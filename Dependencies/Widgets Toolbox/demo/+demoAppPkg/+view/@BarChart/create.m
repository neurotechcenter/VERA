function create(obj)
% create - Creates all parts of the viewer display
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


%% Create the layout

obj.hLayout.MainBox = uix.BoxPanel(...
    'Parent',obj.hBasePanel,...
    'FontSize',10,...
    'Title','Bar Chart');

% Axes should be inside a container, in case colorbar or legend are added
obj.hLayout.AxesContainer = uicontainer('Parent',obj.hLayout.MainBox);


%% Create the widgets

obj.h.Axes = axes(...
    'Parent',obj.hLayout.AxesContainer);

obj.h.BarPlot = gobjects(0);

