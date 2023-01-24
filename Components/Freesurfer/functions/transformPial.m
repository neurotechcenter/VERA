function [pial] = transformPial(pial,xfrm_matrix)
%transformPial - apply transformation matrix to loaded pial struct
%   pial - pial struct
%   matrix - 4x4 transformation matrix
% Output:
% transformed pial struct
        pial.vert=(xfrm_matrix*[pial.vert(:,1), pial.vert(:,2), pial.vert(:,3), ones(size(pial.vert, 1), 1)]')';
        pial.vert=pial.vert(:,1:3);
end

