classdef FreesurferThalamusSegmentation < AFSSubsegmentation
    %FreesurferThalamusSegmentation Load Freesurfers Thalamus Segmentation
    % 
    properties (Access=protected)
        ShellScriptName ='recon-thalamus.sh'
        LVolumeName ='ThalamicNuclei.v1?.T1.mgz' %Volume of left hemisphere segmentation
        RVolumeName ='ThalamicNuclei.v1?.T1.mgz'%Volume of right hemisphere segmentation, if both have the same name it is assumed to be single volume
    end

    
    methods
        function obj = FreesurferThalamusSegmentation()
            %FREESURFERTHALAMUSSEGMENTATION Construct an instance of this class
            %   Detailed explanation goes here
            obj.Name='ThalamusSegmentation';
            obj.VolumeIdentifier='Thalamus';
       %     obj.ShellScriptName='recon-thalamus.sh';
       %     obj.LVolumeName='ThalamicNuclei.v12.T1.mgz';
       %     obj.RVolumeName='ThalamicNuclei.v12.T1.mgz';
        end
        
    end
end

