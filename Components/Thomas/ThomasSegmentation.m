classdef ThomasSegmentation < AComponent
    % ThomasSegmentation Run Thomas segmentation within VERA

    properties
        MRIIdentifier     % Input MRI Data Identifier
        LeftVolumeIdentifier
        RightVolumeIdentifier
        SegmentationPathIdentifier
    end

    methods
        function obj = ThomasSegmentation()
            obj.MRIIdentifier              = 'MRI';
            obj.LeftVolumeIdentifier       = 'LThomasVolume';
            obj.RightVolumeIdentifier      = 'RThomasVolume';
            obj.SegmentationPathIdentifier = 'ThomasSegmentationPath';
        end

        function Publish(obj)
            obj.AddInput(obj.MRIIdentifier,               'Volume');
            obj.AddOutput(obj.LeftVolumeIdentifier,       'Volume');
            obj.AddOutput(obj.RightVolumeIdentifier,      'Volume');
            obj.AddOutput(obj.SegmentationPathIdentifier, 'PathInformation');
            obj.RequestDependency('Thomas','folder');
            % obj.RequestDependency('Docker','file');
        end

        function Initialize(obj)
            path = obj.GetDependency('Thomas');
            addpath(path);
            
            % path = obj.GetDependency('Docker');
            % addpath(path);
        end

        function [Lvolout,Rvolout,pathInfo] = Process(obj,mri)
            segmentationFolder                 = obj.ComponentPath;
            mri_path                           = GetFullPath(mri.Path);
            [imageFolder, imageName, imageExt] = fileparts(mri_path);
            imageName                          = [imageName, imageExt];
            ThomasPath                         = obj.GetDependency('Thomas');
            % DockerPath                         = obj.GetDependency('Docker');

            if strcmp(obj.MRIIdentifier,'MRI')
                % T1
                docker_script = ['docker run -v ',imageFolder,':',imageFolder,' -w ',imageFolder,...
                    ' --user $(id -u):$(id -g) --rm -t anagrammarian/thomasmerged bash -c "hipsthomas_csh -i ',imageName,' -t1 -big"'];

            elseif strcmp(obj.MRIIdentifier,'FGATIR')
                % WMn/FGATIR
                docker_script = ['docker run -v ',imageFolder,':',imageFolder,' -w ',imageFolder,...
                    ' --user $(id -u):$(id -g) --rm -t anagrammarian/thomasmerged bash -c "hipsthomas_csh -i ',imageName,'"'];

            end
            
            segmentationPath = fullfile(segmentationFolder,'Segmentation');

            if(~exist(segmentationPath,'dir') ||...
                    (exist(segmentationPath,'dir') && strcmp(questdlg('Found an Existing Thomas Segmentation Folder! Do you want to rerun the Segmentation?','Rerun Segmentation?','Yes','No','No'),'Yes')))
                disp('Running Thomas segmentation, this might take a few hours, get a coffee...');
                if(exist(segmentationPath,'dir'))
                    rmdir(segmentationPath,'s');
                end

                % what happens if docker isn't installed?
                % Run docker from terminal instead of app?
                system('open -a docker')

                % Check docker image
                % This will check if usr/local/bin is on the system path
                dockerImage = 'anagrammarian/thomasmerged:latest';
                checkDocker(dockerImage);

                % run docker
                system(docker_script);

                % Move Thomas files to correct location
                movefile(fullfile(imageFolder,'left'),  fullfile(segmentationPath,'left'))
                movefile(fullfile(imageFolder,'right'), fullfile(segmentationPath,'right'))
                movefile(fullfile(imageFolder,'temp'),  fullfile(segmentationPath,'temp'))
                movefile(fullfile(imageFolder,'tempr'), fullfile(segmentationPath,'tempr'))

            end

            Lvolout = obj.CreateOutput(obj.LeftVolumeIdentifier);
            nii_path = fullfile(segmentationPath,'left','thomasfull.nii.gz');
            Lvolout.LoadFromFile(nii_path);

            Rvolout = obj.CreateOutput(obj.RightVolumeIdentifier);
            nii_path = fullfile(segmentationPath,'right','thomasrfull.nii.gz');
            Rvolout.LoadFromFile(nii_path);

            pathInfo      = obj.CreateOutput(obj.SegmentationPathIdentifier);
            pathInfo.Path = segmentationPath;

        end
    end
end

