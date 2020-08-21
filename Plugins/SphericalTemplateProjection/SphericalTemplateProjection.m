classdef SphericalTemplateProjection < AComponent
    %SphericalTemplateProjection Uses Freesurfers spherical coregistration
    %to project electrodes from a single subject to a template
    %   Only works for strips and grids, not for depth electrodes!
    
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
            
            for ip=1:length(inLocs.Location)
                surfVert=obj.findClosestVertex(inLocs.Location(ip,:),surf.Model.vert);

                if(surf.Model.vertId(surfVert) == 1)  %LH
                    surfoffset=find(surf.Model.vertId == 1,1)-1;
                    tsurfoffset=find(tsurf.Model.vertId == 1,1)-1;  
                    tSphereVertIdx=obj.findClosestVertex(lsphere.Model.vert(surfVert-surfoffset,:),ltsphere.Model.vert);
                    outLocs.Location(ip,:)=tsurf.Model.vert(tSphereVertIdx+tsurfoffset,:);
                elseif(surf.Model.vertId(surfVert) == 2)
                    surfoffset=find(surf.Model.vertId == 2,1)-1;
                    tsurfoffset=find(tsurf.Model.vertId == 2,1)-1;  
                    tSphereVertIdx=obj.findClosestVertex(rsphere.Model.vert(surfVert-surfoffset,:),rtsphere.Model.vert);
                    outLocs.Location(ip,:)=tsurf.Model.vert(tSphereVertIdx+tsurfoffset,:);
                else
                    error(['Unknown vertex identifier: ' num2str(surf.Model.vertId(surfVert))]);
                end
            end
        end
        
        
        function vId=findClosestVertex(~,p,vert)
            [~,vId]=min((vert(:,1)-p(1)).^2 + (vert(:,2)-p(2)).^2 + (vert(:,3)-p(3)).^2);
        end

    end
end

