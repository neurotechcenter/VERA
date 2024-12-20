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
    
    properties (Access = private)
        RasVolume
        VoxelSize
    end
    
    methods
        
        function obj=Volume()
            obj.ignoreList{end+1}='Image';
            obj.RasVolume=[];
        end

        function AddTransformation(obj,T)
            %AddTransformation - multiplies the transformation matrix T
            %into the existing transformation matrix within the Nifti 
            % T - transformation matrix
            new_T=T*([obj.Image.hdr.hist.srow_x;obj.Image.hdr.hist.srow_y;obj.Image.hdr.hist.srow_z;0 0 0 1]);
            obj.Image.hdr.hist.srow_x=new_T(1,:);
            obj.Image.hdr.hist.srow_y=new_T(2,:);
            obj.Image.hdr.hist.srow_z=new_T(3,:);
        end
        
        function coordOut=Vox2Ras(obj,coordIn)
            %Vox2Ras transforms coordinates from Voxel space into RAS sapce
            %Input coordinates are assumed to be in MATLABs 1 index system
            if(numel(coordIn) == 3)
                coordOut= ([obj.Image.hdr.hist.srow_x;obj.Image.hdr.hist.srow_y;obj.Image.hdr.hist.srow_z;0 0 0 1]*[coordIn(:)-1; 1]);
                coordOut=coordOut(1:3);
            else
                for i=1:size(coordIn,1)
                    coordOut(i,:)=[obj.Image.hdr.hist.srow_x;obj.Image.hdr.hist.srow_y;obj.Image.hdr.hist.srow_z;0 0 0 1]*[coordIn(i,:)'-1; 1];
                end
                coordOut=coordOut(:,1:3);
            end
            
        end
        
        function coordOut=Ras2Vox(obj,coordIn)
            %Ras2Vox transforms RAS values into Matlab 1 based voxel
            %coordinates
           coordOut=[obj.Image.hdr.hist.srow_x;obj.Image.hdr.hist.srow_y;obj.Image.hdr.hist.srow_z;0 0 0 1]\[coordIn(:); 1];
           coordOut=coordOut(1:3)+1;
        end
        
        function V=GetRasSlicedVolume(obj,voxelSize,forceReslice)
            %GetRasSlicedVolume - returns a new Volume which is resliced
            %for orthogonal RAS projection
            % voxelSize - voxel size (1x3 vector for x,y,z) after reslicing, default is [1 1 1];
            % forceReslice - if the original volume does not require
            % slicing based on voxel size and original orientation, no
            % reslicing would be performed unless forceReslice is true
            % returns: new Volume 
            if(nargin < 2)
                voxelSize=[1 1 1];
            else
                if(isempty(voxelSize))
                    voxelSize=[1 1 1];
                end

            end
            if(nargin < 3)
                forceReslice=false;
            end
            %ras sliced volume 
            if((~isempty(obj.RasVolume) && isequal(voxelSize,obj.VoxelSize)) && ~forceReslice)
                V=obj.RasVolume;
            else
                [~,name]=fileparts(tempname);
                tpath=fullfile(obj.GetDependency('TempPath'),[name '.nii']);
                obj.VoxelSize=voxelSize;
                reslice_nii(obj.Path,tpath,voxelSize);
                V=Volume();
                V.LoadFromFile(tpath);
                V.Path='';
                obj.RasVolume=V;
                delete(tpath);
            end
        end

        function [x,y,z]=GetRasAxis(obj)
            % Returns the projection from voxel to RAS coordinate
            if(~isfield(obj.Image.hdr.hist,'originator'))
                error('GetRasAxis is only available for data sliced along the RAS axis');
            end
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
            try
                tpath=fullfile(obj.GetDependency('TempPath'),'dicom_convert');
            catch
                tpath='temp';
            end

            mkdir(tpath);
            try
                [spath,~,ext]=fileparts(path);
                if(any(strcmpi(ext,{'.dcm','.dicom','','.IMA'})))
                    dicm2nii(spath,tpath,0);
                    path=dir(fullfile(tpath,'*.nii'));

                    % remove . files from options (mac files)
                    remfile = [];
                    for i = 1:length(path)
                        if startsWith(path(i).name,'.')
                            remfile = i;
                        end
                    end
                    path(remfile) = [];

                    if(numel(path) > 1 )
                        warning('Dicom contains multiple Image Containers!');
                        sel_name={path.name};
                        [idx,tf]=listdlg('PromptString','Please Select the correct Dicom for import','SelectionMode','single','ListString',sel_name);
                        if(tf ~= 0)
                            path=path(idx);
                        else
                            error('No Dicom selected!');
                        end
                    end
                    path=fullfile(path.folder,path.name);
            end
            try
                obj.Image=load_nii(path,[],[],[],[],[],0);
                obj.Path=path;
            catch e
                fprintf(e.message);
                obj.Image=load_untouch_nii(path,[],[],[],[],[]);
                obj.Path=path;    
            end
            catch
            end
            rmdir(tpath,'s'); %ensure that temp folder is deleted
               % [nii.img,nii.XYZ ]=spm_read_vols(nii);

        end
        
        function Load(obj,path)
            %Load - override of serializer load
            %See also Serializable.Load
            Load@AData(obj,path);
            obj.Path=obj.makeFullPath(obj.Path);
            if(~isempty(obj.Path))
                try
                    obj.Image=load_nii(path,[],[],[],[],[],0);
                catch
                    obj.Image=load_untouch_nii(obj.Path,[],[],[],[],[]);
                end
            end
        end

        
        function SaveNiiToPath(obj,path)
            if(isfield(obj.Image,'untouch') && obj.Image.untouch == 1)
                save_untouch_nii(obj.Image,path);
            else
                save_nii(obj.Image,path);
            end           
        end
        

        function savepath=Save(obj,path)
            if(~isempty(obj.Image))
                obj.Path=obj.normalizeSlashes(fullfile(path,[obj.Name '.nii']));
                if(isfield(obj.Image,'untouch') && obj.Image.untouch == 1)
                    obj.Image.hdr.hist.magic='n+1';
                    save_untouch_nii(obj.Image,obj.Path);
                else
                    save_nii(obj.Image,obj.Path);
                end
            end
            buffPath=obj.Path;
            obj.Path=obj.makeRelativePath(buffPath,true);
            savepath=Save@AData(obj,path);
            obj.Path=buffPath;
        end
    end
end

