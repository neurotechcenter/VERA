function [transformed_vertices] = affine_transform_slice(vertices,transform_matrix,slice_start,slice_end,slice_dir)
%AFFINE_TRANSFORM_SUB Summary of this function goes here
%   input:
%       vertices... to transform
%       transform_matrix... affine transformation matrix (3x4)
%       slice_start... [x y z] start coordinates for slice
%       slice_end....  [x y z] coordinates slice end
%       use -inf, inf to create slice plane
transformed_vertices=vertices;
slice_start=slice_start(:);
slice_end=slice_end(:);
if(nargin < 5)
    slice_dir=0;
end

if(slice_dir)
    x_mask=vertices(:,1) > slice_start(1) & vertices(:,1) <= slice_end(1);
    y_mask=vertices(:,2) > slice_start(2) & vertices(:,2) <= slice_end(2);
    z_mask=vertices(:,3) > slice_start(3) & vertices(:,3) <= slice_end(3);
else
    x_mask=vertices(:,1) >= slice_start(1) & vertices(:,1) < slice_end(1);
    y_mask=vertices(:,2) >= slice_start(2) & vertices(:,2) < slice_end(2);
    z_mask=vertices(:,3) >= slice_start(3) & vertices(:,3) < slice_end(3);
end

mask=x_mask & y_mask & z_mask;
transformed_vertices(mask,:)=(transform_matrix* vertices(mask,:)')';

end

