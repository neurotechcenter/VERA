function [path_out] = convertToUbuntuSubsystemPath(path_in,subsysPath)
%CONVERTTOUBUNTUSUBSYSTEMPATH Summary of this function goes here
%   Detailed explanation goes here
        path_in=GetFullPath(path_in);
        endout=regexp(path_in,filesep,'split');
        endout{1}=lower(replace(endout{1},':','')); %remove : from path and make it small letter to fit ubuntu mount scheme
        path_out=fullfile(subsysPath,endout{:});
        path_out(strfind(path_out,'\'))='/'; %convert slashes to unix format
end

