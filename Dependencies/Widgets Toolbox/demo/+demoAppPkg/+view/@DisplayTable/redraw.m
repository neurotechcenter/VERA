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

tf = obj.DataModel.FilteredTable;


%% Prepare the data to display

if isempty(tf)
    
    displayTable = cell(0,7);
    
else
    
    % Prepare the table data
    year = num2cell( tf.Year );
    carrier = cellstr( tf.Carrier );
    flightNum = num2cell( tf.FlightNum );
    origin = cellstr( tf.Origin );
    destination = cellstr( tf.Dest );
    arrDelay = num2cell( tf.ArrDelay );
    depDelay = num2cell( tf.DepDelay );
    
    % Put the table data in a cell
    displayTable = horzcat(year, carrier, flightNum, origin, destination, ...
        depDelay, arrDelay);

end


%% Update the view

obj.h.Table.Data = displayTable;