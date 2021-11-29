function [resolvedFile] = resolveSymlink(file)
%resolveWSLSymlink resolve symlink to get path to real file
        [~,res]=system(['readlink ' file]);
    if(~isempty(res))
        resolvedFile=fullfile(fileparts(file),strtrim(res));
    else
        resolvedFile=file;
    end
end