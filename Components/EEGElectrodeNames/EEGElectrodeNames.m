classdef EEGElectrodeNames < AComponent
    %EEGElectrodeNames Component to add EEG electrode names

    properties
        ElectrodeDefinitionIdentifier % Electrode Definitions
        ElectrodeLocationIdentifier   % Electrode Locations
        EEGNamesIdentifier            % EEG Names
        FileTypeWildcard char         % Wildcard Definition
    end

    properties
        EEGNames
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

            % dialog box asking bci2000 file or excel file
            quest    = 'Load BCI2000 data file and generate electrode key? Or load excel file with pre-determined electrode key?';
            dlgtitle = 'Electrode Names Key';
            btn1     = 'BCI2000';
            btn2     = 'Excel';
            answer = questdlg(quest,dlgtitle,btn1,btn2,btn1);

            if strcmp(answer,'BCI2000')
                [file,path]=uigetfile(obj.FileTypeWildcard,'Please select BCI2000 data file');
                if isequal(file,0)
                    error([obj.EEGNamesIdentifier ' selection aborted']);
                else
                    [~,~,bci2000parameters] = load_bcidat(fullfile(path,file));
                end
    
                VERA_elNames = eLocs.GetElectrodeNames(eDef);
                eeg_elNames  = bci2000parameters.ChannelNames.Value; % comes from amplifier via BCI2000
    
                elNameKey = GetElNameKey(obj,VERA_elNames,eeg_elNames);

            elseif strcmp(answer,'Excel')
                [file,path]=uigetfile(obj.FileTypeWildcard,'Please select Excel file with electrode names key');
                if isequal(file,0)
                    error([obj.EEGNamesIdentifier ' selection aborted']);
                else
                    T = readtable(fullfile(path,file));
                    
                    eeg_elNames  = T.Var2(2:end);
                    VERA_elNames = T.Var8(2:end);

                    for i = 1:size(eeg_elNames,1)
                        elNameKey(i) = struct('EEGNames',eeg_elNames{i,1},'VERANames',VERA_elNames{i,1});
                    end
                end
            end
        
            obj.internalDefinitions = elNameKey;

            out = obj.CreateOutput(obj.EEGNamesIdentifier);
            % visualize
            if(isempty(obj.EEGNames))
                obj.EEGNames = obj.internalDefinitions;
                
                h      = figure('Name',obj.Name);
                elView = EEGNamesView('Parent',h);
                elView.SetComponent(obj);
                uiwait(h);
            end
            
            out.Definition = obj.EEGNames;

        end

        function [elNameKey] = GetElNameKey(obj,VERA_elNames,eeg_elNames)
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
                VERA_elNames_normalized{i} = feval(rulelist{i}(1:end-2),VERA_elNames,eeg_elNames);

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

            % VERA electrode locations that were actually recorded from
            VERA_elNames_recorded = VERA_elNames(vera_idx);

            % elNameKey should relate EEG electrode names to original VERA electrode names
            hldr            = cell(size(eeg_elNames,1),2);
            for i = 1:size(eeg_elNames)
                hldr(i,:) = {'',''};
            end
            hldr(:,1)       = eeg_elNames;
            hldr(eeg_idx,2) = VERA_elNames_recorded;

            for i = 1:size(hldr,1)
                elNameKey(i) = struct('EEGNames',hldr{i,1},'VERANames',hldr{i,2});
            end

            % Empty counter (number of missed electrodes) can be used to
            % compare performance
            emptyctr = 0;
            for i = 1:length(elNameKey)
                if isempty(elNameKey(i).VERANames)
                    emptyctr = emptyctr + 1;
                end
            end
        end
        
    end

end

