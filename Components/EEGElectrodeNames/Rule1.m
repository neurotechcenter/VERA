function VERA_elNames_normalized = Rule1(VERA_shankNames,VERA_numEl,eeg_elNames)

idx = 1;
for i = 1:length(VERA_shankNames)
    for ii = 1:VERA_numEl(i)
        VERA_elNames{idx,1} = [VERA_shankNames{i} num2str(ii)];
        idx = idx + 1;
    end
end

VERA_elNames_normalized = [];

for i = 1:length(VERA_elNames)
    % grab first letter
    VERA_shank = VERA_elNames{i}(1);

    % grab last number
    LastNumber = regexp(VERA_elNames{i},'((\d+)\D*$)','match');

    % Normalized names
    VERA_elNames_normalized{i,1} = strcat(VERA_shank,LastNumber{1});
end

end