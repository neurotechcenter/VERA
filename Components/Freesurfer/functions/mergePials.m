function [pialOut] = mergePials(lh_pial,rh_pial)
%MERGE_PIALS Merges two pial structs together
        pialOut.vert=[lh_pial.vert; rh_pial.vert];
        pialOut.vertId=[lh_pial.vertId; rh_pial.vertId]; %add identifier to know how they were combined
        adjustedRHtemptri = rh_pial.tri + size(lh_pial.vert, 1);
        pialOut.tri = [lh_pial.tri; adjustedRHtemptri];
        pialOut.triId=[ones(size(lh_pial.tri,1),1); 2*ones(size(adjustedRHtemptri,1),1)];

end

