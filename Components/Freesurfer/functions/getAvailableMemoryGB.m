function freeGB = getAvailableMemoryGB()
%GETAVAILABLEMEMORYGB Estimate currently available system memory, in GB.
%Returns NaN if the amount could not be determined.
    freeGB = NaN;
    if ispc
        [~,sys] = memory;
        freeGB = sys.PhysicalMemory.Available / 2^30;
    elseif ismac
        [status,cmdout] = system('vm_stat');
        if status ~= 0
            return;
        end
        pageSize = extractNumber(cmdout,'page size of (\d+) bytes');
        freePages = extractNumber(cmdout,'Pages free:\s*(\d+)\.') ...
                  + extractNumber(cmdout,'Pages inactive:\s*(\d+)\.') ...
                  + extractNumber(cmdout,'Pages speculative:\s*(\d+)\.');
        if ~isnan(pageSize) && ~isnan(freePages)
            freeGB = freePages * pageSize / 2^30;
        end
    else
        [status,cmdout] = system('free -b');
        if status ~= 0
            return;
        end
        lines = strsplit(cmdout,newline);
        memLineIdx = find(startsWith(strtrim(lines),'Mem:'),1);
        if isempty(memLineIdx)
            return;
        end
        fields = strsplit(strtrim(lines{memLineIdx}));
        if numel(fields) >= 7
            freeGB = str2double(fields{7}) / 2^30; %'available' column
        elseif numel(fields) >= 4
            freeGB = str2double(fields{4}) / 2^30; %fallback to 'free' column
        end
    end
end

function value = extractNumber(str,pattern)
    tok = regexp(str,pattern,'tokens','once');
    if isempty(tok)
        value = NaN;
    else
        value = str2double(tok{1});
    end
end
