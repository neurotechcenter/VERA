function VERA_elNames_normalized = Rule4(VERA_elNames,eeg_elNames)

VERA_elNames_normalized = [];

for i = 1:length(VERA_elNames)
    % grab first letter and append a ` to the front
    VERA_shank = ['`', VERA_elNames{i}(1)];

    % grab last number
    LastNumber = regexp(VERA_elNames{i},'((\d+)\D*$)','match');

    % Normalized names
    VERA_elNames_normalized{i,1} = strcat(VERA_shank,LastNumber{1});
end

end