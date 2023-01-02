function [pial] = transformPial(pial,xfrm_matrix)
%TRANSFORMPIAL Summary of this function goes here
%   Detailed explanation goes here
        pial.vert=(xfrm_matrix*[pial.vert(:,1), pial.vert(:,2), pial.vert(:,3), ones(size(pial.vert, 1), 1)]')';
        pial.vert=pial.vert(:,1:3);
end

