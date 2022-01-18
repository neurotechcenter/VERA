function vId=findClosestVertex(p,vert)
            [~,vId]=min((vert(:,1)-p(1)).^2 + (vert(:,2)-p(2)).^2 + (vert(:,3)-p(3)).^2);
        end