classdef SphericalTemplateProjection < AComponent
    %SphericalTemplateProjection Uses Freesurfers spherical coregistration
    %to project electrodes from a single subject to a template
    % Only works for strips and grids, not for depth electrodes!
    
    properties
        TemplateSurfaceIdentifier
        TemplateSphereIdentifier
        SurfaceIdentifier
        SphereIdentifier
        ElectrodeLocationInputIdentifier
        ElectrodeLocationOutputIdentifier
    end
    
    properties (Dependent, Access = protected)
        LeftSphereIdentifier
        LeftTemplateSphereIdentifier
        RightSphereIdentifier
        RightTemplateSphereIdentifier
    end
    
    methods
        function obj = SphericalTemplateProjection()
            obj.TemplateSphereIdentifier='TemplateSphere';
            obj.SphereIdentifier='Sphere';
            obj.TemplateSurfaceIdentifier='TemplateSurface';
            obj.SurfaceIdentifier='Surface';
            obj.ElectrodeLocationInputIdentifier='ElectrodeLocation';
            obj.ElectrodeLocationOutputIdentifier='TemplateElectrodeLocation';
        end
        
        function value=get.LeftSphereIdentifier(obj)
            value=['L_' obj.SphereIdentifier];
         end
        
         function value=get.RightSphereIdentifier(obj)
            value=['R_' obj.SphereIdentifier];
         end
        
         function value=get.LeftTemplateSphereIdentifier(obj)
            value=['L_' obj.TemplateSphereIdentifier];
          end
        
         function value=get.RightTemplateSphereIdentifier(obj)
            value=['R_' obj.TemplateSphereIdentifier];
         end
         
         function Publish(obj)
             obj.AddInput(obj.LeftSphereIdentifier,'Surface');
             obj.AddInput(obj.RightSphereIdentifier,'Surface');
             obj.AddInput(obj.SurfaceIdentifier,'Surface');
             obj.AddInput(obj.LeftTemplateSphereIdentifier,'Surface');
             obj.AddInput(obj.RightTemplateSphereIdentifier,'Surface');
             obj.AddInput(obj.TemplateSurfaceIdentifier,'Surface');
             obj.AddInput(obj.ElectrodeLocationInputIdentifier,'ElectrodeLocation');
             obj.AddOutput(obj.ElectrodeLocationOutputIdentifier,'ElectrodeLocation');
         end
        
        function Initialize(obj)
        end
        
        function [outLocs] = Process(obj,lsphere,rsphere,surf,ltsphere,rtsphere,tsurf,inLocs)
            outLocs=obj.CreateOutput(obj.ElectrodeLocationOutputIdentifier);
            outLocs.DefinitionIdentifier=inLocs.DefinitionIdentifier;
            %id = 1 left, ids are not alternating
            %id = 2 right
            
            
           % figure;
           % ax1=subplot(2,2,1);
           % [annotation_remap,cmap]=createColormapFromAnnotations(lsphere);
           % im=plot3DModel(ax1,lsphere.Model,annotation_remap);colormap(ax1,cmap);alpha(im,0.3);
           % ax2=subplot(2,2,2);
           % [annotation_remap,cmap]=createColormapFromAnnotations(surf);
           % im=plot3DModel(ax2,surf.Model,annotation_remap);colormap(ax2,cmap);alpha(im,0.3);
           % ax3=subplot(2,2,3);
           % [annotation_remap,cmap]=createColormapFromAnnotations(ltsphere);
           % im=plot3DModel(ax3,ltsphere.Model,annotation_remap);colormap(ax3,cmap);alpha(im,0.3);
           % ax4=subplot(2,2,4);
           % [annotation_remap,cmap]=createColormapFromAnnotations(tsurf);
           % im=plot3DModel(ax4,tsurf.Model,annotation_remap);colormap(ax4,cmap);alpha(im,0.3);
            
            for ip=1:length(inLocs.Location)
                surfVert=findClosestVertex(inLocs.Location(ip,:),surf.Model.vert);
                
                if(surf.Model.vertId(surfVert) == 1)  %LH
                    surfoffset=find(surf.Model.vertId == 1,1)-1;
                    tsurfoffset=find(tsurf.Model.vertId == 1,1)-1;  
                    tSphereVertIdx=findClosestVertex(lsphere.Model.vert(surfVert-surfoffset,:),ltsphere.Model.vert);
                    outLocs.Location(ip,:)=tsurf.Model.vert(tSphereVertIdx+tsurfoffset,:);
              %      hold(ax1,'on'),plotBallsOn3DImage(ax1,lsphere.Model.vert(surfVert-surfoffset,:),[],4);
              %      hold(ax2,'on'),plotBallsOn3DImage(ax2,surf.Model.vert(surfVert+surfoffset,:),[],4);
              %      hold(ax3,'on'),plotBallsOn3DImage(ax3,ltsphere.Model.vert(tSphereVertIdx+tsurfoffset,:),[],4);
              %      hold(ax4,'on'),plotBallsOn3DImage(ax4,tsurf.Model.vert(tSphereVertIdx+tsurfoffset,:),[],4);
                elseif(surf.Model.vertId(surfVert) == 2)
                    surfoffset=find(surf.Model.vertId == 2,1)-1;
                    tsurfoffset=find(tsurf.Model.vertId == 2,1)-1;  
                    tSphereVertIdx=findClosestVertex(rsphere.Model.vert(surfVert-surfoffset,:),rtsphere.Model.vert);
                    outLocs.Location(ip,:)=tsurf.Model.vert(tSphereVertIdx+tsurfoffset,:);
                else
                    error(['Unknown vertex identifier: ' num2str(surf.Model.vertId(surfVert))]);
                end
                
            end
        end
        
        


    end
end

