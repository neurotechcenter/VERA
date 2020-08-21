function [angles,comb]=findAllAngleCombinations(p,candidates,electrodes)
%findAllAngleCombinations - create all possible angles with 3 points
        comb=nchoosek(candidates,2);
        angles=zeros(size(comb,1),1);
        for i=1:size(comb,1)
        angles(i)=calculateNeighbourAngle(p,electrodes(comb(i,:),:));
        end
end