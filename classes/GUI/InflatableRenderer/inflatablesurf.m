function h = inflatablesurf(varargin)
%INFLATABLESURF Creates a path object which can be morphed between two
%point clouds (vertices1 and vertices2)
%   Usage:
%   h=inflatablesurf(faces,vertices1,vertices2,ci,...)
%   faces - connectivity matrix Nx3
%   vertices1 - Nx3 matrix 
%   vertices2 - Nx3 matrix
%   ci - Face color index (can be set to [] if not used)
%   returns an inflatable patch object
%
%   To change inflation:
%       e.g.:h.Inflation=0.1
%
%   or:
%   h=inflatablesurf(o,faces,vertices1,vertices2,ci,...)
%   o - inflatable object - links inflatable objects together so that
%   changing Inflation in one object causes the same behavior in a linked
%   object
% See also patch
    ax = axescheck(varargin{:});
    ax = newplot(ax);
    if(isa(varargin{1},'inflatableobject'))
        start=6;
        T=varargin{2};
        xyz1=varargin{3};
        xyz2=varargin{4};
        C=varargin{5};
    else
        start=5;
        T=varargin{1};
        xyz1=varargin{2};
        xyz2=varargin{3};
        C=varargin{4};

    end
    if(size(xyz1,2) ~= 3 || size(xyz2,2) ~= 3)
        error('xyz1 and xyz2 are expected to be nx3 vectors');
    end

    if(isempty(C))
        C=zeros(size(xyz1,1),1);
    end

    if(numel(C) ~= size(xyz1,1))
        error('C vector is expected to be same number of elements as vertices');
    end

    h=inflatablepatch(varargin{1:start-2}, ...
        'facecolor',get(ax,'DefaultSurfaceFaceColor'), ...
        'edgecolor',get(ax,'DefaultSurfaceEdgeColor'), ...
        'Parent',ax,...
        'facevertexcdata',C(:),...
        varargin{start:end});

    light(ax,'Position',[1 0 0],'Style','local');
    %light(obj.axModel,'Position',[-1 0 0]);
   % camlight(obj.axModel,'headlight');
    material(ax,'dull');
    set(ax,'AmbientLightColor',[1 1 1]);
    camlight(ax,'headlight');
    set(ax,'xtick',[]);
    set(ax,'ytick',[]);
    set(ax,'ztick',[]);
    axis(ax,'equal');
    axis(ax,'off');
    xlim(ax,'auto');
    ylim(ax,'auto');
    set(ax,'clipping','off');
    set(ax,'XColor', 'none','YColor','none','ZColor','none')
end

