function setPropsIfDifferent(obj,varargin)
% setPropsIfDifferent - Utility to set graphics properties after only if changed
% 
% Abstract: This utility will set graphics properties only if the value is
% different. It is useful in certain situations for performance. If the
% handle is not valid, it silently does nothing.
%
% Syntax:
%           uiw.utility.setPropsIfDifferent(obj,varargin)
%
% Inputs:
%           obj - the graphics object array
%
%           varargin - property-value pairs to set
%
% Outputs:
%           none
%

%   Copyright 2018-2019 The MathWorks Inc.
%
% Auth/Revision:
%   MathWorks Consulting
%   $Author: rjackey $
%   $Revision: 324 $  $Date: 2019-04-23 08:05:17 -0400 (Tue, 23 Apr 2019) $
% ---------------------------------------------------------------------

for oIdx = 1:numel(obj)
    if isvalid(obj(oIdx))
        for propIdx = 2:2:numel(varargin)
            if ~isequal(obj(oIdx).(varargin{propIdx-1}), varargin{propIdx})
                obj(oIdx).(varargin{propIdx-1}) = varargin{propIdx};
            end
        end
    end
end
