classdef DicomOutput < AComponent
    %DicomOutput Creates a .dcm files as Output of VERA using Matlab's
    %dicomwrite function. This is paired with the LoadDicomHeader component
    %to save the dicom header information
    properties
        VolumeIdentifier
        HeaderIdentifier
        SavePathIdentifier char
    end
    
    methods
        function obj = DicomOutput()
            obj.VolumeIdentifier   = 'MRI';
            obj.HeaderIdentifier   = 'MRIHeader';
            obj.SavePathIdentifier = 'default';
        end
        
        function Publish(obj)
            obj.AddInput(obj.VolumeIdentifier, 'Volume');
            obj.AddInput(obj.HeaderIdentifier, 'DicomHeader');
        end
        
        function Initialize(obj)
        end
        
        function []= Process(obj, vol, dcmheader)

            % create output files in DataOutput/VolumeIdentifer/slice_n.dcm (default behavior)
            if strcmp(obj.SavePathIdentifier,'default')
                path = fullfile(obj.ComponentPath,'..','DataOutput',obj.VolumeIdentifier);

            % if empty, use dialog
            elseif isempty(obj.SavePathIdentifier)
                if ~isfolder(fullfile(obj.ComponentPath,'..','DataOutput'))
                    mkdir(fullfile(obj.ComponentPath,'..','DataOutput'))
                end

                path = uigetdir(fullfile(obj.ComponentPath,'..','DataOutput'));

                if isequal(path, 0)
                    error('Selection aborted');
                end
                
            % Otherwise, save to specified folder
            else
                path = obj.SavePathIdentifier;
                if ~isAbsolutePath(path)
                    path = fullfile(obj.ComponentPath,'..',path);
                end
            end

            % create save folder if it doesn't exist
            if ~isfolder(path)
                mkdir(path)
            else % if it is already populated, delete it and start fresh
                d = dir(fullfile(path,'*.dcm'));
                for i = 1:length(d)
                    delete(fullfile(d(i).folder,d(i).name))
                end
            end

            outputDir = fullfile(path);
            
            img = vol.Image.img;

            % Account for MATLAB's transpose of NifTi files
            img = permute(img, [1 3 2]);
            img = flip(img,2);
            img = flip(img,3);

            for i = 1:size(img,1)
                slice = squeeze(img(i, :, :));
                dicomFileName = sprintf('%s/slice_%03d.dcm', outputDir, i);

                % Write the slice to a DICOM file
                dicomwrite(slice, dicomFileName, dcmheader.Header(i),'CreateMode','Copy');
            end

            % Popup stating where file was saved
            msgbox(['Files saved to: ',GetFullPath(path)],['"',obj.Name,'" files saved'])
        end
        
    end
end

