classdef GenerateThomasSegmentation < AComponent
    % GenerateThomasSegmentation Run Thomas thalamic segmentation within VERA
    % MRIIdentifier can be T1 MRI or FGATIR

    properties
        MRIIdentifier     % Input MRI Data Identifier
        LeftVolumeIdentifier
        RightVolumeIdentifier
        SegmentationPathIdentifier
    end

    methods
        function obj = GenerateThomasSegmentation()
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

            obj.RequestDependency('Docker', 'file');
        end

        function Initialize(obj)
            
            dockerexe = obj.GetDependency('Docker');
            if ispc
                dockerpath = fileparts(dockerexe);
                addpath(dockerpath);
            else
                addpath(dockerexe);
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

        function [Lvolout, Rvolout, pathInfo] = Process(obj, mri)
            segmentationFolder                 = obj.ComponentPath;
            segmentationPath                   = fullfile(segmentationFolder,'Segmentation');
            mri_path                           = GetFullPath(mri.Path);
            [imageFolder, imageName, imageExt] = fileparts(mri_path);
            imageName                          = [imageName, imageExt];
            DockerPath                         = obj.GetDependency('Docker');

            if ispc
                subsyspath    = obj.GetDependency('UbuntuSubsystemPath');
                w_imageFolder = convertToUbuntuSubsystemPath(imageFolder, subsyspath);
            end

            if ispc
                if strcmp(obj.MRIIdentifier,'MRI')
                    % PC T1
                    docker_script = sprintf([ 'time docker run --rm --name sthomas ' ...
                                                '-v "%s":/data ' ...
                                                '-w /data ' ...
                                                'anagrammarian/sthomas hipsthomas.sh -v -t1 ' ...
                                                '-i /data/%s' ], ...
                                                w_imageFolder, imageName);
                elseif strcmp(obj.MRIIdentifier,'FGATIR')
                    % PC WMn/FGATIR
                    docker_script = sprintf([ 'time docker run --rm --name sthomas ' ...
                                                '-v "%s":/data ' ...
                                                '-w /data ' ...
                                                'anagrammarian/sthomas hipsthomas.sh -v ' ...
                                                '-i /data/%s' ], ...
                                                w_imageFolder, imageName);
                end
            else
                if strcmp(obj.MRIIdentifier,'MRI')
                    % Mac T1
                    docker_script = sprintf([ 'time docker run -it --rm --name sthomas ' ...
                                                '-v "%s":/data ' ...
                                                '-w /data ' ...
                                                'anagrammarian/sthomas hipsthomas.sh -v -t1 ' ...
                                                '-i /data/%s' ], ...
                                                imageFolder, imageName);

                elseif strcmp(obj.MRIIdentifier,'FGATIR')
                    % Mac WMn/FGATIR
                    docker_script = sprintf([ 'time docker run -it --rm --name sthomas ' ...
                                                '-v "%s":/data ' ...
                                                '-w /data ' ...
                                                'anagrammarian/sthomas hipsthomas.sh -v ' ...
                                                '-i /data/%s' ], ...
                                                imageFolder, imageName);
                end
            end

            if(~exist(segmentationPath,'dir') ||...
                    (exist(segmentationPath,'dir') && strcmp(questdlg('Found an Existing Thomas Segmentation Folder! Do you want to rerun the Segmentation?','Rerun Segmentation?','Yes','No','No'),'Yes')))
                disp('Running Thomas segmentation, this might take a few hours, get a coffee...');
                if(exist(segmentationPath, 'dir'))
                    rmdir(segmentationPath, 's');
                    mkdir(segmentationPath);
                else
                    mkdir(segmentationPath);
                end

                % what happens if docker isn't installed?
                % Run docker from terminal instead of app?
                if ispc
                    system(['"', DockerPath, '"']);
                else
                    system('open -a docker');
                end

                % Might need to wait for docker to open?
                pause(10)

                % Check docker image
                % This will check if usr/local/bin is on the system path
                dockerImage = 'anagrammarian/sthomas:latest';
                checkDocker(dockerImage);

                % run docker
                if ispc
                    [status, cmdout] = systemWSL(docker_script, '-echo');
                else
                    [status, cmdout] = system(docker_script, '-echo');
                end

                if status
                    rmdir(segmentationPath, 's');
                    errorMsg = sprintf(['Error! Thomas segmentation not generated.\n\n', cmdout]);
                    error(errorMsg);
                end

                % Move Thomas files to correct location
                movefile(fullfile(imageFolder, 'left'),                     fullfile(segmentationPath, 'left'))
                movefile(fullfile(imageFolder, 'right'),                    fullfile(segmentationPath, 'right'))
                movefile(fullfile(imageFolder, 'sthomas_LR_labels.nii.gz'), fullfile(segmentationPath, 'sthomas_LR_labels.nii.gz'))
                movefile(fullfile(imageFolder, 'sthomas_LR_labels.png'),    fullfile(segmentationPath, 'sthomas_LR_labels.png'))
            end

            % Left
            Lvolout           = obj.CreateOutput(obj.LeftVolumeIdentifier);
            Lnii_path         = fullfile(segmentationPath, 'left', 'thomasfull_L.nii.gz');
            Lnii_path_reslice = fullfile(segmentationPath, 'left', 'thomasfull_L_reslice.nii.gz');

            reslice_nii(Lnii_path, Lnii_path_reslice); % needed to reslice because the tolerance of 0 is too low for FGATIR image

            Lvolout.LoadFromFile(Lnii_path_reslice);

            % Right
            Rvolout           = obj.CreateOutput(obj.RightVolumeIdentifier);
            Rnii_path         = fullfile(segmentationPath, 'right', 'thomasfull_R.nii.gz');
            Rnii_path_reslice = fullfile(segmentationPath, 'right', 'thomasfull_R_reslice.nii.gz');

            reslice_nii(Rnii_path, Rnii_path_reslice);

            Rvolout.LoadFromFile(Rnii_path_reslice);

            % Path
            pathInfo      = obj.CreateOutput(obj.SegmentationPathIdentifier);
            pathInfo.Path = segmentationPath;

        end
    end
end

