classdef FreesurferSurfaceLoader < AComponent
    %FreesurferSurfaceLoader combines pial into a single surface combining
    %both hemispheres and loads spherical maps
    
    properties
        SurfaceIdentifier
        SphereIdentifier
        AnnotationType
        SegmentationPathIdentifier
        SurfaceType
        LoadSphere
    end
    
    properties (Dependent, Access = protected)
        LeftSphereIdentifier
        RightSphereIdentifier
    end
    
    methods
        function value=get.LeftSphereIdentifier(obj)
            value=['L_' obj.SphereIdentifier];
        end
        function value=get.RightSphereIdentifier(obj)
            value=['R_' obj.SphereIdentifier];
        end
        
        function obj = FreesurferSurfaceLoader()
            obj.SurfaceIdentifier='Surface';
            obj.SphereIdentifier='Sphere';
            obj.SurfaceType='pial';
            obj.AnnotationType='aparc';
            obj.SegmentationPathIdentifier='SegmentationPath';
            obj.LoadSphere=1;
        end
        function Publish(obj)
            obj.AddOutput(obj.SurfaceIdentifier,'Surface');
            if(obj.LoadSphere)
                obj.AddOutput(obj.LeftSphereIdentifier,'Surface');
                obj.AddOutput(obj.RightSphereIdentifier,'Surface');
            end
            obj.AddOptionalInput(obj.SegmentationPathIdentifier,'PathInformation',true);
            obj.RequestDependency('Freesurfer','folder');
            if(ispc)
                obj.RequestDependency('UbuntuSubsystemPath','folder');
            end
        end
        function Initialize(obj)
            path=obj.GetDependency('Freesurfer');
            addpath(fullfile(path,'matlab'));
            if(ispc)
                obj.GetDependency('UbuntuSubsystemPath');
               if(system('WHERE bash >nul 2>nul echo %ERRORLEVEL%') == 1)
                   error('If you want to use Freesurfer components on windows, the Windows 10 Ubuntu subsystem is required!');
               else
                   disp('Found ubuntu subsystem on Windows 10!');
               end
            end
        end
        
        function varargout = Process(obj,optInp)

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

            freesurferPath=obj.GetDependency('Freesurfer');
            if(obj.LoadSphere)
                [surf_model,lsphere_model,rsphere_model]=loadFSModelFromSubjectDir(freesurferPath,segmentationPath,GetFullPath(obj.ComponentPath),obj.AnnotationType,obj.SurfaceType);
                surf=obj.CreateOutput(obj.SurfaceIdentifier);
                surf.Model=surf_model.Model;
                surf.Annotation=surf_model.Annotation;
                surf.AnnotationLabel=surf_model.AnnotationLabel;
                
    
                lsphere=obj.CreateOutput(obj.LeftSphereIdentifier);
                lsphere.Model=lsphere_model.Model;
                lsphere.Annotation=lsphere_model.Annotation;
                lsphere.AnnotationLabel=lsphere_model.AnnotationLabel;
    
    
                rsphere=obj.CreateOutput(obj.RightSphereIdentifier);
                rsphere.Model=rsphere_model.Model;
                rsphere.Annotation=rsphere_model.Annotation;
                rsphere.AnnotationLabel=rsphere_model.AnnotationLabel;
                varargout{1}=surf;
                varargout{2}=lsphere;
                varargout{3}=rsphere;
            else
                surf_model=loadFSModelFromSubjectDir(freesurferPath,segmentationPath,GetFullPath(obj.ComponentPath),obj.AnnotationType,obj.SurfaceType);
                surf=obj.CreateOutput(obj.SurfaceIdentifier);
                surf.Model=surf_model.Model;
                surf.Annotation=surf_model.Annotation;
                surf.AnnotationLabel=surf_model.AnnotationLabel;
                varargout{1}=surf;
    
            end

        end
    end
end

