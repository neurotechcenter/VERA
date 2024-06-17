function VERA_elNames_normalized = RuleTemplate(VERA_elNames,eeg_elNames)
% The objective of this function is to translate the electrode names found in VERA_elNames 
% into the same format as those found in eeg_elNames
% The order should not matter - only the character of the names needs to be matched, 
% e.g. for eeg_elNames=[A'1, A'2, A'3] and VERA_elNames=[Ahippocampus1, Ahippocampus2, Ahippocampus3] 
% you would want to remove the word 'hippocampus' so VERA_elNames_normalized=[A'1, A'2, A'3]
% 
% Note that VERA is looking for the word 'Rule' in the name of the function. 
% I would recommend naming new rule functions as 'Rule_institution1.m', 'Rule_institution2.m', etc

VERA_elNames_normalized = [];

end
