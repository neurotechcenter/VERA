classdef LoadThomasSegmentation < AComponent
    % LoadThomasSegmentation Run Thomas thalamic segmentation within VERA
    % MRIIdentifier can be MRI or FGATIR

    properties
        InputFilepath char
        LeftVolumeIdentifier
        RightVolumeIdentifier
        SegmentationPathIdentifier
    end

    methods
        function obj = LoadThomasSegmentation()
            obj.InputFilepath              = '';
            obj.LeftVolumeIdentifier       = 'LThomasVolume';
            obj.RightVolumeIdentifier      = 'RThomasVolume';
            obj.SegmentationPathIdentifier = 'ThomasSegmentationPath';
        end

        function Publish(obj)
            obj.AddOutput(obj.LeftVolumeIdentifier,       'Volume');
            obj.AddOutput(obj.RightVolumeIdentifier,      'Volume');
            obj.AddOutput(obj.SegmentationPathIdentifier, 'PathInformation');
        end

        function Initialize(obj)

        end

        function [Lvolout, Rvolout, pathInfo] = Process(obj)

            if ~isempty(obj.InputFilepath)
                % working directory is VERA project
                if isAbsolutePath(obj.InputFilepath)
                    path = obj.InputFilepath;
                else
                    path = fullfile(obj.ComponentPath,'..',obj.InputFilepath);
                    path = GetFullPath(path);
                end

                % Open a file load dialog if you can't find the path
                if ~exist(path,'dir')
                    segmentationPath = uigetdir([],'Please select Thomas Segmentation Folder');
                else
                    segmentationPath = path;
                end

            else
                segmentationPath = uigetdir([],'Please select Thomas Segmentation Folder');
            end

            Lnii_path = fullfile(segmentationPath, 'left', 'thomasfull_L.nii.gz');
            if ~exist(Lnii_path,'file')
                error('Could not find thomasfull_L.nii.gz in the Thomas segmentation folder! Please check if you selected the correct folder!');
            end

            Rnii_path = fullfile(segmentationPath, 'right', 'thomasfull_R.nii.gz');
            if ~exist(Rnii_path,'file')
                error('Could not find thomasfull_R.nii.gz in the Thomas segmentation folder! Please check if you selected the correct folder!');
            end

            segmentationFolder = fullfile(obj.ComponentPath,'Segmentation');
            copyfile(segmentationPath, segmentationFolder);

            % Left
            Lvolout           = obj.CreateOutput(obj.LeftVolumeIdentifier);
            Lnii_path_reslice = fullfile(segmentationPath, 'left', 'thomasfull_L_reslice.nii.gz');

            reslice_nii(Lnii_path, Lnii_path_reslice); % needed to reslice because the tolerance of 0 is too low for FGATIR image

            Lvolout.LoadFromFile(Lnii_path_reslice);

            % Right
            Rvolout           = obj.CreateOutput(obj.RightVolumeIdentifier);
            Rnii_path_reslice = fullfile(segmentationPath, 'right', 'thomasfull_R_reslice.nii.gz');

            reslice_nii(Rnii_path, Rnii_path_reslice);

            Rvolout.LoadFromFile(Rnii_path_reslice);

            % Path
            pathInfo      = obj.CreateOutput(obj.SegmentationPathIdentifier);
            pathInfo.Path = segmentationPath;

        end
    end
end

