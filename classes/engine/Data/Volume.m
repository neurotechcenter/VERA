classdef Volume < AData & IFileLoader
    %VOLUME Data class for MRI,CT or similar volumetric data
    %   Volume Data is stored in the nifti format
    %   RAS and voxel axis are assumed to be parallel, if not image will be
    %   resliced accordingly
    % See also AData, load_nii
    properties
         %Volume data as struct
        %  nii structure:
        %
        %	hdr -		struct with NIFTI header fields.
        %
        %	filetype -	Analyze format .hdr/.img (0); 
        %			NIFTI .hdr/.img (1);
        %			NIFTI .nii (2)
        %
        %	fileprefix - 	NIFTI filename without extension.
        %
        %	machine - 	machine string variable.
        %
        %	img - 		3D (or 4D) matrix of NIFTI data.
        %
        %	original -	the original header before any affine transform.
        % See also load_nii
        Image
        Path
    end
    
    methods
        
        function obj=Volume()
            obj.ignoreList{end+1}='Image';

        end
        
        function coordOut=Vox2Ras(obj,coordIn)
            %Vox2Ras transforms coordinates from Voxel space into RAS sapce
            coordOut=(coordIn(:)-obj.Image.hdr.hist.originator(1:3)').*obj.Image.hdr.dime.pixdim(2:4)';
        end
        
        function coordOut=Ras2Vox(obj,coordIn)
            %Ras2Vox transforms RAS coordinates into voxel coordinates
            coordOut=max(min(round((coordIn(:)./obj.Image.hdr.dime.pixdim(2:4)')+obj.Image.hdr.hist.originator(1:3)'),size(obj.Image.img)),[1;1;1]);
        end
        
        function [x,y,z]=GetRasAxis(obj)
            % Returns the projection from voxel to RAS coordinate
            x=((1:size(obj.Image.img,1))-obj.Image.hdr.hist.originator(1)).*obj.Image.hdr.dime.pixdim(2);
            y=((1:size(obj.Image.img,2))-obj.Image.hdr.hist.originator(2)).*obj.Image.hdr.dime.pixdim(3);
            z=((1:size(obj.Image.img,3))-obj.Image.hdr.hist.originator(3)).*obj.Image.hdr.dime.pixdim(4);
        end
        
        
        function LoadFromFile(obj,path)
            % Load nifti file from path
            % This function supports nifit as well as dicom
            % If multiple images are found in the dicom, it will show a
            % selection dialog
            % See also IFileLoader
            [spath,~,ext]=fileparts(path);
            tpath=obj.GetDependency('TempPath');
            if(any(strcmpi(ext,{'.dcm','.dicom'})))
                error('Cannot load from DICOM format');
            end
            try
            obj.Image=load_nii(path,[],[],[],[],[],0);
            obj.Path=path;
            catch 
                    
                    warning 'Input image transformation is not orthogonal; reslicing image'
                    reslice_nii(path,fullfile(tpath,'buff.nii'),[],[],[],2);
                    obj.Image=load_nii(fullfile(tpath,'buff.nii'));
                    obj.Path=fullfile(tpath,'buff.nii');
            end

               % [nii.img,nii.XYZ ]=spm_read_vols(nii);

        end
        
        function Load(obj,path)
            %Load - override of serializer load
            %See also Serializable.Load
            Load@AData(obj,path);
            obj.Path=obj.makeFullPath(obj.Path);
            if(~isempty(obj.Path))
            obj.Image=load_nii(obj.Path,[],[],[],[],[],0);
            end
        end
        function savepath=Save(obj,path)
            if(~isempty(obj.Image))
                obj.Path=fullfile(path,[obj.Name '.nii']);
                save_nii(obj.Image,obj.Path);
            end
            buffPath=obj.Path;
            obj.Path=obj.makeRelativePath(buffPath,true);
            savepath=Save@AData(obj,path);
            obj.Path=buffPath;
        end
    end
end

