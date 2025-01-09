function isAbsolute = isAbsolutePath(path)
    % This function checks if the given path is absolute or relative.
    % It returns true (1) if the path is absolute, and false (0) if it is relative.
    
    % Check if the path is an absolute path
    if ispc
        % For Windows: Check if the path starts with a drive letter (e.g., C:\)
        isAbsolute = ~isempty(regexp(path, '^[A-Za-z]:\\', 'once'));
    else
        % For UNIX-based systems (Linux/macOS): Check if the path starts with a "/"
        isAbsolute = startsWith(path, '/');
    end
end
