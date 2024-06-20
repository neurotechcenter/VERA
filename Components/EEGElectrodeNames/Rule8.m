function VERA_elNames_normalized = Rule8(VERA_shankNames,VERA_numEl,eeg_elNames)

VERA_elNames = [];
for i = 1:size(VERA_shankNames,1)
    for ii = 1:VERA_numEl(i)
        VERA_elNames = [VERA_elNames;VERA_shankNames(i)];
    end
end

VERA_elNumbers = [];
for i = 1:size(VERA_numEl,2)
    VERA_elNumbers = [VERA_elNumbers; [1:VERA_numEl(i)]';];
end

VERA_elNames_normalized = [];

for i = 1:length(VERA_elNames)
    % Take all letters before ^ or -
    idx1 = strfind(VERA_elNames{i},'^');
    idx2 = strfind(VERA_elNames{i},'-');

    % Sometimes they use -'s instead of ^'s
    idx = min([idx1, idx2]);

    if ~isempty(idx)

        % First Letter
        current_shank = VERA_elNames{i}(1:idx-1);

        % ' means Left
        if contains(current_shank,'''')
            current_shank(end) = 'L';
        else
            current_shank = [current_shank 'R'];
        end

        % Last digits
        LastNumber = VERA_elNumbers(i);

        % Normalized names
        VERA_elNames_normalized{i,1} = strcat(current_shank,num2str(LastNumber));
    else
        VERA_elNames_normalized{i,1} = '';
    end
end

end
