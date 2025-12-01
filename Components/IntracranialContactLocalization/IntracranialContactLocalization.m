classdef IntracranialContactLocalization < AComponent
    %IntracranialContactLocalization automated pipeline for estimating 
    %intracranial electrode location based on CT images and manufacture 
    %information of the electrode lead
    
    properties
        MRIIdentifier                       % Identifier for MRI
        CTIdentifier                        % Identifier for CT
        ElectrodeDefinitionIdentifier       % Identifier for ElectrodeDefinition Data
        ElectrodeLocationIdentifier         % Identifier for Electrode Locations
        TrajectoryIdentifier                % Identifier for ROSA trajectory
        SegmentationPathIdentifier          % Path to Freesurfer segmentation folder
        ICLocalizationResultsPathIdentifier % Path to results folder
        
    end
    
    methods
        function obj = IntracranialContactLocalization()
            obj.CTIdentifier                        = 'CT';
            obj.ElectrodeDefinitionIdentifier       = 'ElectrodeDefinition';
            obj.ElectrodeLocationIdentifier         = 'ElectrodeLocation';
            obj.TrajectoryIdentifier                = 'Trajectory';
            obj.SegmentationPathIdentifier          = 'SegmentationPath';
            obj.ICLocalizationResultsPathIdentifier = 'IntracranialContactLocalizationResultsPath';
        end
        
        function Publish(obj)
            obj.AddInput(obj.CTIdentifier,                         'Volume');
            obj.AddInput(obj.ElectrodeDefinitionIdentifier,        'ElectrodeDefinition');
            obj.AddInput(obj.TrajectoryIdentifier,                 'ElectrodeLocation');
            obj.AddInput(obj.SegmentationPathIdentifier,           'PathInformation');

            obj.AddOutput(obj.ElectrodeLocationIdentifier,         'ElectrodeLocation');
            obj.AddOutput(obj.ICLocalizationResultsPathIdentifier, 'PathInformation');

            obj.RequestDependency('Freesurfer', 'folder');
            % obj.RequestDependency('SPM12',      'folder');
            % obj.RequestDependency('BCI2000mex', 'folder');
            obj.RequestDependency('IntracranialContactLocalization', 'folder');

            if(ispc)
                obj.RequestDependency('UbuntuSubsystemPath', 'folder');
            end
        end
        
        function Initialize(obj)
            path = obj.GetDependency('Freesurfer');
            addpath(fullfile(path,'matlab'));
            addpath(fullfile(path,'fsfast','toolbox'));

            % path = obj.GetDependency('SPM12');
            % addpath(path);
            % 
            % path = obj.GetDependency('BCI2000mex');
            % addpath(genpath(path));

            path = obj.GetDependency('IntracranialContactLocalization');
            addpath(genpath(path));
        end
        
        function [out, result_path] = Process(obj,ct,def,traj,segpath)

            curr_dir               = obj.ComponentPath;
            fspath                 = obj.GetDependency('Freesurfer');
            freesurfer_matlab_path = fullfile(fspath,'matlab');
            freesurfer_fsfast_path = fullfile(fspath,'fsfast','toolbox');

            addpath(genpath(freesurfer_matlab_path));
            addpath(genpath(freesurfer_fsfast_path));

            % subject ID
            projectpath = fileparts(obj.ComponentPath);
            [~,subj_id] = fileparts(projectpath);

            % Path to brain mask
            bm_path = fullfile(projectpath,segpath.Path,'mri','brainmask.auto.mgz');

            % Check if any information is missing from the electrode definition
            hasEmpty = false;
            hasNaN   = false;
            fields   = fieldnames(def.Definition);
        
            for elec = 1:size(def.Definition,1)
                for f = 1:numel(fields)
                    val = def.Definition(elec).(fields{f});

                    % Check empty
                    if isempty(val)
                        hasEmpty = true;
                    end
        
                    % Check NaN
                    if isnan(val)
                        hasNaN = true;
                    end
                end
            end

            if hasEmpty || hasNaN
                error('Electrode Definition is missing information!');
            end

            clear hasEmpty hasNan fields elec f val

            % electrode manufacturer
            for i = 1:size(def.Definition,1)
                if strfind(def.Definition(i).Type,'DIXI')
                    electrode_manufacture{i} = 'DIXI';
                elseif strfind(def.Definition(i).Type,'Adtech')
                    electrode_manufacture{i} = 'Adtech';
                elseif strfind(def.Definition(i).Type,'PMT')
                    electrode_manufacture{i} = 'PMT';
                else
                    electrode_manufacture{i} = 'Unknown';
                end
            end


            % ct_volume_registered_to_mri
            im.ct_volume_registered_to_mri = MRIread(ct.Path);

            % coregistered_to_mri_trajectory
            im.coregistered_to_mri_trajectory.trajectory_id = {def.Definition(:).Name}';

            for i = 1:size(def.Definition,1)
                trajIDX = find(traj.DefinitionIdentifier == i);
                im.coregistered_to_mri_trajectory.trajectory(i).start = traj.Location(trajIDX(1),:);
                im.coregistered_to_mri_trajectory.trajectory(i).end   = traj.Location(trajIDX(2),:);
            end

            % electrode_info
            id              = {def.Definition(:).Name}';
            planning_length = [def.Definition.PlanningLength]';
            n_contact       = [def.Definition(:).NElectrodes]';
            for i = 1:length(n_contact)
                n_contact_str{i,1} = num2str(n_contact(i));
            end

            im.electrode_info = table(id, planning_length, n_contact, n_contact_str);

            % Run method
            [contact_tbl, shank_model_all] = gt_automatic_localize_electrode(im, subj_id, 'curr_dir', curr_dir,...
                'freesurfer_matlab_path',freesurfer_matlab_path, 'freesurfer_fsfast_path', freesurfer_fsfast_path, 'bm_path', bm_path,...
                'electrode_manufacture', electrode_manufacture);

            out = obj.CreateOutput(obj.ElectrodeLocationIdentifier);
            for i = 1:length(shank_model_all)
                out.Location             = [out.Location; shank_model_all(i).contact_centers];
                out.DefinitionIdentifier = [out.DefinitionIdentifier; i*ones(size(shank_model_all(i).contact_centers,1),1)];
            end

            result_path      = obj.CreateOutput(obj.ICLocalizationResultsPathIdentifier);
            result_path.Path = curr_dir;

        end
    end
end