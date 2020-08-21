function [phi] = calculateNeighbourAngle(c,n)
%calculateNeighbourAngle Calculates the angle between point c and two
%points in n, assumes that points are connected in a n-c-n pattern
cn=c-n(1,:);
nc=c-n(2,:);

phi=acos(dot(cn,nc)/(norm(cn)*norm(nc)));
end

