classdef MatOutputwithLimbicSystem < AComponent
    %MatOutputwithLimbicSystem Creates a .mat file of the limbic system similar to neuralact
    %but with additional information about electrode locations
    properties
        ElectrodeLocationIdentifier
        ElectrodeDefinitionIdentifier
        SurfaceIdentifier1
        SurfaceIdentifier2
        SurfaceIdentifier3
        SurfaceIdentifier4
        SurfaceIdentifier5
    end
    
    methods
        function obj = MatOutputwithLimbicSystem()
            obj.ElectrodeLocationIdentifier   = 'ElectrodeLocation';
            obj.ElectrodeDefinitionIdentifier = 'ElectrodeDefinition';
            obj.SurfaceIdentifier1            = 'Surface';
            obj.SurfaceIdentifier2            = 'LHippocampusSurface';
            obj.SurfaceIdentifier3            = 'RHippocampusSurface';
            obj.SurfaceIdentifier4            = 'ThalamusSurface';
            obj.SurfaceIdentifier5            = 'CingulateSurface';
        end
        
        function Publish(obj)
            obj.AddInput(obj.ElectrodeLocationIdentifier,   'ElectrodeLocation');
            obj.AddInput(obj.ElectrodeDefinitionIdentifier, 'ElectrodeDefinition');
            obj.AddInput(obj.SurfaceIdentifier1,            'Surface');
            obj.AddInput(obj.SurfaceIdentifier2,            'Surface');
            obj.AddInput(obj.SurfaceIdentifier3,            'Surface');
            obj.AddInput(obj.SurfaceIdentifier4,            'Surface');
            obj.AddInput(obj.SurfaceIdentifier5,            'Surface');
            
        end
        
        
        function Initialize(obj)
        end
        
        function []= Process(obj, eLocs,eDef,surf1,surf2,surf3,surf4,surf5)
            
            [file,path]=uiputfile('*.mat');
            if isequal(file,0) || isequal(path,0)
                error('Selection aborted');
            end

            cortex        = surf1.Model;
            LHippocampus  = surf2.Model;
            RHippocampus  = surf3.Model;
            Thalamus      = surf4.Model;
            Cingulate     = surf5.Model;

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
            annotation.Annotation                    = surf1.Annotation;
            annotation.AnnotationLabel               = surf1.AnnotationLabel;
            LHippocampus_annotation.Annotation       = surf2.Annotation;
            LHippocampus_annotation.AnnotationLabel  = surf2.AnnotationLabel;
            RHippocampus_annotation.Annotation       = surf3.Annotation;
            RHippocampus_annotation.AnnotationLabel  = surf3.AnnotationLabel;
            Thalamus_annotation.Annotation           = surf4.Annotation;
            Thalamus_annotation.AnnotationLabel      = surf4.AnnotationLabel;
            Cingulate_annotation.Annotation          = surf5.Annotation;
            Cingulate_annotation.AnnotationLabel     = surf5.AnnotationLabel;
            electrodeDefinition.Definition           = eDef.Definition;
            electrodeDefinition.Annotation           = eLocs.Annotation;
            electrodeDefinition.Label                = eLocs.Label;
            electrodeNames                           = eLocs.GetElectrodeNames(eDef);
            electrodeDefinition.DefinitionIdentifier = eLocs.DefinitionIdentifier;
            tala                                     = struct('electrodes',eLocs.Location,'activations',zeros(size(eLocs.Location,1),1),'trielectrodes',eLocs.Location);
            vcontribs                                = [];
            SecondaryLabel                           = eLocs.Label;

            save(fullfile(path,file),'cortex','LHippocampus','RHippocampus','Thalamus','Cingulate','ix','tala','viewstruct','electrodeNames','cmapstruct','vcontribs',...
                'electrodeDefinition','electrodeLabels','LabelName','annotation','LHippocampus_annotation','RHippocampus_annotation','Thalamus_annotation','Cingulate_annotation','SecondaryLabel');
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

