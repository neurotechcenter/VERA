classdef FreesurferSurfaceLoader < AComponent
    %FreesurferSurfaceLoader Input Component: Loads Information from Freesurfer segmentation
    
    properties
        SurfaceIdentifier
        SphereIdentifier
        AnnotationType
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
            obj.AnnotationType='annot';
        end
        function Publish(obj)
            obj.AddOutput(obj.SurfaceIdentifier,'Surface');
            obj.AddOutput(obj.LeftSphereIdentifier,'Surface');
            obj.AddOutput(obj.RightSphereIdentifier,'Surface');
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
        
        function [surf,lsphere,rsphere] = Process(obj)
            [segmentationPath]=uigetdir([],['Please select ' obj.SurfaceIdentifier]);
            freesurferPath=obj.GetDependency('Freesurfer');
            [surf_model,lsphere_model,rsphere_model]=loadFSModelFromSubjectDir(freesurferPath,segmentationPath,GetFullPath(obj.ComponentPath),obj.AnnotationType);
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

        end
    end
end

