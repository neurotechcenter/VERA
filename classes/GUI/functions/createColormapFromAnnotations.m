function [annotation_remap,cmap] = createColormapFromAnnotations(surface)
%createColormapFromAnnotations - Creates a colormap for Annotation of the
%Surface 
% surface - Surface Data object
% returns:
% annotation_remap - remapped annotations from 1 to max
% cmap - colormap associated with annotations
% See also Model3DView, plot3DModel
cmap=zeros(numel(surface.AnnotationLabel)+1,3);
annotation_remap=zeros(size(surface.Annotation));
for i=1:length(cmap)-2
    cmap(i,:)=surface.AnnotationLabel(i).PreferredColor;
    annotation_remap(surface.Annotation == surface.AnnotationLabel(i).Identifier)=i;

end
annotation_remap(surface.Annotation == 0)=length(cmap); %grey
cmap(end,:)=[75 75 75]/255;
end

