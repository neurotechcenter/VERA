classdef Coregistration < AComponent
    %Coregistration Uses SPM12 to coregister Volumes to each other.
    %Registers the CoregistrationIdentifier to the ReferenceIdentifier.

    properties
        ReferenceIdentifier
        CoregistrationIdentifier
        TIdentifier
    end
    properties (Dependent) %preserve identifiers for backwards compatibility
        MRIIdentifier
        CTIdentifier
    end

    methods
        function value=get.MRIIdentifier(obj)
            value=obj.ReferenceIdentifier;
        end

        function value=get.CTIdentifier(obj)
            value=obj.CoregistrationIdentifier;
        end

        function set.MRIIdentifier(obj,value)
            obj.ReferenceIdentifier=value;
        end

        function set.CTIdentifier(obj,value)
            obj.CoregistrationIdentifier=value;
        end

        function obj = Coregistration()
            obj.ReferenceIdentifier      = 'MRI';
            obj.CoregistrationIdentifier = 'CT';
            obj.TIdentifier              = 'T';
            obj.ignoreList{end+1}        = 'MRIIdentifier';
            obj.ignoreList{end+1}        = 'CTIdentifier';
        end
        function Publish(obj)
            obj.AddInput(obj.ReferenceIdentifier,       'Volume');
            obj.AddInput(obj.CoregistrationIdentifier,  'Volume');
            obj.AddOutput(obj.CoregistrationIdentifier, 'Volume');
            obj.AddOutput(obj.TIdentifier,              'TransformationMatrix');

            obj.RequestDependency('SPM12','folder');
        end
        function Initialize(obj)
            path = obj.GetDependency('SPM12');
            addpath(path);

        end

        function [coregOut, T] = Process(obj,ref,coreg)
            [a,b,c]  = fileparts(ref.Path);
            pref_ref = fullfile(a,['r' b c]);

            [a,b,c]    = fileparts(coreg.Path);
            pref_coreg = fullfile(a,['r' b c]);

            copyfile(ref.Path, pref_ref);
            V = spm_vol(coreg.Path);

            % func_img = spm_read_vols(V);
            %  func_img=func_img+(rand(size(func_img)) > 0.5);
            new_nii       = spm_create_vol(V);
            new_nii.fname = pref_coreg;
            new_img       = spm_write_vol(new_nii, coreg.Image.img);
            %spm12 seems to have issues with some nifti images; this way we can make sure that the CT is correct
            %copyfile(coreg.Path,pref_coreg);
            refhandle   = spm_vol(pref_ref);
            coreghandle = spm_vol(pref_coreg);

            % put data into the job structure so that spm knows how to access it
            job.ref    = refhandle;
            job.source = coreghandle;
            % job.other  = {};

            job.eoptions.cost_fun = 'nmi';
            job.eoptions.sep      = [4 2];
            job.eoptions.fwhm     = [7 7];
            job.eoptions.tol      = [0.02, 0.02, 0.02, 0.001, 0.001, 0.001, 0.01, 0.01, 0.01, 0.001, 0.001, 0.001];
%             job.roptions.prefix   = 'r';
%             job.roptions.mask     = 0;
%             job.roptions.interp   = 1;
%             job.roptions.wrap     = 1;
%             job.roptions.prefix   = 'r';

            % feed the job structure into spm
            % I took this from the spm coreg est write function
            % It makes the coreg work
            % I have modified it to take my input
            %%%%%%%%%%%%%%%%%%%%%%%%%%% start spm code %%%%%%%%%%%%%%%%%%%%%%%%%%%
            job.other = {};

            x = spm_coreg(job.ref, job.source, job.eoptions);

            M         = spm_matrix(x);
            PO        = job.source;
            MM        = zeros(4,4,numel(PO));
            MM(:,:,1) = spm_get_space(PO.fname);
            spm_get_space(PO.fname, M\MM(:,:,1));

            %%%%%%%%%%%%%%%%%%%%%%%%%%%%% end spm code %%%%%%%%%%%%%%%%%%%%%%%%%%%%
            T          = obj.CreateOutput(obj.TIdentifier);
            T.T(:,:,1) = inv(job.source.mat);
            T.T(:,:,2) = M\MM(:,:,1);

            coregOut   = obj.CreateOutput(obj.CoregistrationIdentifier);
            coregOut.LoadFromFile(pref_coreg);

        end
    end
end

