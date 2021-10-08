classdef CopyElectrodeLocationsTo < AComponent
    %UNTITLED Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        ElectrodeLocationIdentifier
        ElectrodeDefinitionIdentifier
        EletrodeLocationTargetIdentifier
        ElectrodeDefinitionTargetIdentifier
    end
    
    methods
        function obj = CopyElectrodeLocationsTo()
            obj.ElectrodeLocationIdentifier='ElectrodeLocation';
            obj.ElectrodeDefinitionIdentifier='ElectrodeDefinition';
            obj.EletrodeLocationTargetIdentifier='';
            obj.ElectrodeDefinitionTargetIdentifier='';
            
        end
        
        function Publish(obj)
            if(isempty(obj.EletrodeLocationTargetIdentifier) || isempty(obj.ElectrodeDefinitionTargetIdentifier))
                error('Either EletrodeLocationTargetIdentifier or ElectrodeDefinitionTargetIdentifier is not defined, please check the pipeline!');
            end
            obj.AddInput(obj.ElectrodeLocationIdentifier,'ElectrodeLocation');
            obj.AddInput(obj.ElectrodeDefinitionIdentifier,'ElectrodeDefinition');
            obj.AddInput(obj.ElectrodeDefinitionTargetIdentifier,'ElectrodeDefinition');
            obj.AddOptionalInput(obj.EletrodeLocationTargetIdentifier,'ElectrodeLocation');
            obj.AddOutput(obj.EletrodeLocationTargetIdentifier,'ElectrodeLocation');
        end
        
        function Initialize(~)
        end
        
        function outLocations=Process(obj,inLocs,inDef,outDef,~,outLoc)
            if(exist('outLoc','var'))
                outLocations=outLoc;
            else
                outLocations=obj.CreateOutput(obj.EletrodeLocationTargetIdentifier);
            end
            %first check for identical names in indef and outdef
            for i=1:length(outDef.Definition)
                res=find(strcmp(outDef.Definition(i).Name,{inDef.Definition.Name}), 1);
                if(~isempty(res))
                    answer='Override';
                    if(any(outLocations.DefinitionIdentifier == i))
                        answer=questdlg(['Do you want to Keep the definition of ' outDef.Definition(i).Name],'Keep or override?','Keep','Override');
                    end
                    if(strcmp(answer,'Override'))
                        outLocations.RemoveWithIdentifier(i);
                        outLocations.AddWithIdentifier(i,inLocs.Location(inLocs.DefinitionIdentifier == res,:));
                    end
                    disp(['Copied Electrode Locations with Name: ' outDef.Definition(i).Name]);
                end
                
                
            end
        end
        
        
    end
end

