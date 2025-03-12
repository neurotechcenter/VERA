classdef MatOutput < AComponent
    %MatOutput Creates a .mat file as Output of VERA with information
    %about electrode locations, the surface model, and any surface
    %annotations and electrode labels generated
    properties
        ElectrodeLocationIdentifier
        ElectrodeDefinitionIdentifier
        SurfaceIdentifier
        SavePathIdentifier char
        EEGNamesIdentifier
    end

    methods
        function obj = MatOutput()
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

        function [] = Process(obj, eLocs, eDef, surf, varargin)

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

            surfaceModel.Model              = surf.Model;                    % Contains vert (x,y,z points) and tri (triangle triangulation vector) to create the 3D model
            % specified through SurfaceIdentifier in VERA. Additionally, it also contains triId and vertId,
            % which allows you to distinguish between the left (1) and right (2) hemisphere if your data
            % comes from a freesurfer Surface.
            surfaceModel.Annotation         = surf.Annotation;               % Identifier number associating each vertice of a surface with a given annotation
            surfaceModel.AnnotationLabel    = surf.AnnotationLabel;          % Surface annotation map connecting identifier values with annotation

            electrodes.Definition           = eDef.Definition;               % Implanted grid/shank type, name, NElectrodes, spacing, and volume
            electrodes.DefinitionIdentifier = eLocs.DefinitionIdentifier;    % Number associating individual electrodes with their implant
            electrodes.Annotation           = eLocs.Annotation;              % Results of calculation determining the distance from each electrode to each volume (voxel) label.
                                                                             % The nearest distance to each unique label found is stored.
            electrodes.Label                = eLocs.Label;                   % Nearest voxel label to the electrode coordinates, accounting for ReplaceLabels component if used.
                                                                             % If ReplaceLabels is not used, a label for each distance calculation is stored 
                                                                             % (e.g. if the distance to volume labels and the left hippocampus are calculated, two labels will be stored). 
                                                                             % (same as old SecondaryLabel)
            electrodes.Name                 = eLocs.GetElectrodeNames(eDef); % name of each electrode based on their association with the ElectrodeDefinition
            electrodes.Location             = eLocs.Location;                % electrode locations (x,y,z)

            electrodeNamesKey               = elecNamesKey.Definition;       % Key relating EEG recorded electrode names (from amplifier) to VERA electrode names (from VERA Electrode Definition/ROSA)

            save(fullfile(path,file),'surfaceModel','electrodes','electrodeNamesKey');

            % Popup stating where file was saved
            message    = {'File saved as:',GetFullPath(fullfile(path,file))};
            msgBoxSize = [350, 125];
            obj.VERAMessageBox(message,msgBoxSize);
        end

    end
end

