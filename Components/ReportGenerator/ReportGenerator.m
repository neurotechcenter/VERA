classdef ReportGenerator < AComponent
    %ReportGenerator Generates a project for the Neurotechcenter ReportGenerator

    properties
        ImageIdentifier
        SurfaceIdentifier
        ElectrodeDefinitionIdentifier
        ElectrodeLocationIdentifier
    end

    methods
        function obj = ReportGenerator()
            obj.ImageIdentifier               = 'MRI';
            obj.SurfaceIdentifier             = 'Surface';
            obj.ElectrodeDefinitionIdentifier = 'ElectrodeDefinition';
            obj.ElectrodeLocationIdentifier   = 'ElectrodeLocation';
        end

        function Publish(obj)
            obj.AddInput(obj.ImageIdentifier,               'Volume');
            obj.AddInput(obj.SurfaceIdentifier,             'Surface');
            obj.AddInput(obj.ElectrodeDefinitionIdentifier, 'ElectrodeDefinition');
            obj.AddInput(obj.ElectrodeLocationIdentifier,   'ElectrodeLocation');

            obj.RequestDependency('ReportGenerator','folder');
        end

        function Initialize(obj)
            addpath(obj.GetDependency('ReportGenerator'));
        end

        function [] = Process(obj,image,surf,elDef,eLocs)
            tempPath     = obj.GetTempPath();
            [~,randName] = fileparts(tempname);
            delPath      = fullfile(tempPath,randName);
            path         = fullfile(delPath,'Report');

            %path=uigetdir([],'Select output path, generates a ReportGenerator Project');
            cortex = surf.Model;
            ix     = 1;
            cmapstruct=struct('basecol',[0.7 0.7 0.7],'fading',1,'enablecolormap',1,'enablecolorbar',1,'color_bar_ticks',4,'cmap',jet(64),...
                'ixg2',9,'ixg1',-9,'cmin',0,'cmax',0);

            viewstruct.what2view    = {'brain' 'electrodes'};
            viewstruct.viewvect     = [270 0];
            viewstruct.lightpos     = [-150 0 0];
            viewstruct.material     = 'dull';
            viewstruct.enablelight  = 1;
            viewstruct.enableaxis   = 0;
            viewstruct.lightingtype = 'gouraud';

            tala = struct('electrodes',eLocs.Location,'activations',zeros(size(eLocs.Location,1),1),'trielectrodes',eLocs.Location);

            vcontribs       = [];
            annotation      = surf.Annotation;
            annotationlabel = surf.AnnotationLabel;

            mkdir(fullfile(path,'IMAGING'));
            save(fullfile(path,'IMAGING','brain.mat'),'cortex','ix','tala','viewstruct','cmapstruct','vcontribs','annotation','annotationlabel');
            mkdir(fullfile(path,'IMAGING','NIfTI','MRI'));

            RAS_img = image.GetRasSlicedVolume();
            RAS_img.SaveNiiToPath(fullfile(path,'IMAGING','NIfTI','MRI',[obj.ImageIdentifier '.img']));

            compPath = fullfile(path,'IMAGING','Electrodes');
            mkdir(compPath);

            for i = 1:length(elDef.Definition)
                str = '\n';
                if exist('eLocs','var')
                    currLocs = find(eLocs.DefinitionIdentifier == i);
                    for l = 1:length(currLocs)
                        str = [str num2str(eLocs.Location(currLocs(l),:)) '\n'];
                    end
                    numeDefEls = length(currLocs);
                else
                    numeDefEls = 0;
                end
                str = [str 'info \nnumpoints ' num2str(numeDefEls) '\nuseRealRAS 1'];

                wayptfileIds{i} = [compPath '/' regexprep(regexprep(elDef.Definition(i).Name,' +','_'),'[<>:"/\|?*]','_${num2str(cast($0,''uint8''))}') '.dat'];
                fileID = fopen(wayptfileIds{i},'w');
                fprintf(fileID,str);
                fclose(fileID);


            end

            % Run the report generator
            outpptxpath = runGeneratorExternal(path);

            % Save powerpoint file
            % if ~isempty(outpptxpath) && exist(outpptxpath,'file')
            %     [resfile,resdir] = uiputfile([fileparts(outpptxpath) '.pptx']);
            %     copyfile(outpptxpath,fullfile(resdir,resfile),'f');
            % else
            %     error('No report generated!');
            % end

            % create output file in DataOutput folder (default behavior)
            if ~isempty(outpptxpath) && exist(outpptxpath,'file')
                path     = fullfile(obj.ComponentPath,'..','DataOutput');
                [~,file] = fileparts(outpptxpath);

                % convert spaces to underscores
                file = replace(file,' ','_');
    
                % create save folder if it doesn't exist
                if ~isfolder(path)
                    mkdir(path)
                end
        
                [resfile,resdir] = uiputfile(fullfile(path,[file,'.pptx']));
                copyfile(outpptxpath,fullfile(resdir,resfile),'f');
            else
                error('No report generated!');
            end

            % Popup stating where file was saved
            message    = {'File saved as:',GetFullPath(fullfile(resdir,resfile))};
            msgBoxSize = [350, 125];
            obj.VERAMessageBox(message,msgBoxSize);

            rmdir(delPath,'s');
        end
    end
end

