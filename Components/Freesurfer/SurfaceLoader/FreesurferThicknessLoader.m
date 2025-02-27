classdef FreesurferThicknessLoader < AComponent
    %FreesurferThicknessLoader loads cortical thickness information
    %from existing Freesurfer segmentation
    
    properties
        SegmentationPathIdentifier
        ThicknessRoundDecimal
        SurfaceIdentifier
    end
    
    methods
        function obj = FreesurferThicknessLoader()
            obj.SegmentationPathIdentifier = 'SegmentationPath';
            obj.ThicknessRoundDecimal      = 2;
            obj.SurfaceIdentifier          = 'thickness';
        end

        function Publish(obj)
  
            obj.AddOptionalInput(obj.SegmentationPathIdentifier, 'PathInformation',true);
            obj.AddOutput(obj.SurfaceIdentifier,                 'Surface');
            if(ispc)
                obj.RequestDependency('UbuntuSubsystemPath','folder');
            end
        end
        function Initialize(obj)
            path = obj.GetDependency('Freesurfer');
            addpath(fullfile(path,'fsfast','toolbox'));
            if(ispc)
                obj.GetDependency('UbuntuSubsystemPath');
               if(system('WHERE bash >nul 2>nul echo %ERRORLEVEL%') == 1)
                   error('If you want to use Freesurfer components on windows, the Windows 10 Ubuntu subsystem is required!');
               else
                   disp('Found ubuntu subsystem on Windows 10!');
               end
            end
        end
        
        function [surf] = Process(obj,optInp)
            freesurferPath = obj.GetDependency('Freesurfer');

            surf = obj.CreateOutput(obj.SurfaceIdentifier);
            if(nargin > 1) %segmentation path exists
                segmentationPath = optInp.Path;
                comPath          = fileparts(obj.ComponentPath);
                segmentationPath = fullfile(comPath,segmentationPath); %create full path
            else
                segmentationPath = uigetdir([],'Please select Freesurfer Segmentation');
                if(isempty(segmentationPath))
                    error('No path selected!');
                end
            end

            if(ispc)
                subsyspath        = DependencyHandler.Instance.GetDependency('UbuntuSubsystemPath');
                pathToLhthickness = resolveWSLSymlink(fullfile(segmentationPath,'surf/lh.thickness'),subsyspath);
                pathToRhthickness = resolveWSLSymlink(fullfile(segmentationPath,'surf/rh.thickness'),subsyspath);
            else
                subsyspath        = '';
                pathToLhthickness = fullfile(segmentationPath,'surf/lh.thickness');
                pathToRhthickness = fullfile(segmentationPath,'surf/rh.thickness');
            end

            lhThickness = fast_read_curv(pathToLhthickness);
            rhThickness = fast_read_curv(pathToRhthickness);

            [lh_pial,rh_pial] = loadFSSurface('pial',segmentationPath,subsyspath);
            
            lh_pial.vertId = ones(size(lh_pial.vert,1),1);
            lh_pial.triId  = ones(size(lh_pial.tri,1),1);
            rh_pial.vertId = 2*ones(size(rh_pial.vert,1),1);
            rh_pial.triId  = 2*ones(size(rh_pial.tri,1),1);

            xfrm_matrices = loadXFRMMatrix(freesurferPath,segmentationPath,GetFullPath(obj.ComponentPath),subsyspath);
            vox2ras       = xfrm_matrices(1:4, :);
            vox2rastkr    = xfrm_matrices(5:8, :);
            tkr2ras       = vox2ras/(vox2rastkr);
    
            surf.Model      = transformPial(mergePials(lh_pial,rh_pial),tkr2ras);

            Annotation      = [lhThickness;rhThickness];
            surf.Annotation = 10^obj.ThicknessRoundDecimal*round(Annotation,obj.ThicknessRoundDecimal);

            % Annotation Label
            sortedAnnot = sort(surf.Annotation);
            for i = 1:length(surf.Annotation)
                names{i} = num2str(sortedAnnot(i)/10^obj.ThicknessRoundDecimal);
            end

            u_identifiers = sortedAnnot;

            [u_identifiers,ia] = unique(u_identifiers);
            names              = names(ia);
            u_colortable       = hot(length(names));

            surf.AnnotationLabel = struct('Name',names','Identifier',num2cell(u_identifiers),'PreferredColor',num2cell(u_colortable,2));

        end
    end
end

