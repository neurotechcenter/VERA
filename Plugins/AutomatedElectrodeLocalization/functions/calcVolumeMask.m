function [maskIn] = calcVolumeMask(maskIn)
%calcVolumeMask - calculates the binary convex hull to create a mask
for k=1:size(maskIn,3)
        maskIn(:,:,k)=bwconvhull(maskIn(:,:,k));
end




