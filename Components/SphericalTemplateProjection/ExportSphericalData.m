classdef ExportSphericalData < AComponent
    %ExportSphericalData Save spherical data as .mat file
    
    properties
        SurfaceIdentifier
        SphereIdentifier
        ElectrodeLocationIdentifier
        ElectrodeDefinitionIdentifier
    end
    properties (Dependent, Access = protected)
        LeftSphereIdentifier
        RightSphereIdentifier
    end    
    methods
        function obj = ExportSphericalData()
            %EXPORTSPHERICALDATA Construct an instance of this class
            %   Detailed explanation goes here
            obj.SphereIdentifier='Sphere';
            obj.SurfaceIdentifier='Surface';
            obj.ElectrodeLocationIdentifier='ElectrodeLocation';
            obj.ElectrodeDefinitionIdentifier='ElectrodeDefinition';
        end
        
        function Publish(obj)
            obj.AddInput(obj.LeftSphereIdentifier,'Surface');
            obj.AddInput(obj.RightSphereIdentifier,'Surface');
            obj.AddInput(obj.SurfaceIdentifier,'Surface');
            obj.AddInput(obj.ElectrodeLocationIdentifier,'ElectrodeLocation');
            obj.AddInput(obj.ElectrodeDefinitionIdentifier,'ElectrodeDefinition');
        end

        function Initialize(obj)
        end

        function Process(obj,lsphere,rsphere,surf,eLocs,eDef)
            [file,path]=uiputfile('*.mat');
            leftHemiLocs=ElectrodeLocation();
            rightHemiLocs=ElectrodeLocation();
            for ip=1:length(eLocs.Location)
                surfVert=findClosestVertex(eLocs.Location(ip,:),surf.Model.vert);
                if(surf.Model.vertId(surfVert) == 1)  %LH
                    surfoffset=find(surf.Model.vertId == 1,1)-1; 
                    leftHemiLocs.Location(end+1,:)=lsphere.Model.vert(surfVert-surfoffset,:);
                    leftHemiLocs.SetLabel(size(leftHemiLocs.Location,1),eLocs.Label{size(leftHemiLocs.Location,1)});
                    if(size(rightHemiLocs.Location,1) == 1)
                        leftHemiLocs.Annotation=eLocs.Annotation(size(leftHemiLocs.Location,1));
                    else
                        leftHemiLocs.Annotation(size(leftHemiLocs.Location,1))=eLocs.Annotation(size(leftHemiLocs.Location,1));
                    end
                    elseif(surf.Model.vertId(surfVert) == 2)
                    surfoffset=find(surf.Model.vertId == 2,1)-1;
                    rightHemiLocs.Location(end+1,:)=rsphere.Model.vert(surfVert-surfoffset,:);
                    rightHemiLocs.SetLabel(size(rightHemiLocs.Location,1),eLocs.Label{size(rightHemiLocs.Location,1)});
                    if(size(rightHemiLocs.Location,1) == 1)
                         rightHemiLocs.Annotation=eLocs.Annotation(size(rightHemiLocs.Location,1));
                    else
                    rightHemiLocs.Annotation(size(rightHemiLocs.Location,1))=eLocs.Annotation(size(rightHemiLocs.Location,1));
                    end
                else
                    error(['Unknown vertex identifier: ' num2str(surf.Model.vertId(surfVert))]);
                end 
            end
            obj.saveSphere(lsphere,leftHemiLocs,eDef,fullfile(path,['l_' file]));
            obj.saveSphere(rsphere,rightHemiLocs,eDef,fullfile(path,['r_' file]));
        end


        function value=get.LeftSphereIdentifier(obj)
            value=['L_' obj.SphereIdentifier];
         end
        
         function value=get.RightSphereIdentifier(obj)
            value=['R_' obj.SphereIdentifier];
         end

         function saveSphere(obj,surf,eLocs,eDef,path)
            cortex=surf.Model;
            ix=1;
            cmapstruct=struct('basecol',[0.7 0.7 0.7],'fading',1,'enablecolormap',1,'enablecolorbar',1,'color_bar_ticks',4,'cmap',jet(64),...
               'ixg2',9,'ixg1',-9,'cmin',0,'cmax',0);

            viewstruct.what2view={'brain' 'electrodes'};
            viewstruct.viewvect=[270 0];
            viewstruct.lightpos=[-150 0 0];
            viewstruct.material='dull';
            viewstruct.enablelight=1;
            viewstruct.enableaxis=0;
            viewstruct.lightingtype='gouraud';

            annotation.Annotation=surf.Annotation;
            annotation.AnnotationLabel=surf.AnnotationLabel;
            electrodeDefinition.Definition=eDef.Definition;
            electrodeDefinition.Annotation=eLocs.Annotation;
            electrodeDefinition.Label=eLocs.Label;
            electrodeNames=cell(size(eLocs.DefinitionIdentifier,1),1);
            idx=1;
            order=unique(eLocs.DefinitionIdentifier,'stable');
            for i=1:length(order)
                for ii=1:eDef.Definition(order(i)).NElectrodes
                    electrodeNames{idx}=[eDef.Definition(order(i)).Name num2str(ii)];
                    idx=idx+1;
                end
            end
            electrodeDefinition.DefinitionIdentifier=eLocs.DefinitionIdentifier;
            tala=struct('electrodes',eLocs.Location,'activations',zeros(size(eLocs.Location,1),1),'trielectrodes',eLocs.Location);
            vcontribs = [];
            SecondaryLabel=eLocs.Label;
            save(path,'cortex','ix','tala','viewstruct','electrodeNames','cmapstruct','vcontribs','electrodeDefinition','annotation','SecondaryLabel');

         end
    end
end

