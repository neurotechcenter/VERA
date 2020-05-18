function [angles,comb]=findAllAngleCombinations(p,candidates,electrodes)
        comb=nchoosek(candidates,2);
        angles=zeros(size(comb,1),1);
        for i=1:size(comb,1)
        angles(i)=calculateNeighbourAngle(p,electrodes(comb(i,:),:));
        end
end