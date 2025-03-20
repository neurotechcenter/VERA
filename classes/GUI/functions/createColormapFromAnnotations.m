function [annotation_remap,cmap,name,name_id] = createColormapFromAnnotations(surface,varargin)
    %createColormapFromAnnotations - Creates a colormap for Annotation of the
    %Surface 
    % surface - Surface Data object
    % returns:
    % annotation_remap - remapped annotations from 1 to max
    % cmap - colormap associated with annotations
    % See also Model3DView, plot3DModel

    if nargin == 2
        barflag = varargin{1};
    else
        barflag = 1;
    end

    cmap             = zeros(numel(surface.AnnotationLabel), 3);
    name             = cell(numel(surface.AnnotationLabel),  1);
    name_id          = zeros(numel(surface.AnnotationLabel), 1);
    annotation_remap = zeros(size(surface.Annotation));

    if(isempty(surface.AnnotationLabel) && ~isempty(surface.Annotation))
        %if the annotations arent empty, but we didnt define any labels - we
        %assume that the annotation is a continous scale - like thickness or
        %curvature
        annotation_remap = surface.Annotation;
        cmap             = turbo(100);
        name{1}          = '';
        name{2}          = '';
        name_id(1)       = min(annotation_remap);
        name_id(2)       = max(annotation_remap);
    
    else
        for i=1:size(cmap,1)
            cmap(i,:)  = surface.AnnotationLabel(i).PreferredColor;
            name{i}    = surface.AnnotationLabel(i).Name;
            name_id(i) = i;

            annotation_remap(surface.Annotation == surface.AnnotationLabel(i).Identifier) = i;
        end

        % Append gray bar to separate surface from electrodes on the colorbar
        if barflag
            cmap(end+1,:)         = [75 75 75]/255;
            name_id(size(cmap,1)) = size(cmap,1);
            name{size(cmap,1)}    = ' ';
            annotation_remap(surface.Annotation == 0) = size(cmap,1); %grey
        else
            
        end
    end
end

