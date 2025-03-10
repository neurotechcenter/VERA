classdef CreateDicomHeader < AComponent
    %CreateDicomHeader - This component creates a dicom header by
    %extracting some information from the nifti file. The coordinate system
    %will differ due to the unknown starting point of the first slice.

    properties
        VolumeIdentifier
        HeaderIdentifier
    end

    methods
        function obj = CreateDicomHeader()
            obj.VolumeIdentifier = 'MRI';
            obj.HeaderIdentifier = 'MRIHeader';
        end

        function Publish(obj)
            % Publish - Define Output for Component
            % See also AComponent.Publish
            if(isempty(obj.VolumeIdentifier))
                error('No Identifier Tag specified');
            end

            obj.AddInput(obj.VolumeIdentifier, 'Volume');
            obj.AddOutput(obj.HeaderIdentifier, 'DicomHeader');

        end

        function Initialize(obj)
        end

        function header = Process(obj,vol)

            header = obj.CreateOutput(obj.HeaderIdentifier);

            sliceLocation = 0;
            edata         = vol.Image.ext.section.edata;
            edata         = strsplit(edata,';')';

            volhdr = vol.Image.hdr;

            % Generate Dicom headers
            for sliceNumber = 1:size(vol.Image.img,1)
                slice = squeeze(vol.Image.img(sliceNumber,:,:));

                header.Header{sliceNumber} = header.TemplateDicomHeader(slice,sliceNumber,sliceLocation,edata,volhdr);

                sliceLocation = header.Header{sliceNumber}.SliceLocation;

            end
        end
    end
end