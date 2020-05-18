function mData = java2mat(jData,varargin)
% java2mat - Utility to convert Java array to MATLAB array
% 
% Abstract: This utility will convert Java values to a MATLAB equivalent
%
% Syntax:
%           mData = uiw.utility.java2mat(jData)
%
% Inputs:
%           jData - the Java array
%
% Outputs:
%           mData - the MATLAB array
%
% Examples:
%           none
%
% Notes: none
%

%   Copyright 2017-2019 The MathWorks Inc.
%
% Auth/Revision:
%   MathWorks Consulting
%   $Author: rjackey $
%   $Revision: 324 $  $Date: 2019-04-23 08:05:17 -0400 (Tue, 23 Apr 2019) $
% ---------------------------------------------------------------------

% Constants that may be needed
persistent epochDate


%% What type of data is this?

thisJavaClass = class(jData);
thisJavaClass = strrep(thisJavaClass,'[]','');

switch thisJavaClass
    
    case 'cell'
        
        % Requres recursion in each cell
        mData = cell(size(jData));
        for idx=1:numel(jData)
            mData{idx} = uiw.utility.java2mat(jData{idx});
        end
        
    case 'java.lang.Object'
        
        mData = cell(size(jData));
        for idx=1:numel(jData)
            mData{idx} = uiw.utility.java2mat(jData(idx));
        end
        
    case 'java.awt.Color'
        
        mData = zeros(numel(jData),3);
        for idx=1:numel(jData)
            mData(idx,:) = [jData.getRed(), jData.getGreen(), jData.getBlue()];
        end
        mData = mData / 255;
        
    case 'java.util.GregorianCalendar'
        
        % Populate this constant value if not yet done
        if isempty(epochDate)
            epochDate = datetime([1970 1 1],'TimeZone','GMT');
        end

        % Preallocate
        mData = repmat(epochDate, size(jData));
        
        % Loop on each element
        for idx = 1:numel(jData)
            
            % Set the date
            millisSinceEpoch = jData(idx).getTimeInMillis();
            mData(idx) = epochDate + milliseconds(millisSinceEpoch);
            
        end %for 1:numel(jData)
        
        % Set timezone - all must be the same
        jTimeZone = jData(1).getTimeZone();
        timeZoneId = jTimeZone.getID();
        mData.TimeZone = char(timeZoneId);
            
    case 'java.lang.String'
        
        % Convert to Java string
        mData = char(jData);
        
    case 'java.lang.Double'
        
        mData = double(jData);
        
    case 'java.lang.Float'
        
        mData = single(jData);
        
    case 'java.lang.Long'
        
        mData = int64(jData);
        
    case 'java.lang.Integer'
        
        mData = int32(jData);
        
    case 'java.lang.Short'
        
        mData = int16(jData);
        
    case 'java.lang.Byte'
        
        mData = int8(jData);
        
    case 'java.lang.Boolean'
        
        mData = javaObject('java.lang.Boolean',jData);
        
    otherwise
        
        % Leave as-is
        mData = jData;
        
end %switch class(jData)

end %function java2mat
