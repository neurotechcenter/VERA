classdef ImportROSFile < AComponent
    %ImportROSFile Import trajectory planning information from ROSA robot.
    properties
        TrajectoryIdentifier
        ElectrodeDefinitionIdentifier
        ElectrodeDefinition
        VolumeIdentifier
        History
        InputFilepath char
    end

    methods
        function obj = ImportROSFile()
            obj.TrajectoryIdentifier          = 'Trajectory';
            obj.ElectrodeDefinitionIdentifier = 'ElectrodeDefinition';
            obj.ElectrodeDefinition           = {};
            obj.VolumeIdentifier              = 'ROSAVolume';
            obj.History                       = {};
            obj.InputFilepath                 = '';
        end

        function Publish(obj)
            obj.AddOptionalInput(obj.ElectrodeDefinitionIdentifier, 'ElectrodeDefinition',true);
            obj.AddOutput(obj.TrajectoryIdentifier,                 'ElectrodeLocation');
            obj.AddOutput(obj.ElectrodeDefinitionIdentifier,        'ElectrodeDefinition');
            obj.AddOutput(obj.VolumeIdentifier,                     'Volume');

            obj.ignoreList{end+1} = 'History';
        end

        function Initialize(obj)
        end

        function [trajectories,definitions,volume]=Process(obj,optInp)
            if(nargin > 1) 
                obj.ElectrodeDefinition = optInp;
            else
                obj.ElectrodeDefinition = [];
            end

            if ~isempty(obj.InputFilepath)
                % working directory is VERA project
                if isAbsolutePath(obj.InputFilepath)
                    d = dir(fullfile(obj.InputFilepath,'*.ros'));
                else
                    d = dir(fullfile(obj.ComponentPath,'..',obj.InputFilepath,'*.ros'));
                end

                % remove hidden files
                rem = [];
                for i = 1:length(d)
                    if strcmp(d(i).name(1),'.')
                        rem = [rem, i];
                    end
                end
                d(rem) = [];

                % Open a file load dialog if you can't find the path
                if ~isempty(d)
                    file = d.name;
                    path = d.folder;
                    clear d rem
                else
                    [file,path] = uigetfile('*.ros',['Please select the .ros ROSA file']);
                end
            else
                [file,path] = uigetfile('*.ros',['Please select the .ros ROSA file']);
            end

            rosa_parsed  = parseROSAfile(fullfile(path,file));

            if ~isempty(obj.ElectrodeDefinition)
                definitions = obj.ElectrodeDefinition;
            else
                definitions = obj.CreateOutput(obj.ElectrodeDefinitionIdentifier);
            end
            trajectories = obj.CreateOutput(obj.TrajectoryIdentifier);
            volume       = obj.CreateOutput(obj.VolumeIdentifier);


            [~,~,~,rot2ras] = affine_rotation(deg2rad(0),deg2rad(0),deg2rad(180));
            outpath = obj.GetDependency('TempPath');
            ras_projected.displays = {};
            for i=1:length(rosa_parsed.displays)
                displays = rosa_parsed.displays(i);
                vol_path = dir(fullfile(path,[displays.volume '.img']));
                if(~isempty(vol_path) && exist(fullfile(vol_path.folder,vol_path.name),'file'))
                    try
                        % Converting ANALYZE to nifti ----
                        info   = load_nii(fullfile(vol_path.folder,vol_path.name));
                        [~,nm] = fileparts(vol_path.name);
                        save_nii(info, fullfile(outpath,['orig_' nm '.nii']));
                        % Moving nifti 0/0/0 to center of image to match ROSA coordinate
                        % space
                        info = load_nii(fullfile(outpath,['orig_' nm '.nii']));
                        
                        % old
                        img_size = size(info.img)/2;
                        info.hdr.hist.srow_x(4) = -info.hdr.dime.pixdim(2)*img_size(1);
                        info.hdr.hist.srow_y(4) = -info.hdr.dime.pixdim(3)*img_size(2);
                        info.hdr.hist.srow_z(4) = -info.hdr.dime.pixdim(4)*img_size(3);

                        % new - accounts for zero indexing in ROSA coordinates
                        % info.hdr.hist.srow_x(4) = -info.hdr.dime.pixdim(2)*(img_size(1)-1);
                        % info.hdr.hist.srow_y(4) = -info.hdr.dime.pixdim(3)*(img_size(2)-1);
                        % info.hdr.hist.srow_z(4) = -info.hdr.dime.pixdim(4)*(img_size(3)-1);

                        info.hdr.hist.sform_code = 1; %set sform 1 so that changes are applied later on
                        %image is not yet in RAS space, so we will delete the orig_ later
                        %to avoid confusion
                        save_nii(info, fullfile(outpath,['orig_' nm '.nii']));
                        %load nii without the resampling restrictions of the nifti package
                        info = load_untouch_nii(fullfile(outpath,['orig_' nm '.nii']));
                        %calculate the correct transofmration matrix that correspond to the
                        %ROSA coregistration and transform to RAS
                        M     = [info.hdr.hist.srow_x;info.hdr.hist.srow_y;info.hdr.hist.srow_z; 0 0 0 1];
                        t_out = rot2ras*displays.ATForm*M;
                        info.hdr.hist.srow_x = t_out(1,:);
                        info.hdr.hist.srow_y = t_out(2,:);
                        info.hdr.hist.srow_z = t_out(3,:);
                        info.hdr.hist.intent_name='ROSATONI';

                        % save the ROSA coregistered and RAS transformed nifti
                        save_untouch_nii(info, fullfile(outpath,[nm '.nii']));
                        ras_projected.displays{end+1} = fullfile(outpath,[nm '.nii']);
                        delete(fullfile(outpath,['orig_' nm '.nii'])); %lets delete this file since its coordinate system might confuse someone
                    catch
                        warning(['Couldnt load ' fullfile(vol_path.folder,vol_path.name)]);
                    end
                end
            end

            if(isempty(ras_projected.displays))
                error('ROSA files seem to be missing, no imaging data available to create reference frame for trajectories');
            end
            %% save trajectories in RAS coordinate system
            % All trajectories are in the coregistration space, so all we need to do is
            % transform the trajectories into RAS space by applying rot2ras

            if isempty(obj.ElectrodeDefinition)
                for ii = 1:length(rosa_parsed.Trajectories)
                    definitions.Definition(ii).Name   = rosa_parsed.Trajectories(ii).name;
                    definitions.Definition(ii).Type   = 'Depth';
                    definitions.Definition(ii).Volume = 30;
                end
            end

            for ii = 1:length(rosa_parsed.Trajectories)
                traj_tosave = [rosa_parsed.Trajectories(ii).start 1;rosa_parsed.Trajectories(ii).end 1];

                % added by James to try to account for zero indexing
                % traj_tosave(:,1:3) = traj_tosave(:,1:3)-1;

                traj_tosave = (rot2ras*traj_tosave')';
                traj_tosave = traj_tosave(:,1:3);

                % used to be flipped - not sure why. This should set the
                % inner most point on the trajectory as index 1
                if(pdist([rosa_parsed.Trajectories(ii).start; 0 0 0]) < pdist([rosa_parsed.Trajectories(ii).end; 0 0 0]))
                    ras_projected.Trajectories(ii).start = traj_tosave(1,:);
                    ras_projected.Trajectories(ii).end   = traj_tosave(2,:);
                else
                    ras_projected.Trajectories(ii).start = traj_tosave(2,:);
                    ras_projected.Trajectories(ii).end   = traj_tosave(1,:);
                end

                % definitions.Definition(ii).Type   = 'Depth';
                % definitions.Definition(ii).Volume = 30;
                % 
                % definitions.Definition(ii).Name          = rosa_parsed.Trajectories(ii).name;
                trajectories.DefinitionIdentifier(end+1) = ii;
                trajectories.Location(end+1,:)           = ras_projected.Trajectories(ii).start;
                trajectories.DefinitionIdentifier(end+1) = ii;
                trajectories.Location(end+1,:)           = ras_projected.Trajectories(ii).end;
                % [definitions.Definition(ii).NElectrodes,definitions.Definition(ii).Spacing]=obj.calculateNumContacts([ras_projected.Trajectories(ii).start; ras_projected.Trajectories(ii).end]);
            end

            volume.LoadFromFile(ras_projected.displays{1});
            if isempty(obj.ElectrodeDefinition)
                obj.ElectrodeDefinition = definitions.Definition;
                h = figure;
                elView = ElectrodeDefinitionView('Parent',h);
                elView.SetComponent(obj);
                uiwait(h);
                hist = obj.History;
                definitions.Definition = obj.ElectrodeDefinition;
                for i = 1:length(hist)
                    cmd = hist{i}{1};
                    val = hist{i}{2};
                    if(strcmp(cmd,'Add'))
                    elseif(strcmp(cmd,'Delete'))
                        for i_traj = 1:length(val)
                            trajectories.Location(trajectories.DefinitionIdentifier == val(i),:)           = [];
                            trajectories.DefinitionIdentifier(trajectories.DefinitionIdentifier == val(i)) = [];
                            trajectories.DefinitionIdentifier(trajectories.DefinitionIdentifier > val(i))  = trajectories.DefinitionIdentifier(trajectories.DefinitionIdentifier > val(i)) -1;
                        end
                    elseif(strcmp(cmd,'Update'))
                    else
                        error('unknown ElectrodeDefinitionView history command');
                    end
                end
            end

            if(~isempty(obj.ElectrodeDefinition))
                field = fieldnames(obj.ElectrodeDefinition);
                for i = 1:length(obj.ElectrodeDefinition)
                    for f = 1:length(field)
                        if(isempty(obj.ElectrodeDefinition(i).(field{f})))
                            error([field{f} ' is missing values!']);
                        end
                    end
                end
            end
        end
%
%         function [numC,spacing]=calculateNumContacts(obj,traj)
%             shankLength=pdist(traj)-3;
%             spacing = 3.5; % mm
%             if(and(shankLength-3>=0,shankLength-3<=0))
%                 numC = 0;
%             elseif(and(shankLength-3>=1,shankLength-3<=12.5))
%                 numC = 4;
%             elseif(and(shankLength-3>=12.6,shankLength-3<=19.5))
%                 numC = 6;
%             elseif(and(shankLength-3>=19.6,shankLength-3<=26.5))
%                 numC = 8;
%             elseif(and(shankLength-3>=26.6,shankLength-3<=33.5))
%                 numC = 10;
%             elseif(and(shankLength-3>=33.6,shankLength-3<=40.5))
%                 numC = 12;
%             elseif(and(shankLength-3>=40.6,shankLength-3<=47.5))
%                 numC = 14;
%             elseif(and(shankLength-3>=47.6,shankLength-3<=54.5))
%                 numC = 16;
%             elseif(and(shankLength-3>=54.6,shankLength-3<=61.5))
%                 numC = 16;
%                 spacing = 3.97; % mm
%             elseif shankLength-3>=61.6
%                 numC = 16;
%                 spacing = 4.43; % mm
%             else
%                 error('unexpected trajectory length');
%             end
%
%         end

    end
end
