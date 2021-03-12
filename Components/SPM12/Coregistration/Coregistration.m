classdef Coregistration < AComponent
    %Coregistration Uses SPM12 to coregister Volumes to each  other
    
   properties
        MRIIdentifier
        CTIdentifier
        TIdentifier
    end
    
    methods
        function obj = Coregistration()
            obj.MRIIdentifier='MRI';
            obj.CTIdentifier='CT';
            obj.TIdentifier='T';
            
        end
        function Publish(obj)
            obj.AddInput(obj.MRIIdentifier,'Volume');
            obj.AddInput(obj.CTIdentifier,'Volume');
            obj.AddOutput(obj.CTIdentifier,'Volume');
            obj.AddOutput(obj.TIdentifier,'TransformationMatrix');
            obj.RequestDependency('SPM12','folder');
        end
        function Initialize(obj)
            path=obj.GetDependency('SPM12');
            addpath(path);
            
        end
        
        function [ct,T] = Process(obj,mri,ct)
            [a,b,c]=fileparts(mri.Path);
            pref_mri=fullfile(a,['r' b c]);
            
            [a,b,c]=fileparts(ct.Path);
            pref_ct=fullfile(a,['r' b c]);
            
            copyfile(mri.Path,pref_mri);
            copyfile(ct.Path,pref_ct);
            mrihandle = spm_vol(pref_mri);
            cthandle = spm_vol(pref_ct);

            % put data into the job structure so that spm knows how to access it
            job.ref = mrihandle;
            job.source = cthandle;
            %job.other = {};

            job.eoptions.cost_fun = 'nmi';
            job.eoptions.sep = [4 2];
            job.eoptions.fwhm = [7 7];
            job.eoptions.tol = [0.02, 0.02, 0.02, 0.001, 0.001, 0.001, 0.01, 0.01, 0.01, 0.001, 0.001, 0.001];
%             job.roptions.prefix = 'r';
%             job.roptions.mask = 0;
%             job.roptions.interp = 1;
%             job.roptions.wrap = 1;
%             job.roptions.prefix = 'r';

            % feed the job structure into spm
            % I took this from the spm coreg est write function
            % It makes the coreg work
            % I have modified it to take my input
            %%%%%%%%%%%%%%%%%%%%%%%%%%% start spm code %%%%%%%%%%%%%%%%%%%%%%%%%%%
            job.other = {};

            x = spm_coreg(job.ref, job.source, job.eoptions);

            M = spm_matrix(x);
            PO = job.source;
            MM = zeros(4,4,numel(PO));
            MM(:,:,1) = spm_get_space(PO.fname);
            spm_get_space(PO.fname, M\MM(:,:,1));
            
            
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%% end spm code %%%%%%%%%%%%%%%%%%%%%%%%%%%%
            T=obj.CreateOutput(obj.TIdentifier);
            T.T(:,:,1)=inv(job.source.mat);
            T.T(:,:,2)=M\MM(:,:,1);
            ct=obj.CreateOutput(obj.CTIdentifier);
            ct.LoadFromFile(pref_ct);
            
            
        end
    end
end

