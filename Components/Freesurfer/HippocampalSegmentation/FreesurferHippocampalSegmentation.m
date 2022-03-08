classdef FreesurferHippocampalSegmentation < AComponent
    %FreesurferHippocampalSegmentation runs Freesurfers hippocampal
    %subsegmentation and loads the volume with L and R prefixes
    
    properties
        VolumeIdentifier
        SegmentationPathIdentifier
    end
    
    methods
        function obj = FreesurferHippocampalSegmentation()
            obj.VolumeIdentifier='Hippocampus';
            obj.SegmentationPathIdentifier='SegmentationPath';
        end
        
        function Publish(obj)
            obj.AddOptionalInput(obj.SegmentationPathIdentifier,'PathInformation');
            obj.AddOutput(['L' obj.VolumeIdentifier],'Volume');
            obj.AddOutput(['R' obj.VolumeIdentifier],'Volume');
        end
        

    end
end

