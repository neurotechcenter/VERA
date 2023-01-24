function [annotation_remap,cmap,name,name_id] = createColormapFromAnnotations(surface)
%createColormapFromAnnotations - Creates a colormap for Annotation of the
%Surface 
% surface - Surface Data object
% returns:
% annotation_remap - remapped annotations from 1 to max
% cmap - colormap associated with annotations
% See also Model3DView, plot3DModel
cmap=zeros(numel(surface.AnnotationLabel)+1,3);
name=cell(numel(surface.AnnotationLabel)+1,1);
name_id=zeros(numel(surface.AnnotationLabel)+1,1);
annotation_remap=zeros(size(surface.Annotation));
if(isempty(surface.AnnotationLabel) && ~isempty(surface.Annotation))
    %if the annotations arent empty, but we didnt define any labels - we
    %we assume that the annotation is a continous scale - like thickness or
    %curvature
    annotation_remap=surface.Annotation;
    cmap=turbo(100);
    name{1}='';
    name{2}='';
    name_id(1)=min(annotation_remap);
    name_id(2)=max(annotation_remap);


else
    for i=1:size(cmap,1)-1
        cmap(i,:)=surface.AnnotationLabel(i).PreferredColor;
        annotation_remap(surface.Annotation == surface.AnnotationLabel(i).Identifier)=i;
        name{i}=surface.AnnotationLabel(i).Name;
        name_id(i)=i;
    
    end
    annotation_remap(surface.Annotation == 0)=length(cmap); %grey
    name_id(length(cmap))=length(cmap);
    name{length(cmap)}=' ';
    cmap(end,:)=[75 75 75]/255;
end
end

