function VERA_elNames_normalized = Rule2(VERA_elNames,eeg_elNames)

VERA_elNames_normalized = [];

for i = 1:length(VERA_elNames)
    % if second element is number or hat (no modifier) implant on left
    if ~isempty(regexp(VERA_elNames{i}(2),'((\d+)\D*$)','match')) || strcmp(VERA_elNames{i}(2),'^')
        VERA_shank = [VERA_elNames{i}(1),'L'];
        % Sometimes there is a dash
    elseif contains(VERA_elNames{i},'-L')
        VERA_shank = [VERA_elNames{i}(1),'L'];
    elseif contains(VERA_elNames{i},'-R')
        VERA_shank = [VERA_elNames{i}(1),'R'];
    else
        VERA_shank = [];
    end

    % Last digits
    LastNumber = regexp(VERA_elNames{i},'((\d+)\D*$)','match');

    % Normalized names
    VERA_elNames_normalized{i,1} = strcat(VERA_shank,LastNumber{1});
end

end