classdef MayoReface < AComponent
    % The MayoReface component applies the mri_reface refacing algorithm.
    % Note that for Windows computers and intel macs, a docker container of
    %this project is available. There is no docker image available for arm
    %macs, so the dependencies (Matlab runtime R2022a (MCRv912), ANTs, and 
    %nifty_reg) will have to be installed individually
    properties
        Identifier
        ImType
    end

    methods
        function obj = MayoReface()
            obj.Identifier = 'MRI';
            obj.ImType     = 'T1';
        end

        function Publish(obj)
            obj.AddInput(obj.Identifier,  'Volume');
            obj.AddOutput(obj.Identifier, 'Volume');

            if ismac
                [~,result] = system('uname -v');
                is_arm_mac = any(strfind(result,'ARM64'));
            else
                is_arm_mac = false;
            end

            % External dependencies
            obj.RequestDependency('mri_reface', 'folder');

            if ispc
                obj.RequestDependency('Docker',              'file');
                obj.RequestDependency('UbuntuSubsystemPath', 'folder');
            elseif ismac && ~is_arm_mac % intel mac
                obj.RequestDependency('Docker', 'file');
            else
                % No Docker version available for ARM macs
                obj.RequestDependency('MCRv912',   'folder');
                obj.RequestDependency('ANT',       'folder');
                obj.RequestDependency('nifty_reg', 'folder');
            end

        end

        function Initialize(obj)
            mri_refacePath = obj.GetDependency('mri_reface');
            addpath(mri_refacePath);

            if ismac
                [~,result] = system('uname -v');
                is_arm_mac = any(strfind(result,'ARM64'));
            else
                is_arm_mac = false;
            end
            
            % if PC or intel mac, use Docker image
            if ispc
                dockerpath = obj.GetDependency('Docker');
                addpath(fileparts(dockerpath));

                obj.GetDependency('UbuntuSubsystemPath');
                if(system('WHERE bash >nul 2>nul echo %ERRORLEVEL%') == 1)
                    error('If you want to use mri_reface on windows, the Windows 10 Ubuntu subsystem is required!');
                else
                    disp('Found ubuntu subsystem on Windows 10!');
                end

            elseif ismac && ~is_arm_mac
                dockerpath = obj.GetDependency('Docker');
                addpath(fileparts(dockerpath));
            end
            
        end

        function vol = Process(obj,vol)
            
            waitbar_parts = 4;
            f = waitbar(0,'Calculating Refaced Volume');

            mri_refacePath = obj.GetDependency('mri_reface');
            outputpath     = fullfile(obj.ComponentPath,'Data');

            if contains(outputpath,' ')
                error(['Error! This component does not work if the project path contains any spaces. ',...
                    'Remove any spaces from the project path and try again.'])
            end

            if ismac
                [~,result] = system('uname -v');
                is_arm_mac = any(strfind(result,'ARM64'));
            else
                is_arm_mac = false;
            end
            
            %% Docker setup
            if ispc
                DockerPath = obj.GetDependency('Docker');
                [~,TL]     = system('tasklist');
                IsRunning  = contains(TL, 'Docker Desktop.exe');
                if ~IsRunning
                    fprintf('\nStarting Docker\n');
                    system(['"',DockerPath,'"']);
                else
                    fprintf('\nDocker already running\n');
                end

            elseif ismac && ~is_arm_mac
                if ~contains(getenv('PATH'),'/usr/local/bin')
                    fprintf('\nadding /usr/local/bin to path\n')
                    setenv('PATH', [getenv('PATH') ':/usr/local/bin']);
                end
                [~,TL]    = system('ps aux');
                IsRunning = contains(TL, 'Docker');
                if ~IsRunning
                    fprintf('\nStarting Docker\n')
                    system('open -a docker');
                else
                    fprintf('\nDocker already running\n');
                end

            end

            if ispc || ~is_arm_mac
                % Might need to wait for docker to open?
                pause(20)

                % Check docker image
                dockerImageName = 'mri_reface';
                dockerImage     = fullfile(mri_refacePath,'mri_reface_docker_image');
                [~, id]         = system(['docker images -q ' dockerImageName]);
                if ~isempty(id)
                    fprintf('docker image found: %s\n',   dockerImageName);
                else
                    fprintf('Loading docker image: %s\n', dockerImage);
                    system(['docker load < ' dockerImage]);
                end
            end

            waitbar(1/waitbar_parts,f);
            

            %% EXECUTE call
            if ispc
                mri_reface_script = fullfile(fileparts(mfilename('fullpath')), 'scripts', 'run_mri_reface_docker.sh');

                subsyspath = obj.GetDependency('UbuntuSubsystemPath');

                w_volpath           = convertToUbuntuSubsystemPath(vol.Path,          subsyspath);
                w_outputpath        = convertToUbuntuSubsystemPath(outputpath,        subsyspath);
                w_mri_reface_script = convertToUbuntuSubsystemPath(mri_reface_script, subsyspath);
                
                systemWSL(['chmod +x ''' w_mri_reface_script ''''], '-echo');

                waitbar(2/waitbar_parts,f);
                
                shellcmd = ['' w_mri_reface_script ' ' w_volpath ' ' w_outputpath...
                                ' -imType ' obj.ImType ' -saveQCRenders 0' ''];
                            
                [stat,cmdout] = systemWSL(shellcmd,'-echo');
                
            elseif ismac && ~is_arm_mac
                mri_reface_script = fullfile(fileparts(mfilename('fullpath')), 'scripts', 'run_mri_reface_docker.sh');

                system(['chmod +x ''' mri_reface_script ''''], '-echo');

                waitbar(2/waitbar_parts,f);
                
                shellcmd = ['' mri_reface_script ' ' vol.Path ' ' outputpath...
                                ' -imType ' obj.ImType ' -saveQCRenders 0' ''];
                
                [stat,cmdout] = system(shellcmd,'-echo');
                
            else
                mri_reface_script = fullfile(fileparts(mfilename('fullpath')), 'scripts', 'run_mri_reface_ARM_Mac.sh');

                system(['chmod +x ''' mri_reface_script ''''], '-echo');

                waitbar(2/waitbar_parts,f);
                
                MCRv912path   = obj.GetDependency('MCRv912');
                ANTpath       = obj.GetDependency('ANT');
                nifty_regpath = obj.GetDependency('nifty_reg');

                shellcmd = ['' mri_reface_script ' ' vol.Path ' ' outputpath ' '...
                                mri_refacePath ' ' MCRv912path ' ' ANTpath ' ' nifty_regpath...
                                ' -imType ' obj.ImType ' -saveQCRenders 0' ''];

                [stat,cmdout] = system(shellcmd,'-echo');
            end

            waitbar(3/waitbar_parts,f);
            
            if stat ~= 0
                error(['Refacing was not completed. Check that dependencies are properly installed and configured in the settings.\n', cmdout])
            else
                % Replace the original volume file so there is no identified
                % image still stored in the VERA project folder
                outputfile = fullfile(outputpath,[obj.Identifier,'_deFaced.nii']);

                if ~exist(outputfile,'file')
                    error('Refaced output file was not created. Check that dependencies are properly installed and configured in the settings.\n');
                end
                
                filelist = dir(fullfile(obj.ComponentPath,'..','**',['*',obj.Identifier,'.nii']));
                
                for i = 1:length(filelist)
                    copyfile(outputfile,fullfile(filelist(i).folder,filelist(i).name));
                end
                
                % This is so the defaced volume is used in further VERA processing
                vol.LoadFromFile(outputfile);
                
                % delete output files so they cannot be used to undo the re-facing
                delete(outputfile);
                delete(fullfile(outputpath, [obj.Identifier, '_to_MCALT_FaceTemplate_Affine.txt']));
                delete(fullfile(outputpath, [obj.Identifier, '_to_MCALT_FaceTemplate_InverseWarp.nii']));
                delete(fullfile(outputpath, [obj.Identifier, '_to_MCALT_FaceTemplate_Warp.nii']));
            end

            waitbar(1,f);
            close(f);
        end
    end
end
