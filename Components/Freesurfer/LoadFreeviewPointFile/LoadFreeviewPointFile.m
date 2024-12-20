classdef LoadFreeviewPointFile < AComponent
    %LoadFreeviewPointFile Load Freesurfer formatted pointset files as
    %electrode locations

    properties
        ElectrodeLocationIdentifier
        LocationDataType
        ElectrodeDefinitionIdentifier
        LocationDefinitionDataType
        InputFilepath char
    end

    methods
        function obj = LoadFreeviewPointFile()
            obj.ElectrodeLocationIdentifier   = 'ElectrodeLocation';
            obj.LocationDataType              = 'ElectrodeLocation';
            obj.ElectrodeDefinitionIdentifier = 'ElectrodeDefinition';
            obj.LocationDefinitionDataType    = 'ElectrodeDefinition';
            obj.InputFilepath                 = '';
        end

        function Publish(obj)
            obj.AddOptionalInput(obj.ElectrodeDefinitionIdentifier, obj.LocationDefinitionDataType);

            obj.AddOutput(obj.ElectrodeLocationIdentifier, obj.LocationDataType);
        end

        function Initialize(obj)
            if(~any(strcmp(superclasses(obj.LocationDataType),'PointSet')))
                error('LocationDataType has to be a subtype of PointSet');
            end
        end

        function elData = Process(obj,varargin)
            elDef  = [];
            elData = obj.CreateOutput(obj.ElectrodeLocationIdentifier);
            if(length(varargin) > 1 && strcmp(varargin{1},obj.ElectrodeDefinitionIdentifier))
                elDef = varargin{2};
            end

            % Use the path given in InputFilepath
            if ~isempty(obj.InputFilepath)
                % working directory is VERA project
                if isAbsolutePath(obj.InputFilepath)
                    [path,file,ext] = fileparts(obj.InputFilepath);
                else
                    [path,file,ext] = fileparts(fullfile(obj.ComponentPath,'..',obj.InputFilepath));
                    path = GetFullPath(path);
                end

                % Open a file load dialog if you can't find the path
                if ~exist(path,'dir')
                    [files,path] = uigetfile('*.dat','Select Data Files','','MultiSelect','on');
                else
                    d = dir(path);
                    % remove hidden files
                    rem = [];
                    for i = 1:length(d)
                        if strcmp(d(i).name(1),'.')
                            rem = [rem, i];
                        end
                    end
                    d(rem) = [];

                    files = {d(:).name};
                end
            % Otherwise use a file dialog
            else
                [files,path] = uigetfile('*.dat','Select Data Files','','MultiSelect','on');
            end

            if ~iscell(files)
                files = {files};
            end

            for i_f = 1:length(files)
                %check if name corresponds to any electrode definitions if
                %they are available
                identifier = i_f;
                el         = importelectrodes(fullfile(path, files{i_f}));
                if(~isempty(elDef))
                    elDefNames = {elDef.Definition.Name};
                    identifier = find(strcmp(files{i_f}(1:end-4), elDefNames),1);
                end
                if(~isempty(identifier))
                    elData.AddWithIdentifier(identifier,el);
                else
                    [idx,~] = listdlg('PromptString',{'Select Corresponding Definition','for',files{i_f}},'SelectionMode','single','ListString',elDefNames);
                    if(~isempty(idx))
                        if(any(elData.DefinitionIdentifier == idx))
                            answ = questdlg('Do you want to override the existing electrode Locations?','Override?','yes','no');
                            if(strcmp(answ,'no'))
                                continue;
                            end
                            elData.RemoveWithIdentifier(idx);
                        end

                        elData.AddWithIdentifier(idx,el);
                    end
                end
            end
        end
    end
end

