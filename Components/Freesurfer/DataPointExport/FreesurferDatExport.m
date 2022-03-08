classdef FreesurferDatExport < AComponent
    %FreesurferDatExport Exports electrode locations to Freesurfer pointset
    %format
    properties
        ElectrodeLocationIdentifier
        ElectrodeDefinitionIdentifier
    end
    
    methods
        function obj = FreesurferDatExport()
            obj.ElectrodeLocationIdentifier='ElectrodeLocation';
            obj.ElectrodeDefinitionIdentifier='ElectrodeDefinition';
        end
        
        function Publish(obj)
            obj.AddInput(obj.ElectrodeLocationIdentifier,'ElectrodeLocation');
            obj.AddInput(obj.ElectrodeDefinitionIdentifier,'ElectrodeDefinition');
        end
        
        
        function Initialize(obj)
        end
        
        function []= Process(obj, eLocsIn,elDef)
             compPath=uigetdir;
             for i=1:length(elDef.Definition)
                str='\n';
                if(exist('eLocsIn','var'))
                    currLocs=find(eLocsIn.DefinitionIdentifier == i);
                    for l=1:length(currLocs)
                        str=[str num2str(eLocsIn.Location(currLocs(l),:)) '\n'];
                    end
                    numeDefEls=length(currLocs);
                else
                    numeDefEls=0;
                end
                str=[str 'info \nnumpoints ' num2str(numeDefEls) '\nuseRealRAS 1'];
                
                wayptfileIds{i}=[compPath '/' regexprep(regexprep(elDef.Definition(i).Name,' +','_'),'[<>:"/\|?*]','_${num2str(cast($0,''uint8''))}') '.dat'];
                fileID = fopen(wayptfileIds{i},'w');
                fprintf(fileID,str);
                fclose(fileID);


            end            
            
        
        end
    end
end

