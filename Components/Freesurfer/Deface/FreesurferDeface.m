classdef FreesurferDeface < AComponent
    % The FreesurferDeface component applies the Freesurfer defacing algorithm
    properties
        Identifier
    end

    methods
        function obj = FreesurferDeface()
            obj.Identifier  = 'MRI';
        end

        function Publish(obj)
            obj.AddInput(obj.Identifier,  'Volume');
            obj.AddOutput(obj.Identifier, 'Volume');

            % External dependencies
            obj.RequestDependency('Freesurfer','folder');
            if(ispc)
                obj.RequestDependency('UbuntuSubsystemPath','folder');
            end
        end

        function Initialize(obj)
            freesurferPath = obj.GetDependency('Freesurfer');
            addpath(freesurferPath);
            
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

        function vol = Process(obj,vol)

            freesurferPath = obj.GetDependency('Freesurfer');

            pathtoTalMixSkull = strcat(freesurferPath, '/average/talairach_mixed_with_skull.gca');
            pathtoFace        = strcat(freesurferPath, '/average/face.gca');

            deface_command = ['mri_deface ', vol.Path, ' ', pathtoTalMixSkull, ' ', pathtoFace, ' ', vol.Path];

            syscall = ['export FREESURFER_HOME=', freesurferPath, ' && source ', freesurferPath, '/SetUpFreeSurfer.sh && ', deface_command];

            % EXECUTE call
            if(ispc)
                subsyspath = obj.GetDependency('UbuntuSubsystemPath');

                w_syscall = convertToUbuntuSubsystemPath(syscall, subsyspath);

                systemWSL(w_syscall,'-echo');

            else
                stat = system(syscall,'-echo');
    
                if stat ~= 0
                    disp('Problem with defacing')
                end
            end

            % This is so the defaced volume is used in further VERA processing
            vol.LoadFromFile(vol.Path);

        end
    end
end
