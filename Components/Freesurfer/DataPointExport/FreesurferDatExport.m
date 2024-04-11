classdef FreesurferDatExport < AComponent
    %FreesurferDatExport Exports electrode locations to Freesurfer pointset
    %format
    properties
        ElectrodeLocationIdentifier
        ElectrodeDefinitionIdentifier
        SavePathIdentifier char
    end
    
    methods
        function obj = FreesurferDatExport()
            obj.ElectrodeLocationIdentifier   = 'ElectrodeLocation';
            obj.ElectrodeDefinitionIdentifier = 'ElectrodeDefinition';
            obj.SavePathIdentifier            = '';
        end
        
        function Publish(obj)
            obj.AddInput(obj.ElectrodeLocationIdentifier,   'ElectrodeLocation');
            obj.AddInput(obj.ElectrodeDefinitionIdentifier, 'ElectrodeDefinition');
            obj.AddOptionalInput(obj.SavePathIdentifier,    'PathInformation');
        end
        
        
        function Initialize(obj)
        end
        
        function []= Process(obj, eLocsIn,elDef)
            % if empty, use dialog (default behavior)
            if isempty(obj.SavePathIdentifier)
                path = uigetdir;
                if isequal(path, 0)
                    error('Selection aborted');
                end
            % Otherwise, save on relative path in project folder using component name as file name
            else
                path = fullfile(obj.ComponentPath,'..',obj.SavePathIdentifier); 
            end

            % create save folder if it doesn't exist
            if ~isfolder(path)
                mkdir(path)
            end
            
            for i = 1:length(elDef.Definition)
                str = '\n';
                if(exist('eLocsIn','var'))
                    currLocs = find(eLocsIn.DefinitionIdentifier == i);
                    for l = 1:length(currLocs)
                        str = [str num2str(eLocsIn.Location(currLocs(l),:)) '\n'];
                    end
                    numeDefEls = length(currLocs);
                else
                    numeDefEls = 0;
                end
                str = [str 'info \nnumpoints ' num2str(numeDefEls) '\nuseRealRAS 1'];
                
                wayptfileIds{i} = [path '/' regexprep(regexprep(elDef.Definition(i).Name,' +','_'),'[<>:"/\|?*]','_${num2str(cast($0,''uint8''))}') '.dat'];
                fileID = fopen(wayptfileIds{i},'w');
                fprintf(fileID, str);
                fclose(fileID);
            end
            
            % Popup stating where file was saved
            msgbox(['Electrodes saved in folder: ',GetFullPath(path)],[obj.Name,' file(s) saved'])
        end
    end
end

