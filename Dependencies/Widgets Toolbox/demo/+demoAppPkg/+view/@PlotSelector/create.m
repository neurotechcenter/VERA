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
    'Title','Plot Data Selection');

obj.hLayout.MainGrid = uix.Grid(...
    'Parent',obj.hLayout.MainBox,...
    'Padding',10,...
    'Spacing',5);


%% Create the plot widgets

% These list items are fixed so we can populate them once here
[~,plotTypes] = enumeration('demoAppPkg.enum.PlotType');
[~,delayTypes] = enumeration('demoAppPkg.enum.DelayType');

obj.h.PlotTypePopup = uiw.widget.Popup(...
    'Parent',obj.hLayout.MainGrid,...
    'Callback',@(h,e)onPopupSelection(obj,e),...
    'Items',plotTypes,...
    'Label','Plot Type');

obj.h.DelayTypePopup = uiw.widget.Popup(...
    'Parent',obj.hLayout.MainGrid,...
    'Callback',@(h,e)onPopupSelection(obj,e),...
    'Items',delayTypes,...
    'Label','Delay Type');

% Fill in a blank space
% uix.Empty('Parent',obj.hLayout.MainGrid);

obj.h.DelayTimeSlider = uiw.widget.Slider(...
    'Parent',obj.hLayout.MainGrid,...
    'Callback',@(h,e)onSliderChanged(obj,e),...
    'Min',0,...
    'Max',120,...
    'Label','Minimum Delay Time');


%% Create the filter widgets

obj.h.CarrierPopup = uiw.widget.Popup(...
    'Parent',obj.hLayout.MainGrid,...
    'Callback',@(h,e)onPopupSelection(obj,e),...
    'Tag','Carrier',...
    'Label','Carrier');

obj.h.OriginPopup = uiw.widget.Popup(...
    'Parent',obj.hLayout.MainGrid,...
    'Callback',@(h,e)onPopupSelection(obj,e),...
    'Tag','Origin',...
    'Label','Origin');

obj.h.DestinationPopup = uiw.widget.Popup(...
    'Parent',obj.hLayout.MainGrid,...
    'Callback',@(h,e)onPopupSelection(obj,e),...
    'Tag','Destination',...
    'Label','Destination');


%% Adjust sizes

obj.hLayout.MainGrid.Heights = [25 25 40];
obj.hLayout.MainGrid.Widths = [-1 -1];
