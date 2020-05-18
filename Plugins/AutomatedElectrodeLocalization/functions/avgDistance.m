function dist=avgDistance(p1,p2)
dists=zeros(size(p2,2),1);
for i=1:size(p2,2)
    dists(i)=min(sqrt(sum((p2(i,1:3)-p1(:,1:3)).^2,2)));
end

dist(1)=median(dists);
end