classdef MatOutputLegacy < AComponent
    %MatOutput_legacy Creates a .mat file as Output of VERA similar to neuralact
    %but with additional information about electrode locations
    properties
        ElectrodeLocationIdentifier
        ElectrodeDefinitionIdentifier
        SurfaceIdentifier
        SavePathIdentifier char
        EEGNamesIdentifier
    end
    
    methods
        function obj = MatOutputLegacy()
            obj.ElectrodeLocationIdentifier   = 'ElectrodeLocation';
            obj.ElectrodeDefinitionIdentifier = 'ElectrodeDefinition';
            obj.SurfaceIdentifier             = 'Surface';
            obj.SavePathIdentifier            = 'default';
            obj.EEGNamesIdentifier            = 'EEGNames';
        end
        
        function Publish(obj)
            obj.AddInput(obj.ElectrodeLocationIdentifier,   'ElectrodeLocation');
            obj.AddInput(obj.ElectrodeDefinitionIdentifier, 'ElectrodeDefinition');
            obj.AddInput(obj.SurfaceIdentifier,             'Surface');
            obj.AddOptionalInput(obj.EEGNamesIdentifier,    'ElectrodeDefinition');             
        end
        
        function Initialize(obj)
        end
        
        function []= Process(obj, eLocs,eDef,surf,varargin)
            
            % create output file in DataOutput folder with ProjectName_ComponentName.mat (default behavior)
            if strcmp(obj.SavePathIdentifier,'default')
                ProjectPath      = fileparts(obj.ComponentPath);
                [~, ProjectName] = fileparts(ProjectPath);

                path = fullfile(obj.ComponentPath,'..','DataOutput');
                file = [ProjectName, '_', obj.Name,'.mat'];

            % if empty, use dialog
            elseif isempty(obj.SavePathIdentifier)
                [file, path] = uiputfile('*.mat');
                if isequal(file, 0) || isequal(path, 0)
                    error('Selection aborted');
                end

            % Otherwise, save with specified file name
            else
                [path, file, ext] = fileparts(obj.SavePathIdentifier);
                file = [file,ext];
                path = fullfile(obj.ComponentPath,'..',path);

                if ~strcmp(ext,'.mat')
                    path = fullfile(obj.ComponentPath,'..',obj.SavePathIdentifier);
                    file = [obj.Name,'.mat'];
                end
            end

            % convert spaces to underscores
            file = replace(file,' ','_');

            % create save folder if it doesn't exist
            if ~isfolder(path)
                mkdir(path)
            end

            if ~isempty(varargin)
                elecNamesKey.Definition = varargin{1,2}.Definition;
            else
                elecNamesKey.Definition = [];
            end
    
            % surface model
            cortex = surf.Model;

            % surface annotation
            annotation.Annotation      = surf.Annotation;
            annotation.AnnotationLabel = surf.AnnotationLabel;

            % electrode names
            electrodeNames = eLocs.GetElectrodeNames(eDef);

            % VERA's electrode definition. Also includes electrode annotations
            electrodeDefinition.Definition           = eDef.Definition;
            electrodeDefinition.Annotation           = eLocs.Annotation;
            electrodeDefinition.Label                = eLocs.Label;
            electrodeDefinition.DefinitionIdentifier = eLocs.DefinitionIdentifier;

            % electrode locations stored in tala structure for legacy reasons
            tala = struct('electrodes',eLocs.Location,'activations',zeros(size(eLocs.Location,1),1),'trielectrodes',eLocs.Location);

            % Surface labels applied to electrodes
            [electrodeLabels,LabelName]  = obj.findLabels(eLocs,surf); % electrodeLabels: unique number identifying electrode location
                                                                       % LabelName:       map pointing to given label from the surface
                                                                       % LabelName(electrodeLabels(1)) would give the label of electrode 1

            % Same as labels found in electrodeDefinition structure
            SecondaryLabel = eLocs.Label;

            % Legacy colormap from Neuralact days
            cmapstruct = struct('basecol',[0.7 0.7 0.7],'fading',1,'enablecolormap',1,'enablecolorbar',1,'color_bar_ticks',4,'cmap',jet(64),...
               'ixg2',9,'ixg1',-9,'cmin',0,'cmax',0);

            % Legacy view struct from NeuralAct days
            viewstruct.what2view    = {'brain' 'electrodes'};
            viewstruct.viewvect     = [270 0];
            viewstruct.lightpos     = [-150 0 0];
            viewstruct.material     = 'dull';
            viewstruct.enablelight  = 1;
            viewstruct.enableaxis   = 0;
            viewstruct.lightingtype = 'gouraud';

            % Legacy variables from NeuralAct days
            vcontribs = [];
            ix        = 1;

            % Key relating EEG recorded electrode names (from amplifier) to VERA electrode names (from VERA Electrode Definition/ROSA)
            electrodeNamesKey = elecNamesKey.Definition;


            % save file 
            save(fullfile(path,file),'cortex','ix','tala','viewstruct','electrodeNames','cmapstruct','vcontribs','electrodeDefinition',...
                'electrodeLabels','LabelName','annotation','SecondaryLabel','electrodeNamesKey');

            % Popup stating where file was saved
            message    = {'File saved as:',GetFullPath(fullfile(path,file))};
            msgBoxSize = [350, 125];
            obj.VERAMessageBox(message,msgBoxSize);
        end
        
        function [labelId,labelName] = findLabels(~,elocs,surf)
             labelId   = zeros(length(elocs.Location),1);
             labelName = containers.Map('KeyType','double','ValueType','char');

             for ie = 1:length(elocs.Location)
                p           = elocs.Location(ie,:);
                [~,vId]     = min((surf.Model.vert(:,1)-p(1)).^2 + (surf.Model.vert(:,2)-p(2)).^2 + (surf.Model.vert(:,3)-p(3)).^2);
                labelId(ie) = surf.Annotation(vId);

                if(~isempty(surf.AnnotationLabel))
                    labelName(labelId(ie)) = ['' surf.AnnotationLabel(([surf.AnnotationLabel.Identifier] == labelId(ie))).Name];
                end
             end
        end
        

    end
end

