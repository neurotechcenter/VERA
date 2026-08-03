function VERAErrorLog(context, err)
    %VERAErrorLog Append a timestamped error report to a log file.
    %   The compiled/deployed VERA apps have no MATLAB console to surface
    %   errors on, so failures that would normally print to the Command
    %   Window are otherwise invisible. Call this from a catch block with
    %   a short context string and the caught MException (or a plain
    %   char message) to leave a persistent, inspectable record.
    logPath = fullfile(char(java.lang.System.getProperty('user.home')), 'VERA_error_log.txt');

    fid = fopen(logPath, 'a');
    if fid == -1
        return;
    end

    fprintf(fid, '\n=== %s | %s ===\n', datestr(now), context);
    if ischar(err) || isstring(err)
        fprintf(fid, '%s\n', char(err));
    else
        try
            fprintf(fid, '%s\n', getReport(err, 'extended', 'hyperlinks', 'off'));
        catch
            fprintf(fid, '%s\n', err.message);
        end
    end
    fclose(fid);
end
