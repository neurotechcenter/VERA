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

    end
end

