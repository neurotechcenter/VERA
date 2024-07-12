function VERA_elNames_normalized = RuleTemplate(VERA_shankNames,VERA_numEl,eeg_elNames)
% The objective of this function is to translate the electrode names found in VERA_elNames 
% into the same format as those found in eeg_elNames
% The order should not matter - only the character of the names needs to be matched, 
% e.g. for eeg_elNames=[A'1, A'2, A'3] and VERA_elNames=[Ahippocampus1, Ahippocampus2, Ahippocampus3] 
% you would want to remove the word 'hippocampus' so VERA_elNames_normalized=[A'1, A'2, A'3]
% 
% Note that VERA is looking for the word 'Rule' in the name of the function. 
% I would recommend naming new rule functions as 'Rule_institution1.m', 'Rule_institution2.m', etc

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

        % ` means Right
        current_shank = [current_shank, '`'];

        % Last digits
        LastNumber = VERA_elNumbers(i);

        % Normalized names
        VERA_elNames_normalized{i,1} = strcat(current_shank,num2str(LastNumber));
    else
        VERA_elNames_normalized{i,1} = '';
    end
end

end
