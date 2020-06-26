classdef Volume < AData & IFileLoader
    %VOLUME Summary of this class goes here
    %   Detailed explanation goes here
    properties
        Image
        Path
    end
    
    methods
        
        function obj=Volume()
            obj.ignoreList{end+1}='Image';

        end
        
        function coordOut=Vox2Ras(obj,coordIn)
            coordOut=(coordIn(:)-obj.Image.hdr.hist.originator(1:3)').*obj.Image.hdr.dime.pixdim(2:4)';
        end
        
        function coordOut=Ras2Vox(obj,coordIn)
            coordOut=max(min(round((coordIn(:)./obj.Image.hdr.dime.pixdim(2:4)')+obj.Image.hdr.hist.originator(1:3)'),size(obj.Image.img)),[1;1;1]);
        end
        
        function [x,y,z]=GetRasAxis(obj)
            x=((1:size(obj.Image.img,1))-obj.Image.hdr.hist.originator(1)).*obj.Image.hdr.dime.pixdim(2);
            y=((1:size(obj.Image.img,2))-obj.Image.hdr.hist.originator(2)).*obj.Image.hdr.dime.pixdim(3);
            z=((1:size(obj.Image.img,3))-obj.Image.hdr.hist.originator(3)).*obj.Image.hdr.dime.pixdim(4);
        end
        
        
        function LoadFromFile(obj,path)

            [spath,~,ext]=fileparts(path);
            tpath=obj.GetDependency('TempPath');
            if(any(strcmpi(ext,{'.dcm','.dicom'})))
                %gather all dicom files for this subject
%                 fd=dir(fullfile(path,['*' ext]));
%                 files=cell(length(fd),1);
%                 for i=1:length(fd)
%                     files{i}=fullfile(fd(i).folder,fd(i).name);
%                 end
                [~,path]=dicm2nii(spath,tpath,0);
                if(numel(path) > 1 )
                    warning('Dicom contains multiple Image Containers!');
                    sel_name=cellfun(@(x)dir(x),path,'UniformOutput',false);
                    sel_name={sel_name{:}.name};
                    [idx,tf]=listdlg('PromptString','Please Select the correct Dicom for import','SelectionMode','single','ListString',sel_name);
                    if(tf ~= 0)
                        path=path{idx};
                    else
                        error('No Dicom selected!');
                    end
                else
                path=path{1};
                end
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

