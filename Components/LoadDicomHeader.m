classdef LoadDicomHeader < AComponent
    %LoadDicomHeader - This component extracts the dicom info from dicom
    %files. Select one dicom file to provide the path to the folder
    %containing the dicom files. This folder should contain only one
    %volume.

    properties
        Identifier char       % Data identifier
        InputFilepath char
        Anonymize
    end

    methods
        function obj = LoadDicomHeader()
            obj.Identifier     = 'MRIHeader';
            obj.InputFilepath  = '';
            obj.Anonymize      = 1;
        end

        function Publish(obj)
            % Publish - Define Output for Component
            % See also AComponent.Publish
            if(isempty(obj.Identifier))
                error('No Identifier Tag specified');
            end

            obj.AddOutput(obj.Identifier, 'DicomHeader');

        end

        function Initialize(obj)
        end

        function [out] = Process(obj)
            if ~isempty(obj.InputFilepath)

                % working directory is VERA project
                if isAbsolutePath(obj.InputFilepath)
                    [path,~,ext] = fileparts(obj.InputFilepath);
                else
                    [path,~,ext] = fileparts(fullfile(obj.ComponentPath,'..',obj.InputFilepath));
                    path = GetFullPath(path);
                end

                % Open a file load dialog if you can't find the path
                if ~isfolder(path)
                    [file,path] = uigetfile('*.dcm',['Please select ' obj.Identifier]);
                    [path,~,ext] = fileparts(fullfile(path,file));
                end
            else
                [file,path] = uigetfile('*.dcm',['Please select ' obj.Identifier]);
                [path,~,ext] = fileparts(fullfile(path,file));
            end
            
            out = obj.CreateOutput(obj.Identifier);

            % Extract and store dicom headers
            if strcmp(ext,'.dcm')
                d = dir(fullfile(path,'*.dcm'));
                for i = 1:length(d)
                    info = out.ExtractDicomHeader(fullfile(path,d(i).name));
                    
                    if obj.Anonymize
                        info = out.AnonymizeDicom(info);
                    end

                    out.Header{i} = info;
                end

            else
                errordlg('Please select one dicom file to provide the path to the volume.\n');
            end

        end
    end
end

