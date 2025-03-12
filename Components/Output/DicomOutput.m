classdef DicomOutput < AComponent
    %DicomOutput Creates a .dcm files as Output of VERA using Matlab's
    %dicomwrite function. This is paired with the LoadDicomHeader component
    %to save the dicom header information
    % If starting with nifti files, use the CreateDicomHeader component to
    % create the header and enable the CreatedHeader flag
    properties
        VolumeIdentifier
        HeaderIdentifier
        SavePathIdentifier char
        CreatedHeader
    end
    
    methods
        function obj = DicomOutput()
            obj.VolumeIdentifier   = 'MRI';
            obj.HeaderIdentifier   = 'MRIHeader';
            obj.SavePathIdentifier = 'default';
            obj.CreatedHeader      = 0;
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
            
            % Account for MATLAB's transpose of NifTi files
            img = vol.Image.img;
            img = permute(img, [1 3 2]);
            img = flip(img,2);
            img = flip(img,3);

            % Not sure why this is necessary
            if obj.CreatedHeader
                img = flip(img,1);
            end

            for i = 1:size(img,1)
                slice = squeeze(img(i, :, :));
                dicomFileName = sprintf('%s/slice_%03d.dcm', fullfile(path), i);

                % Write the slice to a DICOM file
                dicomwrite(slice, dicomFileName, dcmheader.Header(i),'CreateMode','Copy');
            end

            % Popup stating where file was saved
            message    = {'Files saved to:',GetFullPath(path)};
            msgBoxSize = [350, 125];
            obj.VERAMessageBox(message,msgBoxSize);

        end
        
    end
end

