function applyFilters(obj)
% applyFilters - determines the selected rows based on filters
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

% Height of the table
nRows = height(obj.Table);


%% Origin Filter

if isempty(obj.OriginFilter) || nRows==0
    % Empty = Select All
    originRows = true(nRows,1);
else
    % Match selection
    originRows = any( obj.Table.Origin == obj.OriginFilter(:)', 2 );
end


%% Destination Filter

if isempty(obj.DestinationFilter) || nRows==0
    % Empty = Select All
    destinationRows = true(nRows,1);
else
    % Match selection
    destinationRows = any( obj.Table.Dest == obj.DestinationFilter(:)', 2 );
end


%% Carrier Filter

if isempty(obj.CarrierFilter) || nRows==0
    % Empty = Select All
    carrierRows = true(nRows,1);
else
    % Match selection
    carrierRows = any( obj.Table.Carrier == obj.CarrierFilter(:)', 2 );
end


%% Update the filter

obj.RowIsSelected = originRows & destinationRows & carrierRows;

