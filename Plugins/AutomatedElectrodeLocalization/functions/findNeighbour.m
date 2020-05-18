function [pointTree] = findNeighbour(pointId,p,electrodes,phi,electrodeIds,allowedVar,gdist,checkEnd)

Y = pdist([p;electrodes]);
D=squareform(Y);
pointTree.Me=pointId;
neighbournames={'A','B'};
if(isempty(D))
    return;
end
Neighbours=find(D(1,:) < gdist*(1+allowedVar) & D(1,:) > gdist*(1-allowedVar))-1;

if(numel(Neighbours) == 2)
    angle=calculateNeighbourAngle(p,electrodes(Neighbours,:));
   
    if(angle > deg2rad(phi*(1-allowedVar)) && angle < deg2rad(phi*(1+allowedVar)))
        pointTree.Angle=angle;
       % disp(['Neighbours input: ' num2str(Neighbours) ' ' num2str(size(electrodes))]);
        pointTree=traverse(pointTree,electrodes,Neighbours,electrodeIds,neighbournames,phi,allowedVar,gdist);
    end
else
    if(checkEnd && (numel(Neighbours) > 2)) %if we have more than 2 maybe we can find a pair with 90 degree angle
        [angles,comb]=findAllAngleCombinations(p,Neighbours,electrodes);
        qualifies=(angles > deg2rad(phi*(1-allowedVar))) & (angles < deg2rad(phi*(1+allowedVar)));
       
        candidates=find(qualifies);
        if(length(candidates) == 1) %if there is only a single candidate, lets use that one
            Neighbours=comb(candidates,:);
            pointTree=traverse(pointTree,electrodes,Neighbours,electrodeIds,neighbournames,phi,allowedVar,gdist);
        end
    end
end
    
end


function pointTree=traverse(pointTree,electrodes,Neighbours,electrodeIds,neighbournames,phi,allowedVar,gdist)
        neigh=electrodes(Neighbours,:);
        bElId=electrodeIds(Neighbours);
        electrodes(Neighbours,:)=[];
        electrodeIds(Neighbours)=[];
        for in=1:length(Neighbours)
            pointTree.(neighbournames{in})=findNeighbour(bElId(in),neigh(in,:),electrodes,phi,electrodeIds,allowedVar,gdist,false);
        % if all neighbors are ends, maybe we reached the opposing
        % corner... lets see if there is a single electrode in reach that
        % forms a corner
        end
 
  
        if(all(~isfield(pointTree.A,neighbournames)) && all(~isfield(pointTree.B,neighbournames)))
                Neigh=1:size(electrodes,1);
                for in=1:length(Neighbours)
                    Y = pdist([neigh(in,:);electrodes]);
                    D=squareform(Y);
                    Neigh=intersect(Neigh,find(D(1,:) < gdist*(1+allowedVar) & D(1,:) > gdist*(1-allowedVar))-1);
                end
                %if we have multiple choices... we need to find the one
                %that forms the right angle 
                if(numel(Neigh) > 1)
                        angles=zeros(numel(Neigh),1);
                        disp(['Neighbours traverse: ' num2str(Neighbours) ' ' num2str(size(electrodes))])
                      for in=1:numel(Neigh)
                          angles(in)=calculateNeighbourAngle(electrodes(Neigh(in),:),neigh);
                      end
                      qualifies=(angles > deg2rad(phi*(1-allowedVar))) & (angles < deg2rad(phi*(1+allowedVar)));
                      Neigh=Neigh(qualifies);
                      pointTree.Angle=angles(qualifies);
                end
                if(~isempty(Neigh) && numel(Neigh) == 1)
                    temp.Me=electrodeIds(Neigh);
                    pointTree.A.A=temp; %%add an additional node to A.A
                    pointTree.B.A=temp;
                end

        end
end




