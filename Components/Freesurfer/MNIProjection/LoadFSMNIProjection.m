classdef LoadFSMNIProjection < AComponent
    %LoadFSMNIProjection - Load transformation matrix for FS MNI305
    %from a Freesurfer project
    
    properties
       SegmentationPathIdentifier
       TIdentifier

    end
    
    methods
        function obj = LoadFSMNIProjection()
            obj.SegmentationPathIdentifier='SegmentationPath';
            obj.TIdentifier='T_MNI';
        end
        
        function Publish(obj)
            obj.AddOptionalInput(obj.SegmentationPathIdentifier,'PathInformation',true);
            obj.AddOutput(obj.TIdentifier,'TransformationMatrix');
        end
        
        function Initialize(obj)
            path=obj.GetDependency('Freesurfer');
            addpath(fullfile(path,'matlab'));
        end
        
        function T=Process(obj,optInp)
            if(nargin > 1) %segmentation path exists
                segmentationPath=optInp.Path;
                comPath=fileparts(obj.ComponentPath);
                segmentationPath=fullfile(comPath,segmentationPath); %create full path
            else
                segmentationPath=uigetdir([],'Please select Freesurfer Segmentation');
                if(isempty(segmentationPath))
                    error('No path selected!');
                end
            end
            T=obj.CreateOutput(obj.TIdentifier);
            T.T=xfm_read(fullfile(segmentationPath,'mri','transforms','talairach.xfm'));
            
        end
    end
end

