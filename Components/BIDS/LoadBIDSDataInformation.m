classdef LoadBIDSDataInformation < AComponent
    %Loading MRI, ElectrodeLocations and ElectrodeDefinitions from
    %BIDS data
    
    properties
        MRIIdentifier
        ElectrodeDefinitionIdentifier
        ElectrodeLocationIdentifier
    end
    
    methods
        function obj = LoadBIDSDataInformation()
           obj.Name='Load BIDS Dataset';
           obj.MRIIdentifier='MRI';
           obj.ElectrodeDefinitionIdentifier='ElectrodeDefinition';
           obj.ElectrodeLocationIdentifier='ElectrodeLocation';
        end

        function obj= Publish(obj)
            obj.AddOutput(obj.MRIIdentifier,'Volume');
            obj.AddOutput(obj.ElectrodeDefinitionIdentifier,'ElectrodeDefinition');
            obj.AddOutput(obj.ElectrodeLocationIdentifier,'ElectrodeLocation');
            obj.RequestDependency('BIDS','folder');

        end
        
        function Initialize(obj)
            path=obj.GetDependency('BIDS');
            addpath(genpath(path));
        end

        function [mri,eldef,ellocs]=Process(obj)
            bids_sub_folder=uigetdir([],'Please select BIDS subject folder!');
             if isequal(bids_sub_folder,0)
                 error('BIDS folder selection aborted');
             end
            BIDS = bids.layout(fullfile(bids_sub_folder));
            available_subj=bids.query(BIDS, 'subjects');
            [idx,tf]=listdlg('PromptString','Select Subject','SelectionMode','single','ListString',available_subj);
            if(tf == 0)
                error('Subject selection aborted');
            end
            curr_subj=available_subj{idx};
            subj_channels=bids.query(BIDS, 'data','sub',curr_subj,'task','ccep','suffix','channels');
            subj_electrodes=bids.query(BIDS, 'data','sub',curr_subj,'suffix','electrodes');
            channelinfo=bids.util.tsvread(subj_channels{1});
            electrodeInfo=bids.util.tsvread(subj_electrodes{1});

            %estimate channel definitions
            [definitions,~,ic] = unique(regexprep(channelinfo.name,'\d+$',''));
            eldef=obj.CreateOutput(obj.ElectrodeDefinitionIdentifier);
            ellocs=obj.CreateOutput(obj.ElectrodeLocationIdentifier);
            for i=1:length(definitions)
                name=definitions{i};
                def_idx=find(ic == i);
                if(all(strcmp(channelinfo.type(def_idx),'ECOG')))
                    type='Grid';
                elseif(all(strcmp(channelinfo.type(def_idx),'SEEG')))
                    type='Depth';
                else
                    continue;
                end
                
                locs=[electrodeInfo.x(def_idx) electrodeInfo.y(def_idx) electrodeInfo.z(def_idx)];
                locs(any(isnan(locs),2),:)=[];
                N=size(locs,1);
                spacing=mean(diag(pdist2(locs(1:end-1,:),locs(2:end,:))));
                idx=eldef.AddDefinition(type,name,N,spacing,3);
                ellocs.AddWithIdentifier(idx,locs);

            end

            %load T1 mri
            mri_paths=dir(fullfile(BIDS.pth,'derivatives','*',['sub-' curr_subj],'*.nii'));
            if(~isempty(mri_paths))
                mri_path=fullfile(mri_paths.folder,mri_paths.name);
            else
                [idx,tf]=listdlg('PromptString','Multiple viable nifti files found','SelectionMode','single','ListString',{mri_paths.name});
                if(tf == 0)
                    error('MRI selection aborted');
                end
                mri_path=fullfile(mri_paths(idx).folder,mri_paths(idx).name);
            end

            mri=obj.CreateOutput(obj.MRIIdentifier);
            mri.LoadFromFile(mri_path);
            

        end

    end
end

