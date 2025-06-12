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

            waitbar_parts = 3;
            f = waitbar(0,'Calculating Defaced Volume');

            freesurferPath = obj.GetDependency('Freesurfer');

            pathtoTalMixSkull = fullfile(freesurferPath, 'average', 'talairach_mixed_with_skull.gca');
            pathtoFace        = fullfile(freesurferPath, 'average', 'face.gca');
            mri_deface_script = fullfile(fileparts(fileparts(mfilename('fullpath'))),'/scripts/mri_deface.sh');

            % EXECUTE call
            if(ispc)
                subsyspath = obj.GetDependency('UbuntuSubsystemPath');

                w_pathtoTalMixSkull = convertToUbuntuSubsystemPath(pathtoTalMixSkull, subsyspath);
                w_pathtoFace        = convertToUbuntuSubsystemPath(pathtoFace,        subsyspath);
                w_freesurferPath    = convertToUbuntuSubsystemPath(freesurferPath,    subsyspath);
                w_volpath           = convertToUbuntuSubsystemPath(vol.Path,          subsyspath);
                w_mri_deface_script = convertToUbuntuSubsystemPath(mri_deface_script, subsyspath);

                systemWSL(['chmod +x ''' w_mri_deface_script ''''],'-echo');

                waitbar(1/waitbar_parts,f);
                
                shellcmd = ['''' w_mri_deface_script ''' ''' w_freesurferPath ''' ''' w_volpath ''' ''' ...
                w_pathtoTalMixSkull ''' ''' w_pathtoFace ''' ''' w_volpath ''''];
                
                stat = systemWSL(shellcmd,'-echo');
                
            else
                systemWSL(['chmod +x ''' mri_deface_script ''''],'-echo');

                waitbar(1/waitbar_parts,f);
                
                shellcmd = ['''' mri_deface_script ''' ''' freesurferPath ''' ''' vol.Path ''' ''' ...
                pathtoTalMixSkull ''' ''' pathtoFace ''' ''' vol.Path ''''];
                
                stat = systemWSL(shellcmd,'-echo');
            end

            waitbar(2/waitbar_parts,f);
            
            if stat ~= 0
                disp('Problem with defacing')
            end
            
            % Replace the original volume file so there is no identified
            % image still stored in the VERA project folder            
            filelist = dir(fullfile(obj.ComponentPath,'..','**',['*',obj.Identifier,'.nii']));
            
            for i = 1:length(filelist)
                if ~strcmp(vol.Path,fullfile(filelist(i).folder,filelist(i).name))
                    copyfile(vol.Path,fullfile(filelist(i).folder,filelist(i).name));
                end
            end
            
            % This is so the defaced volume is used in further VERA processing
            vol.LoadFromFile(vol.Path);

            waitbar(1,f);
            close(f);

        end
    end
end
