function [pointTree] = findStripNeighbour(pointId,p,electrodes,electrodeIds,allowedVar,gdist,allowOtherAngle)
%findStripNeighbour - recursive function to determine connected points to form a
%strip
% pointId - current point in algorithm
% p - next point
% electrodes - available electrodes
% phi - expected angle between electrode locations
% electrodeIds - electrode Identifiers
% allowedVar - variance allowed for distance and angle between locations
% gdist - expected distance between electrodes
% checkEnd 
Y = pdist([p;electrodes]);
D=squareform(Y);
pointTree.Me=pointId;
neighbournames={'A','B'};
phi=180;
if(~exist('allowOtherAngle','var'))
    allowOtherAngle=false;
end
if(isempty(D))
    return;
end

Neighbours=find(D(1,:) < gdist*(1+allowedVar) & D(1,:) > gdist*(1-allowedVar))-1;
if(numel(Neighbours) == 2)
    angle=calculateNeighbourAngle(p,electrodes(Neighbours,:));
    if(angle > deg2rad(phi*(1-allowedVar)) && angle < deg2rad(phi*(1+allowedVar)))
        pointTree=traverse(pointTree,p,electrodes,Neighbours,electrodeIds,neighbournames,allowedVar,gdist);
    end
else
    if(numel(Neighbours) > 2)
        [angles,comb]=findAllAngleCombinations(p,Neighbours,electrodes);
        if(~allowOtherAngle && any(angles > deg2rad(phi/2*(1-allowedVar)) & angles < deg2rad(phi/2*(1+allowedVar))))
            return;
        end
        poss=find(angles > deg2rad(phi*(1-allowedVar)) & angles < deg2rad(phi*(1+allowedVar)));
        if(numel(poss) == 1)
            pointTree=traverse(pointTree,p,electrodes,comb(poss,:),electrodeIds,neighbournames,allowedVar,gdist);
        end
    end
    
end
    
end


function pointTree=traverse(pointTree,p,electrodes,Neighbours,electrodeIds,neighbournames,allowedVar,gdist)
        neigh=electrodes(Neighbours,:);
        bElId=electrodeIds(Neighbours);
        electrodes(Neighbours,:)=[];
        electrodeIds(Neighbours)=[];
        electrodes(end+1,:)=p; %add back parent point
        electrodeIds(end+1)=pointTree.Me;
        for in=1:length(Neighbours)
            pointTree.(neighbournames{in})=findStripNeighbour(bElId(in),neigh(in,:),electrodes,electrodeIds,allowedVar,gdist,false);
        % if all neighbors are ends, maybe we reached the opposing
        % corner... lets see if there is a single electrode in reach that
        % forms a corner
        end
end

