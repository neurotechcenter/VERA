function [maskIn] = calcVolumeMask(maskIn)
%CALCVOLUMEMASK Summary of this function goes here
%   Detailed explanation goes here



for k=1:size(maskIn,3)
        maskIn(:,:,k)=bwconvhull(maskIn(:,:,k));
end




