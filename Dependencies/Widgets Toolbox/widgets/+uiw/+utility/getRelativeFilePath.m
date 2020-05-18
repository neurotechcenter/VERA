function RelPath = getRelativeFilePath(FullPath, RootPath, FlagRequireSubdir)
% getRelativeFilePath - Utility to return a relative file path within a root
% 
% This function will find the relative file path, given a full absolute
% path and a root path
%
% Syntax:
%       RelPath = uiw.utility.getRelativeFilePath(FullPath, RootPath)
%
% Inputs:
%       FullPath - the full absolute path to a file or folder
%       RootPath - the root folder to get a relative path for
%       FlagRequireSubdir - optional flag indicating whether FullPath must
%           be a subdirectory of RootPath [(true)|false]
%
% Outputs:
%       RelPath - the relative path
%
% Examples:
%
%     >> FullPath = 'C:\Program Files\MATLAB\R2016b\toolbox'
%     >> RootPath = 'C:\Program Files\MATLAB'
%     >> RelPath = uiw.utility.getRelativeFilePath(FullPath, RootPath)
% 
%     RelPath =
%          \R2016b\toolbox
% 
% Notes:
%   If FullPath is not a subdirectory of RootPath and FlagRequireSubdir is
%   false, the path will contain parent directory separators "..\"
%

%   Copyright 2016-2019 The MathWorks Inc.
%
% Auth/Revision:
%   MathWorks Consulting
%   $Author: rjackey $
%   $Revision: 324 $  $Date: 2019-04-23 08:05:17 -0400 (Tue, 23 Apr 2019) $
% ---------------------------------------------------------------------

% Validate inputs
if nargin<3
    FlagRequireSubdir = true;
end
validateattributes(RootPath,{'char'},{})
validateattributes(FullPath,{'char'},{})
validateattributes(FlagRequireSubdir,{'logical'},{'scalar'})

% Is RootPath empty?
if isempty(FullPath)
    
    RelPath = RootPath;
    
elseif isempty(RootPath)
    
    RelPath = FullPath;
    
else
    
    % Remove trailing filesep
    if strcmp(RootPath(end),filesep)
        RootPath(end) = '';
    end
    if strcmp(FullPath(end),filesep)
        FullPath(end) = '';
    end
    
    % Split the paths apart
    RootParts = strsplit(RootPath,filesep);
    FullParts = strsplit(FullPath,filesep);
    
    % Find where the paths diverge
    idx = 1;
    SmallestPath = min(numel(RootParts), numel(FullParts));
    while idx<=SmallestPath && strcmpi(RootParts{idx}, FullParts{idx})
        idx = idx+1;
    end
    
    % Is the specified path outside of the root directory?
    NumAbove = max(numel(RootParts) - idx + 1, 0);
    if FlagRequireSubdir && NumAbove>0
        error('The specified path:\n\t"%s"\nis not a subdirectory of the root path:\n\t"%s"',...
            FullPath,RootPath);
    else
        % In case full path is above the RootPath, add ".." paths
        ParentPaths = repmat(['..' filesep],1,NumAbove);
        
        % Form the relative path
        RelPath = fullfile(ParentPaths, FullParts{idx:end});
    end
    
    % What if paths are still the same?
    if isempty(RelPath)
        RelPath = ['.' filesep];
    end
    
end %if isempty(RootPath)

