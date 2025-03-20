classdef LabelVolume2Surface < AComponent
    %LabelVolume2Surface - Creates a 3D model surface from a Volume, assuming
    %that the Volume is a based on labels

    properties
        VolumeIdentifier
        SurfaceIdentifier
        LabelIds
        LabelNames
        Smoothing
        IsoValue
        LoadLUTFile
        Prefix
    end

    properties (Access = protected)
        internalIds
        internalLabels
    end

    methods
        function obj = LabelVolume2Surface()
            obj.VolumeIdentifier   = '';
            obj.SurfaceIdentifier  = '';
            obj.LabelIds           = [];
            obj.LabelNames         = {};
            obj.ignoreList{end+1}  = 'internalIds';
            obj.ignoreList{end+1}  = 'LabelNames';
            obj.Smoothing          = 3;
            obj.IsoValue           = 0.1;
            obj.LoadLUTFile        = 'false';
            obj.Prefix             = '';
        end

        function  Publish(obj)
            if(isempty(obj.VolumeIdentifier) || isempty(obj.SurfaceIdentifier))
                error('VolumeIdentifier or SurfaceIdentifier is empty');
            end
            obj.AddInput(obj.VolumeIdentifier,   'Volume');
            obj.AddOutput(obj.SurfaceIdentifier, 'Surface');

        end

        function Initialize(obj)
            if ~isempty(obj.LabelIds) && (length(obj.LabelIds) == length(obj.LabelNames))
                obj.internalIds    = obj.LabelIds;
                obj.internalLabels = obj.LabelNames;
            end

            path = obj.GetOptionalDependency('Freesurfer');
            addpath(genpath(fullfile(path,'matlab')));

            if strcmp(obj.LoadLUTFile,'true')
                return;
            elseif strcmp(obj.LoadLUTFile,'FreeSurferColorLUT')
                return;
            elseif strcmp(obj.LoadLUTFile,'thomas')
                return;
            elseif exist(obj.LoadLUTFile,'file')
                return;
            else
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

        function surf=Process(obj,vol)

            surf = obj.CreateOutput(obj.SurfaceIdentifier);

            if strcmp(obj.LoadLUTFile,'true')
                [file,path] = uigetfile({'*.*'},'Select LUT'); % uigetfile extension filter is broken on MacOS, so allowing all file types
                [LUT_Ids,LUT_Labels,rgbv] = loadLUTFile(fullfile(path,file));
            elseif strcmp(obj.LoadLUTFile,'FreeSurferColorLUT')
                path     = obj.GetOptionalDependency('Freesurfer');
                lut_path = fullfile(path,'FreeSurferColorLUT.txt');
                [LUT_Ids,LUT_Labels,rgbv] = loadLUTFile(lut_path);
            elseif strcmp(obj.LoadLUTFile,'thomas')
                path     = obj.GetOptionalDependency('Thomas');
                lut_path = fullfile(path,'CustomAtlas.ctbl');
                [LUT_Ids,LUT_Labels,rgbv] = loadLUTFile(lut_path);
            elseif exist(obj.LoadLUTFile,'file')
                if isAbsolutePath(obj.LoadLUTFile)
                    [path,file,ext] = fileparts(obj.LoadLUTFile);
                else
                    [path,file,ext] = fileparts(fullfile(obj.ComponentPath,'..',obj.LoadLUTFile));
                end
                lut_path = fullfile(path,[file,ext]);
                [LUT_Ids,LUT_Labels,rgbv] = loadLUTFile(lut_path);
            end

            if isa(LUT_Labels,'char')
                LUT_Labels = cellstr(LUT_Labels);
            end

            % Use the whole lookup table for the volume if no labelIds are provided
            if (isempty(obj.LabelIds) || (length(obj.LabelIds) ~= length(obj.LabelNames)))
                obj.internalIds    = LUT_Ids;
                obj.internalLabels = LUT_Labels;
            end

            % unknown labels mess with the color table. Not sure why.
            remidx = [];
            for i = 1:length(obj.internalLabels)
                if strcmp(obj.internalLabels{i},'Unknown') || strcmp(obj.internalLabels{i},'unknown')
                    remidx = [remidx, i];
                end
            end
            obj.internalIds(remidx)    = [];
            obj.internalLabels(remidx) = [];

            % Set color of surface to preferred colors in lookup table. If
            % they don't exist, make up colors
            if exist('rgbv','var')
                if ~isempty(rgbv)
                    [~,~,linenum] = intersect(obj.internalIds,LUT_Ids,'stable');
                    colmap        = rgbv(linenum,1:3)./255;
                else
                    colmap        = distinguishable_colors(length(obj.internalIds));
                end
            else
                colmap = distinguishable_colors(length(obj.internalIds));
            end

            tri_tot         = [];
            vert_tot        = [];
            surf.Annotation = [];
            ii = 1;
            for i = 1:length(obj.internalIds)
                binaryVol = zeros(size(vol.Image.img));
                binaryVol(vol.Image.img == obj.internalIds(i)) = true;
                if(any(any(any(binaryVol)))) %only add if it exists
                    [x,y,z] = meshgrid(1:size(binaryVol,2),1:size(binaryVol,1),1:size(binaryVol,3));
                    if(~isempty(obj.Smoothing))
                        binaryVol = smooth3(binaryVol,'box',obj.Smoothing);
                    end

                    [tri,vert] = isosurface(x,y,z,binaryVol,obj.IsoValue); % James set the last input, isovalue. Not sure what is the appropriate value here

                    % original
                    % tri      = tri + size(vert_tot, 1);
                    % vert     = [vert(:,2) vert(:,1) vert(:,3)];
                    % vert_tot = [vert_tot; vert];
                    % tri_tot  = [tri_tot;  tri];

                    % Another James change to add the if statement...
                    tri     = tri + size(vert_tot, 1);
                    tri_tot = [tri_tot;  tri];

                    newisoval = 0;
                    if isempty(vert)
                        [tri,vert] = isosurface(x,y,z,binaryVol);
                        newisoval  = 1;
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
                        vert = [vert(:,2) vert(:,1) vert(:,3)];
                    end

                    vert_tot = [vert_tot; vert];

                    surf.TriId                              = [surf.TriId;      obj.internalIds(i) * ones(size(tri,  1),1)];
                    surf.VertId                             = [surf.VertId;     obj.internalIds(i) * ones(size(vert, 1),1)];
                    surf.Annotation                         = [surf.Annotation; obj.internalIds(i) * ones(size(vert, 1),1)];
                    surf.AnnotationLabel(ii).Name           = obj.internalLabels{i};
                    surf.AnnotationLabel(ii).Identifier     = obj.internalIds(i);
                    surf.AnnotationLabel(ii).PreferredColor = colmap(i,:);

                    ii = ii + 1;
                end

            end

            if ~any(any(vert_tot)) || ~any(any(tri_tot)) % volume does not exist
                errordlg(['Error: Volume does not exist! Check that the specified LabelNames and LabelIds are correct ',...
                                'and that these volume labels exist in the VolumeIdentifier.'],'Volume does not exist!');
            else
                surf.Model.vert = vol.Vox2Ras(vert_tot);
                surf.Model.tri  = tri_tot;
            end
           
        end
    end
end

