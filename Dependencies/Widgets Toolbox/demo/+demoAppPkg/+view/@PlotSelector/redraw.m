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

% Get the full table
t = obj.DataModel.Table;


%% Prepare the data to display

% Get the popup lists that are dynamic

% The first choice for each of these is empty (for select all)
if isempty(t)
    carrierList = cell(0,1);
    originList = cell(0,1);
    destinationList = cell(0,1);
else
    carrierList = [{''}; categories(t.Carrier)];
    originList = [{''}; categories(t.Origin)];
    destinationList = [{''}; categories(t.Dest)];
end


%% Update the view

obj.h.CarrierPopup.Items = carrierList;
obj.h.OriginPopup.Items = originList;
obj.h.DestinationPopup.Items = destinationList;


%% Update the selections in the popup controls

obj.redrawSelections();
