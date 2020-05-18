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
    'Title','Data Table');


%% Create the widgets

colInfo = {
    'Year'              'custom'    '###0  '
    'Carrier'           'char'      ''
    'Flight Num'        'custom'    '###0  '
    'Origin'            'char'      ''
    'Destination'       'char'      ''
    'Departure Delay'   'numeric'   ''
    'Arrival Delay'     'numeric'   ''
    };

obj.h.Table = uiw.widget.Table(...
    'Parent',obj.hLayout.MainBox,...
    'Tag','DataTable',...
    'ColumnName',colInfo(:,1),...
    'ColumnFormat',colInfo(:,2),...
    'ColumnFormatData',colInfo(:,3),...
    'Editable',false);

