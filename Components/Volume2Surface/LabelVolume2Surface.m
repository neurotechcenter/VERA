classdef LabelVolume2Surface < AComponent
    %LabelVolume2Surface - Creates a 3D model surface from a Volume, assuming
    %that the Volume is a based on labels

    properties
        VolumeIdentifier
        SurfaceIdentifier
        LabelIds
        LabelNames
        Smoothing
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
            obj.Smoothing          = [];
            obj.LoadLUTFile        = "false";
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
            if(strcmp(obj.LoadLUTFile,'true'))
                return;
            elseif(strcmp(obj.LoadLUTFile,'thomas'))
                return;
            end
            if(isempty(obj.LabelIds) || (length(obj.LabelIds) ~= length(obj.LabelNames)))
                try
                    path = obj.GetDependency('Freesurfer');
                    addpath(genpath(fullfile(path,'matlab')));
                    warning(['For Component: "',obj.Name,'" no labels provided or label configuration configuration incorrect, trying Freesurfer LUT']);
                    lut_path    = fullfile(path,'FreeSurferColorLUT.txt');
                    [code, lut] = loadLUTFile(lut_path);
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
            if(strcmp(obj.LoadLUTFile,'true'))
                [file,path]=uigetfile({'*.*'},'Select LUT'); % uigetfile extension filter is broken on MacOS, so allowing all file types
                [obj.internalIds,obj.internalLabels]=loadLUTFile(fullfile(path,file));
            elseif(strcmp(obj.LoadLUTFile,'thomas'))
                path     = obj.GetDependency('Thomas');
                lut_path = fullfile(path,'CustomAtlas.ctbl');
                [obj.internalIds,obj.internalLabels]=loadLUTFile(lut_path);
            end
            % James added to deal with THOMAS lookup table
            if isa(obj.internalLabels,'char')
                obj.internalLabels = cellstr(obj.internalLabels);
            end

            surf = obj.CreateOutput(obj.SurfaceIdentifier);

            tri_tot         = [];
            vert_tot        = [];
            surf.Annotation = [];
            colmap          = distinguishable_colors(length(obj.internalIds));
            ii = 1;
            for i = 1:length(obj.internalIds)
                binaryVol = zeros(size(vol.Image.img));
                binaryVol(vol.Image.img == obj.internalIds(i)) = true;
                if(any(any(any(binaryVol)))) %only add if it exists
                    [x,y,z] = meshgrid(1:size(binaryVol,2),1:size(binaryVol,1),1:size(binaryVol,3));
                    if(~isempty(obj.Smoothing))
                        binaryVol = smooth3(binaryVol,'box',obj.Smoothing);
                    end

                    [tri,vert] = isosurface(x,y,z,binaryVol,0.1); % James set the last input, isovalue. Not sure what is the appropriate value here

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
                        warndlg(['Warning! Unable to generate surface for ',num2str(obj.internalIds(i)),', ', obj.internalLabels{i}, ' at isovalue of 0.1. ' ...
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
            surf.Model.vert = vol.Vox2Ras(vert_tot);
            surf.Model.tri  = tri_tot;

        end
    end
end

