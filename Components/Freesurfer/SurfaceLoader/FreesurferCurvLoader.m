classdef FreesurferCurvLoader < AComponent
    %FreesurferSurfaceLoader Loads Curvature Information
    %from existing Freesurfer segmentation
    
    properties
        SurfaceIdentifier
        SegmentationPathIdentifier
    end
    
    
    methods

        
        function obj = FreesurferCurvLoader()
            obj.SegmentationPathIdentifier='SegmentationPath';
            obj.SurfaceIdentifier='curv';
        end

        function Publish(obj)
  
            obj.AddOptionalInput(obj.SegmentationPathIdentifier,'PathInformation',true);
            obj.AddOutput(obj.SurfaceIdentifier,'Surface');
            if(ispc)
                obj.RequestDependency('UbuntuSubsystemPath','folder');
            end
        end
        function Initialize(obj)
            path=obj.GetDependency('Freesurfer');
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
            surf=obj.CreateOutput(obj.SurfaceIdentifier);
            if(nargin > 1) %segmentation path exists
                segmentationPath=optInp.Path;
                comPath=fileparts(obj.ComponentPath);
                segmentationPath=fullfile(comPath,segmentationPath); %create full path
            else
                segmentationPath=uigetdir([],'Please select Freesurfer Segmentation');
                if(isempty(segmentationPath))
                    error('No path selected!');
                end
            end
            if(ispc)
                subsyspath=DependencyHandler.Instance.GetDependency('UbuntuSubsystemPath');
                pathToLhcurv=resolveWSLSymlink(fullfile(segmentationPath,'surf/lh.curv'),subsyspath);
            else
                pathToLhcurv=fullfile(segmentationPath,'surf/lh.curv');
                subsyspath='';
            end
                [a,b]=fast_read_curv(pathToLhcurv);
                [lsph,rsph]=loadFSSurface('pial',segmentationPath,subsyspath);
                lsph.vertId=ones(size(lsph.vert,1),1);
                lsph.triId=ones(size(lsph.tri,1),1);
                surf.Model=lsph;
                surf.Annotation=a;

        end
    end
end

