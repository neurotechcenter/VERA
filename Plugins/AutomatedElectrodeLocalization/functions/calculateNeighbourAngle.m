function [phi] = calculateNeighbourAngle(c,n)
%CALCULATENEIGHBOURANGLE Summary of this function goes here
%   Detailed explanation goes here
cn=c-n(1,:);
nc=c-n(2,:);

phi=acos(dot(cn,nc)/(norm(cn)*norm(nc)));
end

