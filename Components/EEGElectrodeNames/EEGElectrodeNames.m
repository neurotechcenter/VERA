classdef EEGElectrodeNames < AComponent
    %EEGElectrodeNames Component to add EEG electrode names

    properties
        ElectrodeDefinitionIdentifier % Electrode Definitions
        ElectrodeLocationIdentifier   % Electrode Locations
        EEGNamesIdentifier            % EEG Names 
        FileTypeWildcard char         % Wildcard Definition
        InputFilepath char            % Load file path
        SkipGUI
    end

    properties
        EEGNames
        % columnNames
        internalDefinitions
    end
    
    methods
        function obj = EEGElectrodeNames()
            obj.ElectrodeDefinitionIdentifier = 'ElectrodeDefinition';
            obj.ElectrodeLocationIdentifier   = 'ElectrodeLocation';
            obj.EEGNamesIdentifier            = 'EEGNames';
            obj.FileTypeWildcard              = '*.*';
            obj.EEGNames                      = [];
            obj.internalDefinitions           = [];
            obj.InputFilepath                 = '';
            obj.SkipGUI                       = 0;
        end

        function Publish(obj)
            % Publish - Adds an Output for the EEGNames Data
            % See also AComponent.Publish, ElectrodeDefinition
            obj.AddInput(obj.ElectrodeDefinitionIdentifier, 'ElectrodeDefinition');
            obj.AddInput(obj.ElectrodeLocationIdentifier,   'ElectrodeLocation');
            obj.AddOutput(obj.EEGNamesIdentifier,           'ElectrodeDefinition'); % This is a type, not a variable name

            obj.RequestDependency('BCI2000mex','folder');
        end

        function Initialize(obj)
            bci2000mex_path = obj.GetDependency('BCI2000mex');
            addpath(genpath(bci2000mex_path));

            obj.internalDefinitions = obj.EEGNames;
            obj.EEGNames            = [];
        end

        function [out] = Process(obj,eDef,eLocs)

            elNameKey  = [];
            answer     = '';
            NeedDialog = 1;

            % if an input file is specified, use it and disable the file
            % selection dialog
            if ~isempty(obj.InputFilepath)
                % working directory is VERA project
                if isAbsolutePath(obj.InputFilepath)
                    [path,file,ext] = fileparts(obj.InputFilepath);
                else
                    [path,file,ext] = fileparts(fullfile(obj.ComponentPath,'..',obj.InputFilepath));
                    path = GetFullPath(path);
                end

                if strcmp(ext,'.dat') && exist(fullfile(path,[file,ext]),'file')
                    answer     = 'BCI2000';
                    NeedDialog = 0;
                elseif strcmp(ext,'.xlsx') && exist(fullfile(path,[file,ext]),'file')
                    answer     = 'Excel';
                    NeedDialog = 0;
                end
            end

            % dialog box asking bci2000 file or excel file
            if isempty(answer)
                quest    = 'Load BCI2000 data file and generate electrode key? Or load excel file with pre-determined electrode key?';
                dlgtitle = 'Electrode Names Key';
                btn1     = 'BCI2000';
                btn2     = 'Excel';
                answer = questdlg(quest,dlgtitle,btn1,btn2,btn1);
            end
    
            % if a BCI200 data file is selected
            if strcmp(answer,'BCI2000')
                if NeedDialog
                    [file,path] = uigetfile(obj.FileTypeWildcard,'Please select BCI2000 data file');
                end

                if isequal(file,0)
                    error([obj.EEGNamesIdentifier ' selection aborted']);
                else
                    [signal,states,bci2000parameters] = load_bcidat(fullfile(path,file));
                end
                
                if ~isempty(bci2000parameters.ChannelNames.Value)
                    eeg_elNames = bci2000parameters.ChannelNames.Value; % comes from amplifier via BCI2000
                else
                    for i = 1:size(signal,2)
                        eeg_elNames{i} = ['Ch', num2str(i)];
                    end
                end
                
                for i = 1:size(eLocs.Location,1)
                    VERA_shankNames_long{i,1} = eDef.Definition(eLocs.DefinitionIdentifier(i)).Name;
                    VERA_numEl_long(i)        = find(find(eLocs.DefinitionIdentifier == eLocs.DefinitionIdentifier(i)) == i);

                    VERA_elNames{i,1} = [VERA_shankNames_long{i,1}, num2str(VERA_numEl_long(i))];
                end

                VERA_shankNames = unique(VERA_shankNames_long,'stable');

                for i = 1:size(eDef.Definition,1)
                    defNames{i,1} = eDef.Definition(i).Name;
                end

                for i = 1:length(VERA_shankNames)
                    idx = find(strcmp(defNames, VERA_shankNames{i}));
                    VERA_numEl(i) = eDef.Definition(idx).NElectrodes;
                end

                [elNameKey] = GetElNameKey(obj,VERA_elNames,VERA_shankNames,VERA_numEl,eeg_elNames);

            % if an excel file is selected
            elseif strcmp(answer,'Excel')
                if NeedDialog
                    [file,path] = uigetfile(obj.FileTypeWildcard,'Please select Excel file with electrode names key');
                end

                if isequal(file,0)
                    error([obj.EEGNamesIdentifier ' selection aborted']);
                else
                    T = readtable(fullfile(path,file));
                    
                    eeg_elNames  = T.EEGNames;
                    VERA_elNames = T.VERANames;
                    eeg_elNums   = T.EEGNumbers;
                    VERA_elNums  = T.VERANumbers;

                    % Need the number of contacts identified with VERA to
                    % match the number of rows in the excel table
                    numVERAelecs = size(eLocs.DefinitionIdentifier,1);
                    if numVERAelecs ~= size(VERA_elNums,1)
                        error('Number of rows in table does not match number of identified contacts in VERA');
                    end

                    % Format table contents to channel names are strings
                    % and channel numbers are doubles
                    elNameKey = struct('Select',false,'EEGNames',[],'VERANames',[],'EEGNumbers',[],'VERANumbers',[]);
                    for i = 1:size(eeg_elNames,1)
                        if isnumeric(eeg_elNames(i))
                            eeg_elNames_cell(i,1) = cellstr(num2str(eeg_elNames(i)));
                        else
                            eeg_elNames_cell(i,1) = eeg_elNames(i);
                        end
                        if isnumeric(VERA_elNames(i))
                            VERA_elNames_cell(i,1) = cellstr(num2str(VERA_elNames(i)));
                        else
                            VERA_elNames_cell(i,1) = VERA_elNames(i);
                        end
                        if ~isnumeric(eeg_elNums(i))
                            eeg_elNums(i)       = strrep(eeg_elNums(i), '"',  '');
                            eeg_elNums(i)       = strrep(eeg_elNums(i), '''', '');
                            eeg_elNums_dbl(i,1) = str2double(eeg_elNums(i));
                        else
                            eeg_elNums_dbl(i,1) = eeg_elNums(i);
                        end
                        if ~isnumeric(VERA_elNums(i))
                            VERA_elNums(i)       = strrep(VERA_elNums(i), '"',  '');
                            VERA_elNums(i)       = strrep(VERA_elNums(i), '''', '');
                            VERA_elNums_dbl(i,1) = str2double(VERA_elNums(i));
                        else
                            VERA_elNums_dbl(i,1) = VERA_elNums(i);
                        end

                        elNameKey(i).Select      = false;
                        elNameKey(i).EEGNames    = eeg_elNames_cell{i,1};
                        elNameKey(i).VERANames   = VERA_elNames_cell{i,1};
                        elNameKey(i).EEGNumbers  = eeg_elNums_dbl(i,1);
                        elNameKey(i).VERANumbers = VERA_elNums_dbl(i,1);
                    end
                end
            else
                error([obj.EEGNamesIdentifier ' selection aborted']);
            end
        
            obj.internalDefinitions = elNameKey;

            out = obj.CreateOutput(obj.EEGNamesIdentifier);
            obj.EEGNames = obj.internalDefinitions;
            
            % visualize
            if ~obj.SkipGUI
                h      = figure('Name',obj.Name);
                elView = EEGNamesView(h,obj.EEGNames);
                elView.SetComponent(obj);
                uiwait(h);
            end
            
            % Strips out the Select field name from the structure
            EEGNames_excludeSelected = struct();
            fields = fieldnames(obj.EEGNames);
            for i = 1:length(fields)
                fieldName = fields{i};
                for j = 1:size(obj.EEGNames,2)
                    if ~strcmp(fieldName, 'Select')
                        EEGNames_excludeSelected(j).(fieldName) = obj.EEGNames(j).(fieldName);
                    end
                end
            end

            out.Definition = EEGNames_excludeSelected;

        end

        function [elNameKey] = GetElNameKey(obj,VERA_elNames,VERA_shankNames,VERA_numEl,eeg_elNames)
            % The goal is to force the VERA channel names (either manually
            % created or from ROSA) to conform to the channel names
            % recorded in a BCI2000 data file (usually from the amplifier)

            % clean up EEG names
            eeg_elNames_normalized = EEGNameNormalization(obj,eeg_elNames);

            % get the various Rule functions from Components/EEGElectrodeNames
            path = fileparts(mfilename('fullpath'));
            d = dir(path);
            
            % generate list of rule functions
            iter = 1;
            for i = 1:length(d)
                if ~isempty(strfind(d(i).name,'Rule')) && ~isempty(strfind(d(i).name,'.m'))
                    rulelist{iter,1} = d(i).name;
                    iter = iter + 1;
                end
            end

            % Run Rules
            for i = 1:length(rulelist)
                VERA_elNames_normalized{i} = feval(rulelist{i}(1:end-2),VERA_shankNames,VERA_numEl,eeg_elNames);

                % Get intersection of VERA and EEG names, determine performance
                % based on number of empty cells
                [elNameKey_holder{i},emptyctr(i)] = ElNameIntersection(obj, VERA_elNames, VERA_elNames_normalized{i}, eeg_elNames, eeg_elNames_normalized);

            end

            % Pick the best method to move forward with
            [~, bestmethod] = min(emptyctr);

            % Result
            elNameKey = elNameKey_holder{bestmethod};

        end

        function eeg_elNames_normalized = EEGNameNormalization(obj,eeg_elNames)
            % normalize EEG electrode names

            % Capitalize
            eeg_elNames_normalized  = upper(eeg_elNames);

            % Remove spaces
            for i = 1:length(eeg_elNames_normalized)
                idx = strfind(eeg_elNames_normalized{i},' ');
                eeg_elNames_normalized{i}(idx) = [];
            end

        end

        function [elNameKey,emptyctr] = ElNameIntersection(obj, VERA_elNames, VERA_elNames_normalized, eeg_elNames, eeg_elNames_normalized)
            % Create electrode naming key

            % Find intersection
            [~,eeg_idx,vera_idx] = intersect(eeg_elNames_normalized,VERA_elNames_normalized,'stable');
            
            % Table sorted in order of VERA electrodes
            hldr = cell(size(VERA_elNames,1),4);
            for i = 1:size(VERA_elNames)
                hldr(i,:) = {'','','',''};
            end

            % EEG Names
            hldr(vera_idx,1) = eeg_elNames(eeg_idx);

            % VERA Names
            hldr(:,2) = VERA_elNames;

            % EEG Numbers
            for i = 1:length(vera_idx)
                % hldr{vera_idx(i),3} = num2str(eeg_idx(i));
                hldr{vera_idx(i),3} = eeg_idx(i);
            end

            % VERA Numbers
            for i = 1:length(VERA_elNames)
                % hldr{i,4} = num2str(i);
                hldr{i,4} = i;
            end

            for i = 1:size(hldr,1)
                elNameKey(i) = struct('Select',false,'EEGNames',hldr{i,1},'VERANames',hldr{i,2},'EEGNumbers',hldr{i,3},'VERANumbers',hldr{i,4});
            end

            % Empty counter (number of missed electrodes) can be used to
            % compare performance
            emptyctr = 0;
            for i = 1:length(elNameKey)
                if isempty(elNameKey(i).EEGNames)
                    emptyctr = emptyctr + 1;
                end
            end
            
        end
        
    end

end

