classdef FreesurferModelGeneration < AComponent
    %FreesurferModelGeneration Run Freesurfer segmentation within VERA
    
    properties
        MRIIdentifier %Input MRI Data Identifier
        SurfaceIdentifier %Output Surface Data Identifier
        SphereIdentifier %Output Sphere Surface Volume Identifier (will start with L_ and R_ )
        AnnotationType
        SegmentationPathIdentifier
    end
     properties (Dependent, Access = protected)
        LeftSphereIdentifier
        RightSphereIdentifier
    end
    
    methods
        
        function obj = FreesurferModelGeneration()
            obj.MRIIdentifier='MRI';
            obj.SurfaceIdentifier='Surface';
            obj.SphereIdentifier='Sphere';
            obj.AnnotationType='aparc';
            obj.SegmentationPathIdentifier='SegmentationPath';
        end
        
        function value=get.LeftSphereIdentifier(obj)
            value=['L_' obj.SphereIdentifier];
        end
        function value=get.RightSphereIdentifier(obj)
            value=['R_' obj.SphereIdentifier];
        end
        
        function Publish(obj)
            obj.AddInput(obj.MRIIdentifier,'Volume');
            obj.AddOutput(obj.SurfaceIdentifier,'Surface');
            obj.AddOutput(obj.LeftSphereIdentifier,'Surface');
            obj.AddOutput(obj.RightSphereIdentifier,'Surface');
            obj.AddOutput(obj.SegmentationPathIdentifier,'PathInformation');
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
                   disp('This Component requires GUI Access to freeview, make sure you can run freeview from the Linux subsystem (requires Xserver installed on windows)');
               end
            end
            
        end
        
        function [surf,lsphere,rsphere,pathInfo] = Process(obj,mri)
                 segmentationFolder=obj.ComponentPath;
                 mri_path=GetFullPath(mri.Path);
                freesurferPath=obj.GetDependency('Freesurfer');
                recon_script=fullfile(fileparts(fileparts(mfilename('fullpath'))),'/scripts/importdata_recon-all.sh');
                segmentationPath=fullfile(segmentationFolder,'Segmentation');
                if(~exist(segmentationPath,'dir') || (exist(segmentationPath,'dir') && strcmp(questdlg('Found an Existing Segmentation Folder! Do you want to rerun the Segmentation?','Rerun Segmentation?','Yes','No','No'),'Yes')))
                    disp('Running Freesurfer segmentation, this might take up to 24h, get a coffee...');
                    if(exist(segmentationPath,'dir')) 
                        rmdir(segmentationPath,'s'); 
                    end
                    if(ispc)
                        subsyspath=obj.GetDependency('UbuntuSubsystemPath');
                        w_recon_script=convertToUbuntuSubsystemPath(recon_script,subsyspath);
                        w_freesurferPath=convertToUbuntuSubsystemPath(freesurferPath,subsyspath);
                        w_segmentationFolder=convertToUbuntuSubsystemPath(segmentationFolder,subsyspath);
                        w_mripath=convertToUbuntuSubsystemPath(mri_path,subsyspath);
                        systemWSL(['chmod +x ''' w_recon_script ''''],'-echo');
                        shellcmd=['''' w_recon_script ''' ''' w_freesurferPath ''' ''' ...
                        w_segmentationFolder ''' ' ...
                        'Segmentation ''' w_mripath ''''];
                        systemWSL(shellcmd,'-echo');
                    else
                        system(['chmod +x ''' recon_script ''''],'-echo');
                        shellcmd=[recon_script ' ''' freesurferPath ''' ''' ...
                        segmentationFolder ''' ' ...
                        'Segmentation ''' mri_path ''''];
                        system(shellcmd,'-echo');
                    end
                end
                
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
                pathInfo=obj.CreateOutput(obj.SegmentationPathIdentifier);
                pathInfo.Path=segmentationPath;

        end
    end
end

