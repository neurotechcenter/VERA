function [num] = brodmanLabelToNumber(label)
%BRODMANLABELSTONUMBER Summary of this function goes here
%   Detailed explanation goes here
if(strcmp(label,'Unknown'))
    num=0;
else
    num=sscanf(label, 'Brodmann area %u');
end
end

