classdef FreesurferModelGeneration < AComponent
    %FreesurferModelGeneration Run Freesurfer segmentation within VERA
    
    properties
        MRIIdentifier %Input MRI Data Identifier
        SurfaceIdentifier %Output Surface Data Identifier
        SphereIdentifier %Output Sphere Surface Volume Identifier (will start with L_ and R_ )
        AnnotationType
        SegmentationPathIdentifier
        SurfaceType
        MinFreeMemoryGB %Minimum available system memory (GB) required before starting Freesurfer segmentation
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
            obj.SurfaceType='pial';
            obj.MinFreeMemoryGB=16;
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
            if ~isdeployed
                addpath(fullfile(path,'matlab'));
            end
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
                    obj.CheckAvailableMemory();
                    if(ispc)
                        subsyspath=obj.GetDependency('UbuntuSubsystemPath');
                        w_recon_script=convertToUbuntuSubsystemPath(recon_script,subsyspath);
                        w_freesurferPath=convertToUbuntuSubsystemPath(freesurferPath,subsyspath);
                        w_segmentationFolder=convertToUbuntuSubsystemPath(segmentationFolder,subsyspath);
                        w_mripath=convertToUbuntuSubsystemPath(mri_path,subsyspath);
                        [status,cmdout]=systemWSL(['chmod +x ''' w_recon_script ''''],'-echo');
                        if status ~= 0
                            error(['Error Generating Freesurfer Segmentation: ',cmdout]);
                        end
                        shellcmd=['''' w_recon_script ''' ''' w_freesurferPath ''' ''' ...
                        w_segmentationFolder ''' ' ...
                        'Segmentation ''' w_mripath ''''];
                        [status,cmdout]=systemWSL(shellcmd,'-echo');
                        if status ~= 0
                            error(['Error Generating Freesurfer Segmentation: ',cmdout]);
                        end
                    else
                        [status,cmdout]=system(['chmod +x ''' recon_script ''''],'-echo');
                        if status ~= 0
                            error(['Error Generating Freesurfer Segmentation: ',cmdout]);
                        end
                        shellcmd=[recon_script ' ''' freesurferPath ''' ''' ...
                        segmentationFolder ''' ' ...
                        'Segmentation ''' mri_path ''''];
                        [status,cmdout]=system(shellcmd,'-echo');
                        if status ~= 0
                            error(['Error Generating Freesurfer Segmentation: ',cmdout]);
                        end
                    end
                end
                
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
                pathInfo=obj.CreateOutput(obj.SegmentationPathIdentifier);
                [~,b]=fileparts(obj.ComponentPath);
                pathInfo.Path=fullfile('./',b,'Segmentation');

        end

        function CheckAvailableMemory(obj)
            freeGB=getAvailableMemoryGB();
            if isnan(freeGB)
                warning('Could not determine available system memory before starting Freesurfer segmentation.');
                return;
            end
            if freeGB < obj.MinFreeMemoryGB
                warning(['Only %.1f GB of memory is available, but Freesurfer segmentation typically needs at ' ...
                    'least %.1f GB free to avoid being killed by the OS partway through a multi-hour run. ' ...
                    'Close other applications (browsers, virtual machines, etc.) to free up memory if this fails.'], ...
                    freeGB, obj.MinFreeMemoryGB);
            end
        end
    end
end

