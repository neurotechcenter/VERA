classdef BuildSkullMask < AComponent
    %BuildSkullMask Use SPM12 to create a skull mask for skullstripping
    % Often combined with the ApplyMask component
    
    properties
        MRIIdentifier
        MaskIdentifier
    end
    
    methods
        function obj = BuildSkullMask()
            obj.MRIIdentifier='MRI';
            obj.MaskIdentifier='Skullmask';
        end
        
        function Publish(obj)
            obj.AddInput(obj.MRIIdentifier,'Volume');
            obj.AddOutput(obj.MaskIdentifier,'Volume');
            obj.RequestDependency('SPM12','folder');
            
        end
        
        
        function Initialize(obj)
            addpath(obj.GetDependency('SPM12'));
        end
        
        function [mask,T]=Process(obj,mri)
            mask=obj.CreateOutput(obj.MaskIdentifier);
            spmpath=obj.GetDependency('SPM12');
            %https://en.wikibooks.org/wiki/Neuroimaging_Data_Processing/Skull_Stripping#SPM
            matlabbatch{1}.spm.spatial.preproc.channel.vols = {[mri.Path ',1']};
           matlabbatch{1}.spm.spatial.preproc.channel.biasreg = 0.001;
            matlabbatch{1}.spm.spatial.preproc.channel.biasfwhm = 60;
            matlabbatch{1}.spm.spatial.preproc.channel.write = [0 0];
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
            matlabbatch{1}.spm.spatial.preproc.tissue(4).tpm = {fullfile(spmpath,'tpm/TPM.nii,4')};
            matlabbatch{1}.spm.spatial.preproc.tissue(4).ngaus = 3;
            matlabbatch{1}.spm.spatial.preproc.tissue(4).native = [1 0];
            matlabbatch{1}.spm.spatial.preproc.tissue(4).warped = [0 0];
            matlabbatch{1}.spm.spatial.preproc.tissue(5).tpm = {fullfile(spmpath,'tpm/TPM.nii,5')};
            matlabbatch{1}.spm.spatial.preproc.tissue(5).ngaus = 4;
            matlabbatch{1}.spm.spatial.preproc.tissue(5).native = [1 0];
            matlabbatch{1}.spm.spatial.preproc.tissue(5).warped = [0 0];
            matlabbatch{1}.spm.spatial.preproc.tissue(6).tpm = {fullfile(spmpath,'tpm/TPM.nii,6')};
            matlabbatch{1}.spm.spatial.preproc.tissue(6).ngaus = 2;
            matlabbatch{1}.spm.spatial.preproc.tissue(6).native = [0 0];
            matlabbatch{1}.spm.spatial.preproc.tissue(6).warped = [0 0];
            matlabbatch{1}.spm.spatial.preproc.warp.mrf = 1;
            matlabbatch{1}.spm.spatial.preproc.warp.cleanup = 1;
            matlabbatch{1}.spm.spatial.preproc.warp.reg = [0 0.001 0.5 0.05 0.2];
            matlabbatch{1}.spm.spatial.preproc.warp.affreg = 'mni';
            matlabbatch{1}.spm.spatial.preproc.warp.fwhm = 0;
            matlabbatch{1}.spm.spatial.preproc.warp.samp = 3;
            matlabbatch{1}.spm.spatial.preproc.warp.write = [0 0];            
            spm('defaults', 'FMRI');
            spm_jobman('run', matlabbatch, []);
          
            
            matlabbatch={};
            matlabbatch{1}.spm.util.imcalc.input = {
                                                    [fullfile(fileparts(mri.Path),'c1MRI.nii') ',1']
                                                    [fullfile(fileparts(mri.Path),'c2MRI.nii') ',1']
                                                    [fullfile(fileparts(mri.Path),'c3MRI.nii') ',1']
                                                    [mri.Path ',1']
                                                    };
            matlabbatch{1}.spm.util.imcalc.output = 'output';
            matlabbatch{1}.spm.util.imcalc.outdir = {obj.GetDependency('TempPath')};
            matlabbatch{1}.spm.util.imcalc.expression = '(i4.*(i1 +i2+i3)) > 0.2';
            matlabbatch{1}.spm.util.imcalc.var = struct('name', {}, 'value', {});
            matlabbatch{1}.spm.util.imcalc.options.dmtx = 0;
            matlabbatch{1}.spm.util.imcalc.options.mask = 0;
            matlabbatch{1}.spm.util.imcalc.options.interp = 1;
            matlabbatch{1}.spm.util.imcalc.options.dtype = 4;
            spm_jobman('run', matlabbatch, []);
            mask.LoadFromFile(fullfile(obj.GetDependency('TempPath'),'output.nii'));
            %s = strel('ball',ceil(1/mask.Image.hdr.dime.pixdim(2)),ceil(1/mask.Image.hdr.dime.pixdim(2)));
            %mask.Image.img=imdilate(mask.Image.img,s);
        end
    end
end

