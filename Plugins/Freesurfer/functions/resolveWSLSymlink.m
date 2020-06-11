function [resolvedFile] = resolveWSLSymlink(file,subsyspath)
%RESOLVEWSLSYMLINK Summary of this function goes here
%   Detailed explanation goes here
        [~,res]=systemWSL(['readlink ' convertToUbuntuSubsystemPath(file,subsyspath)]);
    if(~isempty(res))
        resolvedFile=fullfile(fileparts(file),strtrim(res));
    else
        resolvedFile=file;
    end
end

