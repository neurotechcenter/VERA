function VERA_elNames_normalized = Rule6(VERA_elNames,eeg_elNames)

VERA_elNames_normalized = [];

for i = 1:length(VERA_elNames)
    % Take all letters before ^ or -
    idx1 = strfind(VERA_elNames{i},'^');
    idx2 = strfind(VERA_elNames{i},'-');

    % Sometimes they use -'s instead of ^'s
    if ~isempty(idx1)
        idx = idx1;
    elseif ~isempty(idx2)
        idx = idx2;
    else
        idx = [];
    end

    if ~isempty(idx)
        idx = idx(1);

        % First Letter
        VERA_shank = VERA_elNames{i}(1:idx-1);

        % Last digits
        LastNumber = regexp(VERA_elNames{i},'((\d+)\D*$)','match');

        % Normalized names
        VERA_elNames_normalized{i,1} = strcat(VERA_shank,LastNumber{1});
    else
        VERA_elNames_normalized{i,1} = '';
    end
end

end
