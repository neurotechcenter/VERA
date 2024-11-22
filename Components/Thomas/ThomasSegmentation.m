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
            obj.RequestDependency('Docker','file');
        end

        function Initialize(obj)
            thomaspath = obj.GetDependency('Thomas');
            addpath(thomaspath);
            
            dockerpath = obj.GetDependency('Docker');
            if ispc
                addpath(['"' dockerpath '"']);
            else
                addpath(dockerpath);
            end
            
            if(ispc)
               obj.GetDependency('UbuntuSubsystemPath');
               if(system('WHERE bash >nul 2>nul echo %ERRORLEVEL%') == 1)
                   error('If you want to use THOMAS components on windows, the Windows 10 Ubuntu subsystem is required!');
               else
                   disp('Found ubuntu subsystem on Windows 10!');
               end
            end
        end

        function [Lvolout,Rvolout,pathInfo] = Process(obj,mri)
            segmentationFolder                 = obj.ComponentPath;
            mri_path                           = GetFullPath(mri.Path);
            [imageFolder, imageName, imageExt] = fileparts(mri_path);
            imageName                          = [imageName, imageExt];
            ThomasPath                         = obj.GetDependency('Thomas');
            DockerPath                         = obj.GetDependency('Docker');
            
            if ispc
                subsyspath  = obj.GetDependency('UbuntuSubsystemPath');
                w_imageFolder = convertToUbuntuSubsystemPath(imageFolder, subsyspath);
            end

            if ispc
                if strcmp(obj.MRIIdentifier,'MRI')
                    % T1
                    docker_script = ['docker run -v ',w_imageFolder,':',w_imageFolder,' -w ',w_imageFolder,...
                        ' --user $(id -u):$(id -g) --rm -t anagrammarian/thomasmerged bash -c "hipsthomas_csh -i ',imageName,' -t1 -big"'];
                elseif strcmp(obj.MRIIdentifier,'FGATIR')
                    % WMn/FGATIR
                    docker_script = ['docker run -v ',w_imageFolder,':',w_imageFolder,' -w ',w_imageFolder,...
                        ' --user $(id -u):$(id -g) --rm -t anagrammarian/thomasmerged bash -c "hipsthomas_csh -i ',imageName,'"'];
                end
            else
                if strcmp(obj.MRIIdentifier,'MRI')
                    % T1
                    docker_script = ['docker run -v ',imageFolder,':',imageFolder,' -w ',imageFolder,...
                        ' --user $(id -u):$(id -g) --rm -t anagrammarian/thomasmerged bash -c "hipsthomas_csh -i ',imageName,' -t1 -big"'];
                elseif strcmp(obj.MRIIdentifier,'FGATIR')
                    % WMn/FGATIR
                    docker_script = ['docker run -v ',imageFolder,':',imageFolder,' -w ',imageFolder,...
                        ' --user $(id -u):$(id -g) --rm -t anagrammarian/thomasmerged bash -c "hipsthomas_csh -i ',imageName,'"'];
                end
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
                if ispc
                    system(['"',DockerPath,'"']);
                else
                    system('open -a docker');
                end

                % Might need to wait for docker to open?
                pause(10)

                % Check docker image
                % This will check if usr/local/bin is on the system path
                dockerImage = 'anagrammarian/thomasmerged:latest';
                checkDocker(dockerImage);

                % run docker
                if ispc
                    systemWSL(docker_script,'-echo');
                else
                    system(docker_script,'-echo');
                end

                % Move Thomas files to correct location
                movefile(fullfile(imageFolder,'left'),  fullfile(segmentationPath,'left'))
                movefile(fullfile(imageFolder,'right'), fullfile(segmentationPath,'right'))
                movefile(fullfile(imageFolder,'temp'),  fullfile(segmentationPath,'temp'))
                movefile(fullfile(imageFolder,'tempr'), fullfile(segmentationPath,'tempr'))

            end

            Lvolout          = obj.CreateOutput(obj.LeftVolumeIdentifier);
            nii_path         = fullfile(segmentationPath,'left','thomasfull.nii.gz');
            nii_path_reslice = fullfile(segmentationPath,'left','thomasfull_reslice.nii.gz');

            reslice_nii(nii_path,nii_path_reslice); % needed to reslice because the tolerance of 0 is too low for FGATIR image

            Lvolout.LoadFromFile(nii_path_reslice);


            Rvolout          = obj.CreateOutput(obj.RightVolumeIdentifier);
            nii_path         = fullfile(segmentationPath,'right','thomasrfull.nii.gz');
            nii_path_reslice = fullfile(segmentationPath,'right','thomasfull_reslice.nii.gz');

            reslice_nii(nii_path,nii_path_reslice);

            Rvolout.LoadFromFile(nii_path_reslice);


            pathInfo      = obj.CreateOutput(obj.SegmentationPathIdentifier);
            pathInfo.Path = segmentationPath;

        end
    end
end

