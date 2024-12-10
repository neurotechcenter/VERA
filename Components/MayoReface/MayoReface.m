classdef MayoReface < AComponent
    % The FreesurferDeface component applies the Freesurfer defacing algorithm
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

            % External dependencies
            obj.RequestDependency('mri_reface', 'folder');
            obj.RequestDependency('Docker',     'file');
            if(ispc)
                obj.RequestDependency('UbuntuSubsystemPath', 'folder');
            end
        end

        function Initialize(obj)
            mri_refacePath = obj.GetDependency('mri_reface');
            addpath(mri_refacePath);
            
            dockerpath = obj.GetDependency('Docker');
            if ispc
                addpath(fileparts(dockerpath));
            else
                addpath(dockerpath);
            end
            
            if(ispc)
                obj.GetDependency('UbuntuSubsystemPath');
                if(system('WHERE bash >nul 2>nul echo %ERRORLEVEL%') == 1)
                    error('If you want to use mri_reface on windows, the Windows 10 Ubuntu subsystem is required!');
                else
                    disp('Found ubuntu subsystem on Windows 10!');
                end
            end
        end

        function vol = Process(obj,vol)

            mri_refacePath = obj.GetDependency('mri_reface');
            DockerPath     = obj.GetDependency('Docker');
            
            % what happens if docker isn't installed?
            % Run docker from terminal instead of app?
            if ispc
                [~,TL]    = system('tasklist');
                IsRunning = contains(TL, 'Docker Desktop.exe');
                if ~IsRunning
                    fprintf('Starting Docker\n');
                    system(['"',DockerPath,'"']);
                else
                    fprintf('Docker already running\n');
                end
            else
                if ~contains(getenv('PATH'),'/usr/local/bin')
                    fprintf('adding /usr/local/bin to path\n')
                    setenv('PATH', [getenv('PATH') ':/usr/local/bin']);
                end
                [~,TL]    = system('ps aux');
                IsRunning = contains(TL, 'Docker');
                if ~IsRunning
                    fprintf('Starting Docker\n')
                    system('open -a docker');
                end
            end

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

            mri_reface_script = fullfile(fileparts(mfilename('fullpath')), 'scripts', 'run_mri_reface_docker.sh');
            outputpath        = fullfile(obj.ComponentPath,'Data');

            % EXECUTE call
            if(ispc)
                subsyspath = obj.GetDependency('UbuntuSubsystemPath');

                w_volpath           = convertToUbuntuSubsystemPath(vol.Path,          subsyspath);
                w_outputpath        = convertToUbuntuSubsystemPath(outputpath,        subsyspath);
                w_mri_reface_script = convertToUbuntuSubsystemPath(mri_reface_script, subsyspath);
                
                systemWSL(['chmod +x ''' w_mri_reface_script ''''], '-echo');
                
                shellcmd = ['' w_mri_reface_script ' ' w_volpath ' ' w_outputpath...
                                ' -imType ' obj.ImType ' -saveQCRenders 0' ''];
                            
                stat = systemWSL(shellcmd,'-echo');

                
            else
                systemWSL(['chmod +x ''' mri_reface_script ''''], '-echo');
                
                shellcmd = ['' mri_reface_script ' ' vol.Path ' ' outputpath...
                                ' -imType ' obj.ImType ' -saveQCRenders 0' ''];
                
                stat = systemWSL(shellcmd,'-echo');
            end
            
            if stat ~= 0
                disp('Problem with refacing')
            end
            
            % Replace the original volume file so there is no identified
            % image still stored in the VERA project folder
            outputfile = fullfile(outputpath,[obj.Identifier,'_deFaced.nii']);
            
            filelist = dir(fullfile(obj.ComponentPath,'..','**',['*',obj.Identifier,'.nii']));
            
            % copyfile(outputfile,vol.Path);
            for i = 1:length(filelist)
                copyfile(outputfile,fullfile(filelist(i).folder,filelist(i).name));
            end
            
            % This is so the defaced volume is used in further VERA processing
            vol.LoadFromFile(outputfile);
            
            delete(outputfile);

        end
    end
end
