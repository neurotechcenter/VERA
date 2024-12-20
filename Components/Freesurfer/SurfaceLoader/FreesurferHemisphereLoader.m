classdef FreesurferHemisphereLoader < AComponent
    %FreesurferSurfaceLoader Loads surfaces as individual hemispheres
    %from existing Freesurfer segmentation
    
    properties
        SurfaceIdentifier
        AnnotationType
        SegmentationPathIdentifier
        SurfaceType
    end
    
    properties (Dependent, Access = protected)
        LeftSurfaceIdentifier
        RightSurfaceIdentifier
    end
    
    methods
        function value=get.LeftSurfaceIdentifier(obj)
            value=['L_' obj.SurfaceIdentifier];
        end
        function value=get.RightSurfaceIdentifier(obj)
            value=['R_' obj.SurfaceIdentifier];
        end
        
        function obj = FreesurferHemisphereLoader()
            obj.SurfaceIdentifier='Surface';
            obj.SurfaceType='pial';
            obj.AnnotationType='aparc';
            obj.SegmentationPathIdentifier='SegmentationPath';
        end

        function Publish(obj)
  
            obj.AddOutput(obj.LeftSurfaceIdentifier,'Surface');
            obj.AddOutput(obj.RightSurfaceIdentifier,'Surface');

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
        
        function [lsurf, rsurf] = Process(obj,optInp)

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
            else
                subsyspath='';
            end
            lsurf=obj.CreateOutput(obj.LeftSurfaceIdentifier);
            [lsph,rsph]=loadFSSurface(obj.SurfaceType,segmentationPath,subsyspath);
            lsph.vertId=ones(size(lsph.vert,1),1);
            lsph.triId=ones(size(lsph.tri,1),1);
            
            
            rsph.triId=2*ones(size(rsph.tri,1),1);
            rsph.vertId=2*ones(size(rsph.vert,1),1);

            [~,llabel,lct]=read_annotation(fullfile(segmentationPath,['label/lh.' obj.AnnotationType '.annot']));
    
            lsurf.Model=lsph;
            lsurf.Annotation=llabel;
            lsurf.AnnotationLabel=struct('Name',lct.struct_names,'Identifier',num2cell(lct.table(:,5)),'PreferredColor',num2cell(lct.table(:,1:3)/255,2));
            
            rsurf=obj.CreateOutput(obj.RightSurfaceIdentifier);
            [~,rlabel,rct]=read_annotation(fullfile(segmentationPath,['label/rh.' obj.AnnotationType '.annot']));

            rsurf.Annotation=rlabel;
            rsurf.Model=rsph;
            rsurf.AnnotationLabel=struct('Name',rct.struct_names,'Identifier',num2cell(rct.table(:,5)),'PreferredColor',num2cell(rct.table(:,1:3)/255,2));

        end
    end
end

