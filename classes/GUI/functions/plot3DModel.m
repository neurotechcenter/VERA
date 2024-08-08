function [surf] = plot3DModel(ax,model,annotation,varargin)
%plot3DModel - Plots the 3D model with annotations from a Surface Data
%object
%ax - axis to be plotted on
%model - Surface Data object
%annotation - Annotations for each vertex
%varargin - additional settings to be passed to trisurf
%See also Surface, trisurf

    %%% Added by James
    if ~isempty(varargin)
        if strcmp(varargin{1},'LightOn') && varargin{2} == 1
            LightOn = 1;
        else
            LightOn = 0;
        end
    else
        LightOn = 1;
    end
    %%%

    if(~exist('annotation','var'))
        annotation=ones(size(model.vert,1),1);
    end
    if isempty(annotation)
        annotation=ones(size(model.vert,1),1);
    end
    surf=trisurf(model.tri, model.vert(:, 1), model.vert(:, 2), model.vert(:, 3),annotation ,'Parent',...
        ax,'linestyle', 'none','FaceLighting','gouraud','BackFaceLighting','unlit','AmbientStrength',1); % James removed varargin to deal with lighting... was ,varargin){:}
    material(ax,'dull');
    if LightOn
        light(ax,'Position',[1 0 0],'Style','local');
        set(ax,'AmbientLightColor',[1 1 1]);
        camlight(ax,'headlight');
    else
        camlight(ax,'headlight');
    end
    set(ax,'xtick',[]);
    set(ax,'ytick',[]);
    axis(ax,'equal');
    axis(ax,'off');
    xlim(ax,'auto');
    ylim(ax,'auto');
    set(ax,'clipping','off');
    set(ax,'XColor', 'none','YColor','none','ZColor','none')
    
end

