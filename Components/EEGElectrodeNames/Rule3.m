function VERA_elNames_normalized = Rule3(VERA_elNames,eeg_elNames)

VERA_elNames_normalized = [];

for i = 1:length(VERA_elNames)
    % if second element is number or hat (no modifier) implant on RIGHT
    if ~isempty(regexp(VERA_elNames{i}(2),'((\d+)\D*$)','match'))
        VERA_shank = [VERA_elNames{i}(1),'R'];
        % if there is a ' it is on the left
    elseif contains(VERA_elNames{i},'''')
        VERA_shank = [VERA_elNames{i}(1),'L'];
    else
        VERA_shank = [];
    end

    % Last digits
    LastNumber = regexp(VERA_elNames{i},'((\d+)\D*$)','match');

    % Normalized names
    VERA_elNames_normalized{i,1} = strcat(VERA_shank,LastNumber{1});
end
end