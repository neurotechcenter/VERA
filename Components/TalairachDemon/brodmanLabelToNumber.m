function [num] = brodmanLabelToNumber(label)
%brodmanLabelToNumber - converts the label to a number
%label - String in the form of Brodman area %n
%Output
% numerical for brodman label
if(strcmp(label,'Unknown'))
    num=0;
else
    num=sscanf(label, 'Brodmann area %u');
end
end

