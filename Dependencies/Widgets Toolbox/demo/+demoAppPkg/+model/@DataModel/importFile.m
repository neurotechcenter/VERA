function importFile(obj,fileName)
% importFile - import a data file
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


%% Set import options

opts = detectImportOptions(fileName);

selVars = {
    'Year'
    'UniqueCarrier'
    'FlightNum'
    'Origin'
    'Dest'
    'ArrDelay'
    'DepDelay'
    };
    
opts.SelectedVariableNames = selVars; 
opts.MissingRule = 'fill';
opts = setvaropts(opts,{'ArrDelay','DepDelay'},'TreatAsMissing','NA');
opts = setvaropts(opts,{'ArrDelay','DepDelay'},'FillValue',0);
opts = setvartype(opts,{'UniqueCarrier','Origin','Dest'},'categorical');

% Rename this one
opts.VariableNames{9} = 'Carrier';


%% Read in the table

t = readtable(fileName,opts);


%% Set the table

obj.Table = t;