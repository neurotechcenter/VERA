function [mask] = createElectrodeMask(imsize,elInfo)
%CREATESTRIPMASK Summary of this function goes here
%   Detailed explanation goes here
mask=ones(imsize);

for iTag=1:size(elInfo.BoundingBox,1)
    for iBB=1:size(elInfo.BoundingBox,2)
        %loc=round(squeeze(elInfo.BoundingBox(iTag,iBB,:)));
        si=sqrt(squeeze(elInfo.Information.Volume));
        loc(1:3)=round(squeeze(elInfo.Locations(iTag,iBB,:)))-floor(si);
        loc(4:6)=repmat(ceil(si),3,1)*2;
        mask(loc(2):loc(2)+loc(5),loc(1):loc(1)+loc(4),loc(3):loc(3)+loc(6))=0;
    end
end

