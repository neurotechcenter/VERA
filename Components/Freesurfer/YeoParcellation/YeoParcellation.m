classdef YeoParcellation < AComponent
    %This component generates the Yeo parcellation in the segmentation
    %folder found on the segmentation path
    properties
        SegmentationPathIdentifier
    end

    methods
        function obj = YeoParcellation()
            obj.SegmentationPathIdentifier = 'SegmentationPath';
        end

        function Publish(obj)
            obj.AddInput(obj.SegmentationPathIdentifier,  'PathInformation');
            obj.AddOutput(obj.SegmentationPathIdentifier, 'PathInformation');

            % External dependencies
            obj.RequestDependency('Freesurfer','folder');
            if(ispc)
                obj.RequestDependency('UbuntuSubsystemPath','folder');
            end
        end

        function Initialize(obj)
            path = obj.GetDependency('Freesurfer');
            addpath(fullfile(path,'matlab'));

            if(ispc)
                obj.GetDependency('UbuntuSubsystemPath');
               if(system('WHERE bash >nul 2>nul echo %ERRORLEVEL%') == 1)
                   error('If you want to use Freesurfer components on windows, the Windows 10 Ubuntu subsystem is required!');
               else
                   disp('Found ubuntu subsystem on Windows 10!');
                   disp('This Component requires GUI Access to freeview, make sure you can run freeview from the Linux subsystem (requires Xserver installed on windows)');
               end
            end
        end

        function [pathInfo] = Process(obj,pathInfo)
            
            fsDir = obj.GetDependency('Freesurfer');

            componentFolder    = obj.ComponentPath;
            segmentationFolder = fullfile(componentFolder,'..',pathInfo.Path);

            createIndivYeoMapping(fsDir,segmentationFolder);

        end
    end
end

