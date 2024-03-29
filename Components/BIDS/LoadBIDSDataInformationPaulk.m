classdef LoadBIDSDataInformationPaulk < AComponent
    %LoadBIDSDataInformationPaulk Load data from BIDS dataset
    
    properties
        MRIIdentifier
        ElectrodeDefinitionIdentifier
        ElectrodeLocationIdentifier
    end
    
    methods
        function obj = LoadBIDSDataInformationPaulk()
           obj.Name='LoadPaulkDataset';
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
            electrodeInfo=readtable(fullfile(BIDS.pth,'derivatives','epochs',['sub-' curr_subj],'ieeg',['sub-' curr_subj '_task-ccepcoreg_space-T1w_electrodes.tsv']), 'FileType', 'text', 'Delimiter', '\t');

            %estimate channel definitions
            names=cellfun(@(x) (strsplit(x,'''')),electrodeInfo.name,'UniformOutput',false);
            
            [definitions,~,ic] = unique(cellfun(@(x)x{1},names,'UniformOutput',false));
            eldef=obj.CreateOutput(obj.ElectrodeDefinitionIdentifier);
            ellocs=obj.CreateOutput(obj.ElectrodeLocationIdentifier);
            for i=1:length(definitions)
                name=definitions{i};
                def_idx=find(ic == i);
                type='Depth';
                locs=[electrodeInfo.x(def_idx) electrodeInfo.y(def_idx) electrodeInfo.z(def_idx)]*1e3;
                N=size(locs,1);
                spacing=mean(diag(pdist2(locs(1:end-1,:),locs(2:end,:))));
                idx=eldef.AddDefinition(type,name,N,spacing,30);
                ellocs.AddWithIdentifier(idx,locs);

            end

            %load T1 mri
            mri_paths=dir(fullfile(BIDS.pth,['sub-' curr_subj],'anat',['sub-' curr_subj '_T1w.nii']));
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

