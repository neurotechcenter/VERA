classdef ImportFreesurferSegmentation < AComponent
    %ImportFreesurferSegmentation Imports the freesurfer segmentation by
    %creating a local copy within VERA

    properties
        SegmentationPathIdentifier
        InputFilepath char
    end

    methods
        function obj = ImportFreesurferSegmentation()
            %IMPORTFREESURFERSEGMENTATION Construct an instance of this class
            %   Detailed explanation goes here
            obj.SegmentationPathIdentifier = 'SegmentationPath';
            obj.InputFilepath              = '';
        end

        function Publish(obj)
            obj.AddOutput(obj.SegmentationPathIdentifier,'PathInformation');
        end

        function Initialize(obj)
        end

        function [outPath]=Process(obj)
            if ~isempty(obj.InputFilepath)
                segmentationPath = fullfile(obj.ComponentPath,'..','..',obj.InputFilepath);

                % Open a file load dialog if you can't find the path
                if ~exist(segmentationPath,'dir')
                    segmentationPath = uigetdir([],'Please select Freesurfer Folder');
                end
            else
                segmentationPath = uigetdir([],'Please select Freesurfer Folder');
            end

            mri_path = fullfile(segmentationPath,'mri/orig.mgz');
            if(~exist(mri_path,"file"))
                error('Could not find orig.mgz in the Freesurfer segmentation folder! Please check if you selected the correct folder!');
            end

            segmentationFolder = fullfile(obj.ComponentPath,'segmentation');
            copyfile(segmentationPath,segmentationFolder);
            outPath      = obj.CreateOutput(obj.SegmentationPathIdentifier);
            [~,b]        = fileparts(obj.ComponentPath);
            outPath.Path = fullfile('./',b,'segmentation');
        end
    end
end

