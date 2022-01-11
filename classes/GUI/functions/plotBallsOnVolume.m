function [ surfs] = plotBallsOnVolume(ax,electrodes, color, radius,varargin)
%PLOTBALLS  Plots electrodes in assigned color
%ax - axis to be plotted on
%color - color to be plotted
%radiues - size of ball to be plotted in 3d Sapce
%varargin - additional parameters passed to surf
%See also surf
ELS = size(electrodes, 1);
cmap=colormap(ax);
 hold(ax,'on');
 % The axes should stay aligned
 surfs={};
if(isempty(color))
    index  = get(ax,'ColorOrderIndex');
    colors = get(ax,'ColorOrder');
    if index+1 > size(colors,1)
        index = 0;
    end
    set(ax,'ColorOrderIndex',index+1);
    color=colors(index+1,:);
end
if(numel(color) == 1)
    cmap_id=color;
else
 cmap(end+1,:)=color;
 colormap(ax,cmap);
 cmap_id=(size(cmap,1));
end
 %caxis(ax,[1 size(cmap,1)]);
for els = 1 : ELS    
    %original electrode locations:
    xe = electrodes(els, 1);
    ye = electrodes(els, 2);
    ze = electrodes(els, 3);
    %generate sphere coordinates (radius 1, 20-by-20 faces)
    [X, Y, Z] = sphere(100);

    %place the sphere into the spot:
    R = radius; %sphere radius
    X = R * X + xe;
    Y = R * Y + ye;
    Z = R * Z + ze;

    surfs{end+1}=surf(ax,X, Y, Z, ones(size(Z,1))*cmap_id,'FaceColor','flat','FaceLighting','none','CDataMapping', 'direct','LineStyle','none',varargin{:});

end
    
  hold(ax,'off');