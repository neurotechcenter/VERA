function [resolvedFile] = resolveWSLSymlink(file,subsyspath)
%resolveWSLSymlink resolve symlink to get path to real file
        [~,res]=systemWSL(['readlink ' convertToUbuntuSubsystemPath(file,subsyspath)]);
    if(~isempty(res))
        resolvedFile=fullfile(fileparts(file),strtrim(res));
    else
        resolvedFile=file;
    end
end

