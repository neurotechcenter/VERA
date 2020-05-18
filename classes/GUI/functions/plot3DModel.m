function [surf] = plot3DModel(ax,model,annotation,varargin)
    if(~exist('annotation','var'))
        annotation=[];
    end
    surf=trisurf(model.tri, model.vert(:, 1), model.vert(:, 2), model.vert(:, 3),annotation ,'Parent',...
        ax,'CDataMapping', 'direct','linestyle', 'none','FaceLighting','gouraud','BackFaceLighting','unlit','AmbientStrength',1,varargin{:});
    light(ax,'Position',[1 0 0],'Style','local');
    %light(obj.axModel,'Position',[-1 0 0]);
   % camlight(obj.axModel,'headlight');
    material(ax,'dull');
    set(ax,'AmbientLightColor',[1 1 1]);
    camlight(ax,'headlight');
    set(ax,'xtick',[]);
    set(ax,'ytick',[]);
    axis(ax,'equal');
    axis(ax,'off');
    xlim(ax,'auto');
    ylim(ax,'auto');
    set(ax,'clipping','off');
    set(ax,'XColor', 'none','YColor','none','ZColor','none')
end

