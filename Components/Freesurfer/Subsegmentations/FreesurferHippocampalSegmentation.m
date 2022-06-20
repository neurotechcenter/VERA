classdef FreesurferHippocampalSegmentation < AFSSubsegmentation
    %FreesurferHippocampalSegmentation runs Freesurfers hippocampal
    %subsegmentation and loads the volume with L and R prefixes
    

    properties (Access=protected)
        ShellScriptName ='recon-hippocampus.sh'
        LVolumeName ='lh.hippoAmygLabels-T1.v21.mgz' %Volume of left hemisphere segmentation
        RVolumeName ='rh.hippoAmygLabels-T1.v21.mgz'%Volume of right hemisphere segmentation, if both have the same name it is assumed to be single volume
    end
    
    methods
        function obj = FreesurferHippocampalSegmentation()
            obj.VolumeIdentifier='Hippocampus';
        end 

    end
end

