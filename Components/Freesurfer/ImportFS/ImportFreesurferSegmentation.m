classdef ImportFreesurferSegmentation < AComponent
    %IMPORTFREESURFERSEGMENTATION Imports the freesurfer segmentation by
    %creating a local copy within VERA
    
    properties
        SegmentationPathIdentifier
    end
    
    methods
        function obj = ImportFreesurferSegmentation()
            %IMPORTFREESURFERSEGMENTATION Construct an instance of this class
            %   Detailed explanation goes here
            obj.SegmentationPathIdentifier='SegmentationPath';
        end
        
        function Publish(obj)
            obj.AddOutput(obj.SegmentationPathIdentifier,'PathInformation');
        end

        function Initialize(obj)
        end

        function [outPath]=Process(obj)
            [segmentationPath]=uigetdir([],'Please select Freesurfer Folder');
            mri_path=fullfile(segmentationPath,'mri/orig.mgz');
            if(~exist(mri_path,"file"))
                error('Could not find orig.mgz in the Freesurfer segmentation folder! Please check if you selected the correct folder!');
            end

            segmentationFolder=fullfile(obj.ComponentPath,'segmentation');
            copyfile(segmentationPath,segmentationFolder);
            outPath=obj.CreateOutput(obj.SegmentationPathIdentifier);
            [~,b]=fileparts(obj.ComponentPath);
            outPath.Path=fullfile('./',b,'segmentation');
        end
    end
end

