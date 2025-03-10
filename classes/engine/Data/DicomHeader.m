classdef DicomHeader < AData
    %DicomHeader - Data object for dicom header
    % see also AData
    
    properties
        Header %dicom header struct
    end
    
    methods
        function obj = DicomHeader()
            %Header Constructor
            obj.Header = struct([]);
        end

        function header = ExtractDicomHeader(obj,path)
            %Use Matlab's dicominfo function to extract dicom header information
            header = dicominfo(path);
        end

        function header = AnonymizeDicom(obj,header)
            % Anonymize a specific set header values. I tried using
            % Matlab's dicomanon function, but this overwrites some
            % critical header information 

            header.PatientName       = 'Anonymized';
            header.PatientID         = '000000';
            header.PatientBirthDate  = '';
            header.PatientSex        = '';
            header.PatientAge        = '';
            header.PatientAddress    = '';
            header.OtherPatientIDs   = '';
            header.OtherPatientNames = '';
            header.PatientComments   = '';
            
            header.StudyID                 = '';
            header.StudyDate               = '';
            header.StudyTime               = '';
            header.ReferringPhysicianName  = '';
            header.StudyDescription        = '';
            header.AccessionNumber         = '';
            header.PhysiciansOfRecord      = '';
            header.PerformingPhysicianName = '';
            
            header.SeriesDate        = '';
            header.SeriesTime        = '';
            header.OperatorsName     = '';
            
            header.InstitutionName    = 'Anonymized Institution';
            header.InstitutionAddress = '';
        end

        function header = TemplateDicomHeader(obj, slice, sliceNumber, sliceLocation, edata, volhdr)
            
            % Extract header information from nifti file
            for i = 1:size(edata,1)-1
                s_edata{i}       = strsplit(edata{i},' = ');
                s_edata{i}{1}    = strrep(s_edata{i}{1},newline, '');
                s_edata{i}{1}    = strrep(s_edata{i}{1},char(0), '');

                s_edata{i}{2}    = strrep(s_edata{i}{2},'''', '');

                try
                    numericflag = isnumeric(eval(s_edata{i}{2}));
                catch
                    numericflag = false;
                end

                if numericflag
                    header.(s_edata{i}{1}) = eval(s_edata{i}{2});
                else
                    header.(s_edata{i}{1}) = s_edata{i}{2};
                end
            end

            % Choose between s-form and q-form based on the codes
            if isfield(volhdr.hist, 'sform_code') && volhdr.hist.sform_code > 0
                % Use s-form affine matrix if valid
                % Not sure why z needs to be negated, but this fixes shearing issues
                A = [volhdr.hist.srow_x; volhdr.hist.srow_y; -volhdr.hist.srow_z; 0 0 0 1];

            elseif isfield(volhdr.hist, 'qform_code') && volhdr.hist.qform_code > 0
                % Construct affine matrix from q-form parameters in the NIfTI header
                b = volhdr.hist.quatern_b;
                c = volhdr.hist.quatern_c;
                d = volhdr.hist.quatern_d;
                a = sqrt(1.0 - (b*b + c*c + d*d)); % Ensure normalization of the quaternion
            
                % Rotation matrix
                R = [a*a+b*b-c*c-d*d, 2*b*c-2*a*d, 2*b*d+2*a*c;
                     2*b*c+2*a*d, a*a+c*c-b*b-d*d, 2*c*d-2*a*b;
                     2*b*d-2*a*c, 2*c*d+2*a*b, a*a+d*d-c*c-b*b];
            
                % Scaling factors from pixel dimensions
                R(1,:) = R(1,:) * volhdr.dime.pixdim(2);
                R(2,:) = R(2,:) * volhdr.dime.pixdim(3);
                R(3,:) = R(3,:) * volhdr.dime.pixdim(4);
            
                % Translation vector
                T = [volhdr.hist.qoffset_x; volhdr.hist.qoffset_y; volhdr.hist.qoffset_z];
            
                % Construct affine matrix
                A = [R, T; 0 0 0 1];
            else
                error('No valid q-form or s-form affine transform found.');
            end
    
            % Direction cosines & position parameters
            dircosX = A(1:3,2) / norm(A(1:3,2)); 
            dircosY = A(1:3,3) / norm(A(1:3,3)); 

            voxelCoords   = [sliceNumber-1; 0; 0; 1];
            imagePosition = (A * voxelCoords);

            header.ImagePositionPatient       = imagePosition(1:3);
            header.ImageOrientationPatient    = [dircosX(1); dircosX(2); dircosX(3); dircosY(1); dircosY(2); dircosY(3)];
            header.SliceLocation              = sliceLocation + header.SliceThickness;
            header.AcquisitionDateTime        = datestr(datetime('now'), 'yyyymmddHHMMSS');
            header.InstanceNumber             = sliceNumber;
            header.MediaStorageSOPClassUID    = dicomuid; 
            header.MediaStorageSOPInstanceUID = dicomuid; 
            header.SOPClassUID                = header.MediaStorageSOPClassUID; 
            header.SOPInstanceUID             = header.MediaStorageSOPInstanceUID; 
            header.AcquisitionMatrix          = uint16([0; size(slice,2); size(slice,1); 0]);

        end

    end
end

