function [BA] = findBrodmanLabel(data,jarFile)
%FINDBRODMANLABEL Summary of this function goes here
%   jarFile is assumed to be correct path - on windows 
for i=1:size(data,1)
    [~,cmdout]=system(['java -cp ' jarFile ' org.talairach.PointToTD 4:11, ' regexprep(num2str(data(i,:)),'\s+',', ')]);
    [res]=split(cmdout,'Returned:');
    BA{i}=strtrim(res{2});
end

