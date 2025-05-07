classdef CalculateDistanceToVolumeLabel < AComponent
    %CalculateDistanceToVolumeLabel - Calculates the distance between the
    %electrode locations and all defined labels of the volume

    properties
        VolumeIdentifier
        ElectrodeLocationIdentifier
        ElectrodeLocationIdentifierOut
        LabelIds
        LabelNames
        Prefix
        LoadLUTFile
        IsoValue
    end
    properties (Access = protected)
        internalIds
        internalLabels
    end

    methods
        function obj = CalculateDistanceToVolumeLabel()
            %CALCULATECLOSESTSURFACELABEL Construct an instance of this class
            %   Detailed explanation goes here
            obj.VolumeIdentifier               = 'ASEG';
            obj.ElectrodeLocationIdentifier    = 'ElectrodeLocation';
            obj.ElectrodeLocationIdentifierOut = 'ElectrodeLocation';
            obj.ignoreList{end+1}              = 'internalIds';
            obj.ignoreList{end+1}              = 'LabelNames';
            obj.Prefix                         = '';
            obj.LoadLUTFile                    = 'false';
            obj.IsoValue                       = 0.1;
        end

        function  Publish(obj)
            obj.AddInput(obj.VolumeIdentifier,                'Volume');
            obj.AddInput(obj.ElectrodeLocationIdentifier,     'ElectrodeLocation');
            obj.AddOutput(obj.ElectrodeLocationIdentifierOut, 'ElectrodeLocation');
        end

        function Initialize(obj)
            if(strcmp(obj.LoadLUTFile,'true'))
                return;
            elseif(strcmp(obj.LoadLUTFile,'FreeSurferColorLUT'))
                return;
            elseif(strcmp(obj.LoadLUTFile,'thomas'))
                return;
            elseif exist(obj.LoadLUTFile,'file')
                return;
            else
                path = obj.GetOptionalDependency('Freesurfer');
                addpath(genpath(fullfile(path,'matlab')));
                fprintf(['For Component: "',obj.Name,'"\nno labels provided or label configuration incorrect,\ntrying Freesurfer LUT\n\n']);
                lut_path    = fullfile(path,'FreeSurferColorLUT.txt');
                [code, lut] = loadLUTFile(lut_path);
            end
            if(isempty(obj.LabelIds) || (length(obj.LabelIds) ~= length(obj.LabelNames)))
                try
                    if(isempty(obj.LabelIds))
                        obj.internalIds = code;
                    else
                        obj.internalIds = obj.LabelIds;
                    end
                    obj.internalLabels = {};
                    for i = 1:length(obj.internalIds)
                        if(any(code == obj.internalIds(i)))
                            if(strcmpi(strtrim(lut(code == obj.internalIds(i),:)),'UNKNOWN'))
                                obj.internalLabels{i} = 'unknown'; %no need to add prefix for unknown, also normalize way it is written as label
                            else
                                obj.internalLabels{i} = [obj.Prefix strtrim(lut(code == obj.internalIds(i),:))];
                            end
                        else
                            obj.internalLabels{i} = 'unknown';
                        end
                    end

                catch e
                    error("Each label needs a Name! - make sure LabelNames is set correctly");
                end

            else
                obj.internalIds    = obj.LabelIds;
                obj.internalLabels = obj.LabelNames;
            end
        end

        function out = Process(obj,vol,elLocs)
            if strcmp(obj.LoadLUTFile,'true')
                [file,path] = uigetfile({'*.*'},'Select LUT'); % uigetfile extension filter is broken on MacOS, so allowing all file types
                [obj.internalIds,obj.internalLabels] = loadLUTFile(fullfile(path,file));
            elseif strcmp(obj.LoadLUTFile,'FreeSurferColorLUT')
                path     = obj.GetOptionalDependency('Freesurfer');
                lut_path = fullfile(path,'FreeSurferColorLUT.txt');
                [obj.internalIds,obj.internalLabels] = loadLUTFile(lut_path);
            elseif strcmp(obj.LoadLUTFile,'thomas')
                path     = obj.GetOptionalDependency('Thomas');
                lut_path = fullfile(path,'CustomAtlas.ctbl');
                [obj.internalIds,obj.internalLabels] = loadLUTFile(lut_path);
            elseif exist(obj.LoadLUTFile,'file')
                if isAbsolutePath(obj.LoadLUTFile)
                    [path,file,ext] = fileparts(obj.LoadLUTFile);
                else
                    [path,file,ext] = fileparts(fullfile(obj.ComponentPath,'..',obj.LoadLUTFile));
                end
                lut_path = fullfile(path,[file,ext]);
                [obj.internalIds,obj.internalLabels] = loadLUTFile(lut_path);
            end

            % James added to deal with THOMAS lookup table
            if isa(obj.internalLabels,'char')
                obj.internalLabels = cellstr(obj.internalLabels);
            end
            
            out = obj.CreateOutput(obj.ElectrodeLocationIdentifierOut,elLocs);
            f   = waitbar(0,'Calculating Distance from Electrode to Labels');
            for i = 1:length(obj.internalIds)
                binaryVol = zeros(size(vol.Image.img));
                binaryVol(vol.Image.img == obj.internalIds(i))=true;
                waitbar(i/length(obj.internalIds),f);
                if(any(any(any(binaryVol)))) %only check if exists
                    [x,y,z] = meshgrid(1:size(binaryVol,2),1:size(binaryVol,1),1:size(binaryVol,3));

                    [~,vert] = isosurface(x,y,z,binaryVol,obj.IsoValue); 

                    newisoval = 0;
                    if isempty(vert)
                        [~,vert]  = isosurface(x,y,z,binaryVol);
                        newisoval = 1;
                    end

                    if ~isempty(vert) && newisoval
                        warndlg(['Warning! Unable to generate surface for ',num2str(obj.internalIds(i)),', ', obj.internalLabels{i},...
                            ' at isovalue of ',num2str(obj.IsoValue),'. ' ...
                            'Surface generated at different isovalue.']);
                    end

                    if isempty(vert)
                        warndlg(['Warning! Unable to generate surface for ',num2str(obj.internalIds(i)),', ', obj.internalLabels{i}]);
                        vert = [];
                    else
                        vert = [vert(:,2) vert(:,1) vert(:,3)]; % reorient from matlabs normal view...
                    end

                    vert = vol.Vox2Ras(vert);
                    for i_loc = 1:size(out.Location,1)
                        [~,dist] = findNearestNeighbors(pointCloud(vert),out.Location(i_loc,:),1);
                        old_data          = out.GetAnnotation(i_loc, 'Distance');
                        old_data_label    = out.GetAnnotation(i_loc, 'Label');
                        old_data_label_id = out.GetAnnotation(i_loc, 'LabelId');

                        voxLoc = round(vol.Ras2Vox(out.Location(i_loc,:)));
                        if((voxLoc(1) <= size(binaryVol,1)) &&... % if inside of brain?
                                (voxLoc(2) <= size(binaryVol,2)) &&...
                                (voxLoc(3) <= size(binaryVol,3)) &&...
                                all(voxLoc >= 1))
                            if(binaryVol(voxLoc(1),voxLoc(2),voxLoc(3))) % if inside of given brain area?
                                out.AddLabel(i_loc,obj.internalLabels{i});
                                dist = 0; %distance set to 0 if inside
                            end
                        end
                        old_data(end+1)          = dist;
                        old_data_label{end+1}    = obj.internalLabels{i};
                        old_data_label_id(end+1) = obj.internalIds(i);
                        out.SetAnnotation(i_loc, 'Distance', old_data);
                        out.SetAnnotation(i_loc, 'Label',    old_data_label);
                        out.SetAnnotation(i_loc, 'LabelId',  old_data_label_id);
                    end
                end
            end
            close(f);
        end
    end
end

