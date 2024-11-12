classdef DeFace < AComponent
    % The DeFace component applies the Freesurfer defacing algorithm
    properties
        Identifier
    end

    methods
        function obj = DeFace()
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
        end

        function vol = Process(obj,vol)

            freesurferPath = obj.GetDependency('Freesurfer');

            pathtoTalMixSkull = strcat(freesurferPath, '/average/talairach_mixed_with_skull.gca');
            pathtoFace        = strcat(freesurferPath, '/average/face.gca');
            % outputPath        = fullfile(obj.ComponentPath,'data',[obj.Identifier,'.nii']);

            deface_command = ['mri_deface ', vol.Path, ' ', pathtoTalMixSkull, ' ', pathtoFace, ' ', vol.Path];

            syscall = ['export FREESURFER_HOME=', freesurferPath, ' && source ', freesurferPath, '/SetUpFreeSurfer.sh && ', deface_command];

            % EXECUTE call
            stat = system(syscall);

            if stat ~=0
                disp('Problem with defacing')
            end

            % This is so the defaced volume is used in further VERA processing
            vol.LoadFromFile(vol.Path);

        end
    end
end

