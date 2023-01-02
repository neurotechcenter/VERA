function [d,I]=minDistance(x,y)
% minDistance - calculates the minimum distance between each point in x and
% the pointcloud in y
%   [d,I]=minDistance(x,y)
%   x - Nx3 matrix
%   y - Nx3 matrix
%   returns:
%   d - closest distance between point in x and the point cloud y
%   I - index of the point in y to which d is calculated
%
    if(size(x,2) ~= 3 || size(y,2)~= 3)
        error('Inputs are expected as Nx3 vectors')
    end
    d=zeros(size(x,1),1);
    I=zeros(size(x,1),1);
    for p=1:size(x,1)
        ds=vecnorm(x(p,:)-y,2,2);
        [d(p),I(p)]=min(ds);
    end

end