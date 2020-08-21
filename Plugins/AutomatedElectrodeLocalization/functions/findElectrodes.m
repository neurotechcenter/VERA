function [metric,locations,partial_matches] = findElectrodes(V,thresh,f_size,f_std,allowedVar,elInfo,plotit)
%findElectrodes - find all connected electrodes
%   Creates a tree of electrodes which are connected (within a certain distance and have a 90degree angle between them)
% V - volume
% threshold - threshold for volume to determine electrode locations
% f_size - gaussian smoothing kernel size
% f_std - gaussian smoothing std
% allowedVar - variance allowed for distance between electrodes and angles
% elInfo - information about electrode distance
% plotit - plots result of findElectrodes

if(~exist('plotit','var'))
    plotit=[];
end
idx = mod(f_size,2)<1;
f_size = floor(f_size);
f_size(idx) = f_size(idx)+1;

V(V < thresh) = 0;
V=smooth3(V,'gaussian',f_size,f_std);
V=(V > thresh); %make binary
props=regionprops3(bwlabeln(V),'Volume','Centroid','BoundingBox');
volIdx=find((props.Volume > elInfo.Volume*(0)) &  (props.Volume < elInfo.Volume*(inf)));
electrodes=props.Centroid(volIdx,:);
boundingBoxes=props.BoundingBox(volIdx,:);
electrodes=props.Centroid;
boundingBoxes=props.BoundingBox;
num_el=elInfo.NType;
gdist=elInfo.Spacing;

locations.Information=elInfo;
locations.Locations=nan(elInfo.NType,elInfo.NElectrodes,3);
locations.BoundingBox=nan(elInfo.NType,elInfo.NElectrodes,6);
locations.Tree=cell(elInfo.NType,1);
locations.Electrodes=cell(elInfo.NType,1);

% if(~isempty(plotit))
%     figure(plotit);
%     pltax=gca;
%     cla(pltax);
%     [x,y,z]=meshgrid(1:size(V,2),1:size(V,1),1:size(V,3));
%     fv=isosurface(x,y,z,V);
%     p=patch(pltax,fv);
%     p.FaceColor = 'blue';
%     p.EdgeColor = 'none';
%     daspect([1 1 1])
%     view(3); 
%     axis tight
%     camlight 
%     lighting gouraud
%     %alpha(0.3)
%     hold(pltax,'on');
%     if(~isempty(electrodes))
%     scatter3(pltax,electrodes(:,1),electrodes(:,2),electrodes(:,3),'or','fill')
%     end
%     xlim(pltax,[1 size(V,2)]);
%     ylim(pltax,[1 size(V,1)]);
%     zlim(pltax,[1 size(V,3)]);
%     
%     drawnow;
%     
%     
% end


el_locs_found=zeros(size(electrodes,1),1);
el_found=true;
partial_matches={};
while((el_found) && size(electrodes,1) ~= 0 && (num_el ~= 0))%  && (size(electrodes,1) >= elInfo.NElectrodes))) also look for partial matches
    el_found=false;
    for iel=1:size(electrodes,1)
            belectrodes=electrodes;
            belectrodes(iel,:)=[];
            bNames=1:length(electrodes);
            bNames(iel)=[];
            switch(elInfo.Type)
                case 'Grid'
                    poss=findNeighbour(iel,electrodes(iel,:),belectrodes,90,bNames,allowedVar,gdist,true);
                case 'Strip'
                    poss=findStripNeighbour(iel,electrodes(iel,:),belectrodes,bNames,allowedVar,gdist);
                otherwise
                    error('Unknown Electrode type');
            end
            el_locs=TraverseTree(poss,['A','B']);
                    %disp(['Number of connected Grid Electrodes: ' num2str(numel(poss_grid_locs))])
            el_locs_found(iel)=numel(el_locs);
%             if(~isempty(plotit))
%                  plotTree(poss,electrodes,['A','B'],plotit);
%              end
%            disp(['Tree Traversing, found ' num2str(el_locs_found(iel))]);
            if(any(numel(el_locs)== elInfo.NElectrodes))
                    %    fg=figure;scatter3(electrodes(:,1),electrodes(:,2),electrodes(:,3),'o','LineWidth',2);
                    %    view([0 0]);

                    %    title(['Start location: ' num2str(iel)]);
                     %   gridEl(remGrid)=[];
                     %   gridSpaceing(remGrid)=[];
                     %   grid_locs{i_grids}=poss_grid_locs;
                        locations.Locations(elInfo.NType-num_el+1,:,:)=electrodes(el_locs,:);
                        locations.BoundingBox(elInfo.NType-num_el+1,:,:)=boundingBoxes(el_locs,:);
                        locations.Tree{elInfo.NType-num_el+1}=poss;
                        locations.Electrodes{elInfo.NType-num_el+1}=electrodes;
                        electrodes(el_locs,:)=[];
                        boundingBoxes(el_locs,:)=[];
                     %   i_grids=i_grids+1;
                     %   cont=true;
                     %   cont1=true;
                     %   break;
                        num_el=num_el-1;
                        el_found=true;
                        break;
            else
                partial_matches{end+1}=electrodes(el_locs,:);
            end
    end
    
end
el_locs=sort(el_locs_found,'descend');
if(num_el > 0)
locations.Locations((1+elInfo.NType-num_el):elInfo.NType,:,:)=[];
locations.BoundingBox((1+elInfo.NType-num_el):elInfo.NType,:,:)=[];
%locations.Tree{(1+elInfo.N-num_el):elInfo.N}=[];
end
grids_fd_tot=abs(num_el - elInfo.NType);
% 



metric=max((elInfo.NElectrodes*elInfo.NType- length(volIdx)),0)...
    + max(prctile(props.Volume(:)-elInfo.Volume,50), 0)...
    - min(sum(el_locs(1:min(numel(el_locs),elInfo.NType))),elInfo.NType*elInfo.NElectrodes) ...
    - elInfo.NElectrodes*(min(elInfo.NType-num_el,elInfo.NType))...
    - elInfo.NType*elInfo.NElectrodes*(min(elInfo.NType-grids_fd_tot,0));


disp([num2str(elInfo.NType) ' ' elInfo.Type '(s) Found: ' num2str(abs(num_el - elInfo.NType)) ' Metric: ' ...
    num2str(max((elInfo.NElectrodes*elInfo.NType- (length(volIdx))),0)) ...
    ' + ' num2str(max(prctile(props.Volume(:)-elInfo.Volume,50), 0))...
    ' - ' num2str(min(sum(el_locs(1:min(numel(el_locs),elInfo.NType))),elInfo.NType*elInfo.NElectrodes))...
    ' - ' num2str(elInfo.NElectrodes*(min(elInfo.NType-num_el,elInfo.NType))) ...
    ' - ' num2str(elInfo.NType*elInfo.NElectrodes*(min(elInfo.NType-grids_fd_tot,0))) ...
    ' = ' num2str(metric)]);
