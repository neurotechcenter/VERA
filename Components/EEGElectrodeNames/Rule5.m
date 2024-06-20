function VERA_elNames_normalized = Rule5(VERA_shankNames,VERA_numEl,eeg_elNames)

idx = 1;
for i = 1:length(VERA_shankNames)
    for ii = 1:VERA_numEl(i)
        VERA_elNames{idx,1} = [VERA_shankNames{i} num2str(ii)];
        idx = idx + 1;
    end
end

VERA_elNames_normalized = [];

for i = 1:length(VERA_elNames)
    % Take all letters before ^
    idx = strfind(VERA_elNames{i},'^');

    idx = min(idx);

    if ~isempty(idx)

        % First Letter
        VERA_shank = VERA_elNames{i}(1:idx-1);

        % ' means Left
        if contains(VERA_shank,'''')
            VERA_shank(end) = 'L';
        else
            VERA_shank = [VERA_shank 'R'];
        end

        % Last digits
        LastNumber = regexp(VERA_elNames{i},'((\d+)\D*$)','match');

        % Normalized names
        VERA_elNames_normalized{i,1} = strcat(VERA_shank,LastNumber{1});
    else
        VERA_elNames_normalized{i,1} = '';
    end
end

end