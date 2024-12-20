classdef AlignToMNISpace < AComponent
    %AlignToMNISpace Alignment to MNI Coordinate
    %based on: https://neuroimaging-core-docs.readthedocs.io/en/latest/pages/spm_anat_normalization-rev.html
    
    properties
        VolumeInIdentifier
        VolumeOutIdentifier
        TIdentifier
    end
    
    methods
        function obj = AlignToMNISpace()
            obj.VolumeInIdentifier='MRI';
            obj.VolumeOutIdentifier='MNI';
            obj.TIdentifier='T_MNI';
        end
        
        function Publish(obj)
            obj.AddInput(obj.VolumeInIdentifier,'Volume');
            obj.AddOutput(obj.VolumeOutIdentifier,'Volume');
            obj.AddOutput(obj.TIdentifier,'TransformationMatrix');
            obj.RequestDependency('SPM12','folder');
        end

        function Initialize(obj)
            path=obj.GetDependency('SPM12');
            addpath((path));
             addpath(genpath(fullfile(path,'matlabbatch')));
        end

        function [mni,T]=Process(obj,mri)
            spmpath=obj.GetDependency('SPM12');
            spm('defaults', 'FMRI');
            matlabbatch{1}.spm.spatial.preproc.channel.vols = {[mri.Path ',1']};
            matlabbatch{1}.spm.spatial.preproc.channel.biasreg = 0.001;
            matlabbatch{1}.spm.spatial.preproc.channel.biasfwhm = 60;
            matlabbatch{1}.spm.spatial.preproc.channel.write = [0 1];
            matlabbatch{1}.spm.spatial.preproc.tissue(1).tpm = {fullfile(spmpath,'/tpm/TPM.nii,1')};
            matlabbatch{1}.spm.spatial.preproc.tissue(1).ngaus = 1;
            matlabbatch{1}.spm.spatial.preproc.tissue(1).native = [1 0];
            matlabbatch{1}.spm.spatial.preproc.tissue(1).warped = [0 0];
            matlabbatch{1}.spm.spatial.preproc.tissue(2).tpm = {fullfile(spmpath,'/tpm/TPM.nii,2')};
            matlabbatch{1}.spm.spatial.preproc.tissue(2).ngaus = 1;
            matlabbatch{1}.spm.spatial.preproc.tissue(2).native = [1 0];
            matlabbatch{1}.spm.spatial.preproc.tissue(2).warped = [0 0];
            matlabbatch{1}.spm.spatial.preproc.tissue(3).tpm = {fullfile(spmpath,'/tpm/TPM.nii,3')};
            matlabbatch{1}.spm.spatial.preproc.tissue(3).ngaus = 2;
            matlabbatch{1}.spm.spatial.preproc.tissue(3).native = [1 0];
            matlabbatch{1}.spm.spatial.preproc.tissue(3).warped = [0 0];
            matlabbatch{1}.spm.spatial.preproc.tissue(4).tpm = {fullfile(spmpath,'/tpm/TPM.nii,4')};
            matlabbatch{1}.spm.spatial.preproc.tissue(4).ngaus = 3;
            matlabbatch{1}.spm.spatial.preproc.tissue(4).native = [1 0];
            matlabbatch{1}.spm.spatial.preproc.tissue(4).warped = [0 0];
            matlabbatch{1}.spm.spatial.preproc.tissue(5).tpm = {fullfile(spmpath,'/tpm/TPM.nii,5')};
            matlabbatch{1}.spm.spatial.preproc.tissue(5).ngaus = 4;
            matlabbatch{1}.spm.spatial.preproc.tissue(5).native = [1 0];
            matlabbatch{1}.spm.spatial.preproc.tissue(5).warped = [0 0];
            matlabbatch{1}.spm.spatial.preproc.tissue(6).tpm = {fullfile(spmpath,'/tpm/TPM.nii,6')};
            matlabbatch{1}.spm.spatial.preproc.tissue(6).ngaus = 2;
            matlabbatch{1}.spm.spatial.preproc.tissue(6).native = [0 0];
            matlabbatch{1}.spm.spatial.preproc.tissue(6).warped = [0 0];
            matlabbatch{1}.spm.spatial.preproc.warp.mrf = 1;
            matlabbatch{1}.spm.spatial.preproc.warp.cleanup = 1;
            matlabbatch{1}.spm.spatial.preproc.warp.reg = [0 0.001 0.5 0.05 0.2];
            matlabbatch{1}.spm.spatial.preproc.warp.affreg = 'mni';
            matlabbatch{1}.spm.spatial.preproc.warp.fwhm = 0;
            matlabbatch{1}.spm.spatial.preproc.warp.samp = 3;
            matlabbatch{1}.spm.spatial.preproc.warp.write = [0 1];
            matlabbatch{1}.spm.spatial.preproc.warp.vox = NaN;
            matlabbatch{1}.spm.spatial.preproc.warp.bb = [NaN NaN NaN
                                                          NaN NaN NaN];
            matlabbatch{2}.spm.spatial.normalise.write.subj.def(1) = cfg_dep('Segment: Forward Deformations', substruct('.','val', '{}',{1}, '.','val', '{}',{1}, '.','val', '{}',{1}), substruct('.','fordef', '()',{':'}));
            matlabbatch{2}.spm.spatial.normalise.write.subj.resample(1) = cfg_dep('Segment: Bias Corrected (1)', substruct('.','val', '{}',{1}, '.','val', '{}',{1}, '.','val', '{}',{1}), substruct('.','channel', '()',{1}, '.','biascorr', '()',{':'}));
            matlabbatch{2}.spm.spatial.normalise.write.woptions.bb = [-78 -112 -70
                                                                      78 76 85];
            matlabbatch{2}.spm.spatial.normalise.write.woptions.vox = [1 1 1];
            matlabbatch{2}.spm.spatial.normalise.write.woptions.interp = 4;
            matlabbatch{2}.spm.spatial.normalise.write.woptions.prefix = 'w';

            
            spm_jobman('run', matlabbatch, []);
            [a,b,c]=fileparts(mri.Path);
            mni=obj.CreateOutput(obj.VolumeOutIdentifier);
            mni.LoadFromFile(fullfile(a,['wm' b c]));
            tfmat=load(fullfile(a,[b '_seg8.mat']));
            T=obj.CreateOutput(obj.TIdentifier);
            T.T=tfmat.Affine;
        end
    end
end

