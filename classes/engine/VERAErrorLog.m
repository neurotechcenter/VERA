function logPath = VERAErrorLog(context, err)
    %VERAErrorLog Append a timestamped error report to a log file.
    %   The compiled/deployed VERA apps have no MATLAB console to surface
    %   errors on, so failures that would normally print to the Command
    %   Window are otherwise invisible. Call this from a catch block with
    %   a short context string and the caught MException (or a plain
    %   char message) to leave a persistent, inspectable record.
    %
    %   Tries, in order: the build/output directory (next to VERA.app and
    %   VERAPipelineDesigner.app, or StandaloneBuild/build/StandaloneVERA when
    %   run interactively) if it exists, then the user's home folder, then
    %   MATLAB's temp folder as a last resort (always writable, per OS
    %   guarantee - this is what keeps a failure under e.g. macOS App
    %   Translocation, where the build directory AND a misbehaving home
    %   folder could both be unwritable, from losing the record entirely).
    %   Returns the path actually written to, or '' if every location
    %   failed, so callers can tell the user exactly where to look.
    %
    %   This function must never throw - it's called from catch blocks,
    %   and an error here would mask the original one it's trying to
    %   record. Every step that could plausibly fail is individually
    %   guarded so one bad candidate (e.g. an unreadable home directory)
    %   doesn't take the rest down with it.
    logPath = '';
    fid = -1;
    candidates = errorLogCandidates();
    for i = 1:numel(candidates)
        try
            f = fopen(candidates{i}, 'a');
        catch
            f = -1;
        end
        if f ~= -1
            fid = f;
            logPath = candidates{i};
            break;
        end
    end
    if fid == -1
        logPath = '';
        return;
    end

    closer = onCleanup(@() fclose(fid)); % guarantees the handle closes even if a write below throws
    try
        fprintf(fid, '\n=== %s | %s ===\n', safeTimestamp(), safeContext(context));
        fprintf(fid, '%s\n', safeMessage(err));
    catch
        % Swallow - we already have a valid logPath to report, and closer
        % still closes the file on the way out.
    end
end

function candidates = errorLogCandidates()
    %errorLogCandidates - Ordered list of paths to try, most-preferred
    %first. Each candidate is computed defensively so a failure in one
    %(e.g. findBuildDir erroring) doesn't remove the others from the list.
    candidates = {};
    try
        buildDir = findBuildDir();
        if ~isempty(buildDir) && exist(buildDir, 'dir')
            candidates{end+1} = fullfile(buildDir, 'VERA_error_log.txt');
        end
    catch
    end
    try
        candidates{end+1} = fullfile(char(java.lang.System.getProperty('user.home')), 'VERA_error_log.txt');
    catch
        try
            home = getenv('HOME');
            if ~isempty(home)
                candidates{end+1} = fullfile(home, 'VERA_error_log.txt');
            end
        catch
        end
    end
    try
        candidates{end+1} = fullfile(tempdir, 'VERA_error_log.txt');
    catch
    end
end

function s = safeTimestamp()
    try
        s = datestr(now);
    catch
        s = 'unknown time';
    end
end

function s = safeContext(context)
    try
        if ischar(context)
            s = context;
        elseif isstring(context)
            s = char(context);
        else
            s = '(non-char context)';
        end
    catch
        s = '(context unavailable)';
    end
end

function s = safeMessage(err)
    %safeMessage - Best-effort text for whatever was caught. err is
    %normally an MException, but callers are documented to also accept a
    %plain char message, so this can't assume either shape.
    try
        if ischar(err) || isstring(err)
            s = char(err);
            return
        end
    catch
    end
    try
        s = getReport(err, 'extended', 'hyperlinks', 'off');
        return
    catch
    end
    try
        s = err.message;
        return
    catch
    end
    s = '(error details unavailable)';
end

function d = findBuildDir()
    %findBuildDir Best-effort location of "the build directory": the
    %shared output folder VERA.app/VERAPipelineDesigner.app ship in when
    %deployed, or StandaloneBuild/build/StandaloneVERA in an interactive
    %checkout. Returns '' if it can't be determined - the caller falls
    %back to the home folder either way, so this only needs to be a
    %reasonable guess, not guaranteed correct.
    d = '';
    try
        if isdeployed
            if ispc
                % Exact ctfroot() nesting relative to the .exe isn't one
                % documented constant across MATLAB Compiler versions -
                % same caveat as MainGUI/openPipelineDesigner's Windows
                % branch, not yet validated against a real Windows build.
                d = fileparts(ctfroot);
            else
                appBundle = fileparts(fileparts(fileparts(ctfroot))); % .../VERA.app
                d = fileparts(appBundle);                             % shared build output dir
            end
        else
            repoRoot = fileparts(fileparts(fileparts(mfilename('fullpath')))); % classes/engine -> repo root
            d = fullfile(repoRoot, 'StandaloneBuild', 'build', 'StandaloneVERA');
        end
    catch
        d = '';
    end
end
