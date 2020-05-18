function openDocumentationSection(filePath,sectionName)
% openDocumentationSection - Open documentation
% -------------------------------------------------------------------------
% This function will open a documentation file to the specified section
%
% Syntax:
%       uiw.utility.openDocumentationSection(filePath,sectionName)
%
% Inputs:
%       filePath - path to the documentation file
%       sectionName - name of the anchor or section name
%
% Outputs:
%       none
%
% Examples:
%
%     >> csg.utility.openDocumentationSection('myPage.html','someAnchor')
%

%   Copyright 2017-2019 The MathWorks, Inc.
%
% Auth/Revision:
%   MathWorks Consulting
%   $Author: rjackey $
%   $Revision: 445 $  $Date: 2019-03-26 10:56:10 -0400 (Tue, 26 Mar 2019) $
% ---------------------------------------------------------------------

if ~exist(filePath,'file')
    warning('openDoc:fileNotFound','Unable to locate documentation at: %s',filePath);
    return
end

% Store the browser path
persistent browserPath
if isempty(browserPath)
    % Then you want to find the system browser, and that’s a mess. For Windows, something like (you only need to do once):
    [~, raw] = system( 'reg QUERY HKEY_CURRENT_USER\SOFTWARE\Microsoft\Windows\Shell\Associations\URLAssociations\http\UserChoice /v ProgId' );
    parts = strsplit( raw, ' ' );
    progId = strtrim( parts{end} );
    [~, raw] = system( sprintf( 'reg QUERY HKEY_CLASSES_ROOT\\%s\\shell\\open\\command', progId ) );
    browser = regexp( raw, '"(?<Path>[a-zA-Z]:[^"]*)"', 'names', 'once' );
    browserPath = browser.Path;
end

% If just a file name, look on the MATLAB path
if isempty(dir(filePath))
    filePath = which(filePath);
end

% Add the anchor
if isempty(sectionName)
    filePathWithAnchor = sectionName;
else
    filePathWithAnchor = sprintf('%s#%s',filePath,sectionName);
end

% Convert to URL
javaFile = java.io.File( filePathWithAnchor );
fileUri = char( javaFile.toURL() );

% And finally shell out:
system( sprintf( '"%s" "%s" &', browserPath, fileUri ) );

