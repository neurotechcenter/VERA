% Script to convert the VERA output structure from the legacy format to
% the new format, or the opposite

clear;
clc;

% Add VERA dependencies to path
p = mfilename('fullpath');
FILEPATH = fileparts(p);
addpath(genpath(fullfile(FILEPATH,'..','..','classes')));
addpath(genpath(fullfile(FILEPATH,'..','..','Components')));
addpath(genpath(fullfile(FILEPATH,'..','..','dependencies')));
clear p FILEPATH

% Select file to loadck
[file,path] = uigetfile('*.mat','Select brain.mat file to load','MultiSelect','off');
if path == 0
    fprintf('\nError: Please select at least one file.\n')
    return;
end

load(fullfile(path,file));

if ~exist('electrodeNamesKey', 'var')
    electrodeNamesKey  = []; % Key relating EEG recorded electrode names (from amplifier) to VERA electrode names (from VERA Electrode Definition/ROSA)
end

% convert from Legacy to New format
if exist('tala','var')
    [surfaceModel, electrodes] = ConvertLegacyToNew(cortex, annotation, electrodeDefinition, electrodeNames, tala);

    % Save
    [~,file,ext] = fileparts(file);
    save(fullfile(path,[file,'_new',ext]), 'surfaceModel', 'electrodes', 'electrodeNamesKey')
    msgbox(['File saved as: ',GetFullPath(fullfile(path,[file,'_new',ext]))],'Converted from Legacy to New Format')

% convert from New to Legacy format
elseif exist('surfaceModel','var')
    [cortex, annotation, electrodeNames, electrodeDefinition, tala,...
    electrodeLabels, LabelName, SecondaryLabel, cmapstruct, viewstruct, vcontribs, ix] = ConvertNewToLegacy(surfaceModel, electrodes);

    % Save
    [~,file,ext] = fileparts(file);
    save(fullfile(path,[file,'_legacy',ext]), 'cortex', 'annotation', 'electrodeNames', 'electrodeDefinition', 'tala',...
    'electrodeLabels', 'LabelName', 'SecondaryLabel', 'cmapstruct', 'viewstruct', 'vcontribs', 'ix', 'electrodeNamesKey')
    msgbox(['File saved as: ',GetFullPath(fullfile(path,[file,'_legacy',ext]))],'Converted from New to Legacy Format')
else
    fprintf('\nUnfamiliar file loaded. Please load output of\nMatOutput or MatOutput_legacy component.\n\n')
end


function [surfaceModel, electrodes] = ConvertLegacyToNew(cortex, annotation, electrodeDefinition, electrodeNames, tala)
    surfaceModel.Model              = cortex;                                   % Surface model (in vertId/triId, 1 is left hemisphere and 2 is right)
    surfaceModel.Annotation         = annotation.Annotation;                    % Identifier number associating each vertice of a surface with a given annotation
    surfaceModel.AnnotationLabel    = annotation.AnnotationLabel;               % Surface annotation map connecting identifier values with annotation
    
    electrodes.Definition           = electrodeDefinition.Definition;           % Implanted grid/shank type, name, NElectrodes, spacing, and volume
    electrodes.DefinitionIdentifier = electrodeDefinition.DefinitionIdentifier; % Number associating individual channels with its implant
    electrodes.Annotation           = electrodeDefinition.Annotation;           % Results of calculation determining the distance from each electrode to each volume (voxel) label.
                                                                                % The nearest distance to each unique label found is stored.
    electrodes.Label                = electrodeDefinition.Label;                % Nearest voxel label to the electrode coordinates, accounting for ReplaceLabels component if used.
                                                                                % If ReplaceLabels is not used, a label for each distance calculation is stored 
                                                                                % (e.g. if the distance to volume labels and the left hippocampus are calculated, two labels will be stored). 
                                                                                % (same as old SecondaryLabel)
    electrodes.Name                 = electrodeNames;                           % electrode names
    electrodes.Location             = tala.electrodes;                          % electrode locations (x,y,z)
end

function [cortex, annotation, electrodeNames, electrodeDefinition, tala,...
    electrodeLabels, LabelName, SecondaryLabel, cmapstruct, viewstruct, vcontribs, ix] = ConvertNewToLegacy(surfaceModel, electrodes)

    % surface model
    cortex = surfaceModel.Model;

    % surface annotation
    annotation.Annotation      = surfaceModel.Annotation;
    annotation.AnnotationLabel = surfaceModel.AnnotationLabel;

    % electrode names
    electrodeNames = electrodes.Name;

    % VERA's electrode definition. Also includes electrode annotations
    electrodeDefinition.Definition           = electrodes.Definition;
    electrodeDefinition.Annotation           = electrodes.Annotation;
    electrodeDefinition.Label                = electrodes.Label;
    electrodeDefinition.DefinitionIdentifier = electrodes.DefinitionIdentifier;

    % electrode locations stored in tala structure for legacy reasons
    tala = struct('electrodes',electrodes.Location,'activations',zeros(size(electrodes.Location,1),1),'trielectrodes',electrodes.Location);

    % Surface labels applied to electrodes
    [electrodeLabels,LabelName]  = findLabels(electrodes,surfaceModel); % electrodeLabels: unique number identifying electrode location
                                                                        % LabelName:       map pointing to given label
                                                                        % LabelName(electrodeLabels(1)) would give the label of electrode 1

    % Same as labels found in electrodeDefinition structure
    SecondaryLabel = electrodes.Label;

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
end

function [labelId, labelName] = findLabels(elocs,surf)
     labelId   = zeros(length(elocs.Location),1);
     labelName = containers.Map('KeyType','double','ValueType','char');

     for ie = 1:length(elocs.Location)
        p = elocs.Location(ie,:); % electrode position

        [~,vId]     = min((surf.Model.vert(:,1)-p(1)).^2 + (surf.Model.vert(:,2)-p(2)).^2 + (surf.Model.vert(:,3)-p(3)).^2);
        labelId(ie) = surf.Annotation(vId);

        if(~isempty(surf.AnnotationLabel))
            labelName(labelId(ie)) = ['' surf.AnnotationLabel(([surf.AnnotationLabel.Identifier] == labelId(ie))).Name];
        end
     end
end