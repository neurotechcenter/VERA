classdef SPM12FileLoader < FileLoader
    %SPM12FILELOADER Load DICOM using the SPM12 Converter
    
    properties
        tempFolder
    end
    
    methods
        function obj = SPM12FileLoader()
            %SPM12FILELOADER Construct an instance of this class
            %   Detailed explanation goes here
            obj.tempFolder='niftiConversion';
        end
        
        function Publish(obj)
            obj.RequestDependency('SPM12','folder');
            Publish@FileLoader(obj);
            
        end
        
        function Initialize(obj)
            path=obj.GetDependency('SPM12');
            addpath(path);
            Initialize@FileLoader(obj);
        end
        
        function out = Process(obj)
             [file,path]=uigetfile(obj.FileTypeWildcard,['Please select ' obj.Identifier]);
             tpath=obj.GetDependency('TempPath');
             if isequal(file,0)
                 error([obj.Identifier ' selection aborted']);
             else
                 file=fullfile(path,file);
                 if(obj.isDicom(file))
                     file=obj.convertToNifti(file);
                 end
                 out=obj.CreateOutput(obj.Identifier);
                 out.LoadFromFile(file);
                 if(exist(fullfile(tpath,obj.tempFolder),'dir'))
                     rmdir(fullfile(tpath,obj.tempFolder),'s');
                 end
             end
        end
        
        function niftifile=convertToNifti(obj,dicomfile)
            tpath=obj.GetDependency('TempPath');
            mkdir(fullfile(tpath,obj.tempFolder));
            %we assume that all files in the folder should be converted
            [~,~,ext]=fileparts(dicomfile);
            files=dir(fullfile(fileparts(dicomfile),['*' ext]));
            paths=obj.dir2files(files);
            job.data = paths;
            job.root = 'flat';
            job.outdir = {fullfile(tpath,obj.tempFolder)};
            job.protfilter = '.*';
            job.convopts.format = 'nii';
            job.convopts.meta = 0;
            hdr = spm_dicom_headers(strvcat(job.data));
            files=spm_dicom_convert(hdr,'all',job.root,job.convopts.format,job.outdir{1});
            spm_reslice
            files=files.files;
            %files=dir(fullfile(job.outdir{1},['*.nii'])); %check the output files
            if(length(files) == 1)
                niftifile=files{1};
    
            else
                
                [idx,tf]=listdlg('PromptString','Please Select the correct Dicom for import','SelectionMode','single','ListString',files);
                if(tf ~= 0)
                    niftifile=files{idx};
                else
                    error('No Dicom selected!');
                end
            end
            
        end

        function b=isDicom(~,file)
            [~,~,ext]=fileparts(file);
            b=(strcmp(ext,'.dcm') | strcmp(ext,'.dicom'));
        end
        
        function paths=dir2files(~,dirfiles)
            paths=cell(length(dirfiles),1);
            for i=1:length(paths)
                paths{i}=fullfile(dirfiles(i).folder,dirfiles(i).name);
            end
        end
    end
end

