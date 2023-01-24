function [lh,rh] = loadFSSurface(surfacetype,segmentationPath,subsyspath)
%loadFSSurface - load freesurfer surface
%freesurfer 7 works with symlinks which cannot be resolved
%under windows so we need to get the correct target
fallbackSuffix='';
fd=dir(fullfile(segmentationPath,['surf/lh.' surfacetype]));
if(isempty(fd) || fd.bytes == 0) %something went wrong with the symlink
    fallbackSuffix='.T1';
    warning(['lh.' surfacetype ' is 0 byte -- will try fallback to *h.' surfacetype '.T1 ']);
end


if(ispc)
    pathToLhPial=resolveWSLSymlink(fullfile(segmentationPath,['surf/lh.' surfacetype fallbackSuffix]),subsyspath);
    pathToRhPial=resolveWSLSymlink(fullfile(segmentationPath,['surf/rh.' surfacetype fallbackSuffix]),subsyspath);
else
    pathToLhPial=resolveSymlink(fullfile(segmentationPath,['surf/lh.' surfacetype fallbackSuffix]));
    pathToRhPial=resolveSymlink(fullfile(segmentationPath,['surf/rh.' surfacetype fallbackSuffix]));
end

    [lh.vert, lh.tri] = read_surf(pathToLhPial);
    lh.tri=lh.tri+1;
    [rh.vert, rh.tri] = read_surf(pathToRhPial);
    rh.tri=rh.tri+1;
end

