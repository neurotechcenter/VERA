classdef MatOutputwithHippocampus < AComponent
    %MATOUTPUT Creates a .mat file as Output of VERA similar to neuralact
    %but with additional information about electrode locations
    properties
        ElectrodeLocationIdentifier
        ElectrodeDefinitionIdentifier
        SurfaceIdentifier1
        SurfaceIdentifier2
        SurfaceIdentifier3
    end
    
    methods
        function obj = MatOutputwithHippocampus()
            obj.ElectrodeLocationIdentifier   = 'ElectrodeLocation';
            obj.ElectrodeDefinitionIdentifier = 'ElectrodeDefinition';
            obj.SurfaceIdentifier1            = 'Surface';
            obj.SurfaceIdentifier2            = 'LHippocampusSurface';
            obj.SurfaceIdentifier3            = 'RHippocampusSurface';
        end
        
        function Publish(obj)
            obj.AddInput(obj.ElectrodeLocationIdentifier,'ElectrodeLocation');
            obj.AddInput(obj.ElectrodeDefinitionIdentifier,'ElectrodeDefinition');
            obj.AddInput(obj.SurfaceIdentifier1,'Surface');
            obj.AddInput(obj.SurfaceIdentifier2,'Surface');
            obj.AddInput(obj.SurfaceIdentifier3,'Surface');
            
        end
        
        
        function Initialize(obj)
        end
        
        function []= Process(obj, eLocs,eDef,surf1,surf2,surf3)
            
            [file,path]=uiputfile('*.mat');
            if isequal(file,0) || isequal(path,0)
                error('Selection aborted');
            end

            cortex        = surf1.Model;
            LHippocampus  = surf2.Model;
            RHippocampus  = surf3.Model;

            ix = 1;
            cmapstruct = struct('basecol',[0.7 0.7 0.7],'fading',1,'enablecolormap',1,'enablecolorbar',1,'color_bar_ticks',4,'cmap',jet(64),...
               'ixg2',9,'ixg1',-9,'cmin',0,'cmax',0);

            viewstruct.what2view                     = {'brain' 'electrodes'};
            viewstruct.viewvect                      = [270 0];
            viewstruct.lightpos                      = [-150 0 0];
            viewstruct.material                      = 'dull';
            viewstruct.enablelight                   = 1;
            viewstruct.enableaxis                    = 0;
            viewstruct.lightingtype                  = 'gouraud';
            [electrodeLabels,LabelName]              = obj.findLabels(eLocs,surf1);
            cortex_annotation.Annotation             = surf1.Annotation;
            cortex_annotation.AnnotationLabel        = surf1.AnnotationLabel;
            LHippocampus_annotation.Annotation       = surf2.Annotation;
            LHippocampus_annotation.AnnotationLabel  = surf2.AnnotationLabel;
            RHippocampus_annotation.Annotation       = surf3.Annotation;
            RHippocampus_annotation.AnnotationLabel  = surf3.AnnotationLabel;
            electrodeDefinition.Definition           = eDef.Definition;
            electrodeDefinition.Annotation           = eLocs.Annotation;
            electrodeDefinition.Label                = eLocs.Label;
            electrodeNames                           = eLocs.GetElectrodeNames(eDef);
            electrodeDefinition.DefinitionIdentifier = eLocs.DefinitionIdentifier;
            tala                                     = struct('electrodes',eLocs.Location,'activations',zeros(size(eLocs.Location,1),1),'trielectrodes',eLocs.Location);
            vcontribs                                = [];
            SecondaryLabel                           = eLocs.Label;

            save(fullfile(path,file),'cortex','LHippocampus','RHippocampus','ix','tala','viewstruct','electrodeNames','cmapstruct','vcontribs',...
                'electrodeDefinition','electrodeLabels','LabelName','cortex_annotation','LHippocampus_annotation','RHippocampus_annotation','SecondaryLabel');
        end
        
        function [labelId,labelName]=findLabels(~,elocs,surf)
             labelId   = zeros(length(elocs.Location),1);
             labelName = containers.Map('KeyType','double','ValueType','char');
             for ie=1:length(elocs.Location)
                 p          = elocs.Location(ie,:);
                [~,vId]     = min((surf.Model.vert(:,1)-p(1)).^2 + (surf.Model.vert(:,2)-p(2)).^2 + (surf.Model.vert(:,3)-p(3)).^2);
                labelId(ie) = surf.Annotation(vId);
                if(~isempty(surf.AnnotationLabel))
                    labelName(labelId(ie)) = ['' surf.AnnotationLabel(([surf.AnnotationLabel.Identifier] == labelId(ie))).Name];
                end
             end
        end
        

    end
end

