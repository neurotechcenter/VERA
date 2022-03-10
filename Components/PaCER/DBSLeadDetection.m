classdef DBSLeadDetection < AComponent
    %DBSLeadDetection - Finds location of DBS locations using PaCER

    properties
        CTIdentifier
        ElectrodeDefinitionIdentifier
        ElectrodeLocationInIdentifier
        ElectrodeLocationOutIdentifier
    end

    methods
        function obj = DBSLeadDetection()
            %FileLoader - Constructor
            obj.CTIdentifier='CT';
            obj.ElectrodeDefinitionIdentifier='ElectrodeDefinition';
            obj.ElectrodeLocationInIdentifier='ElectrodeLocation';
            obj.ElectrodeLocationOutIdentifier='ElectrodeLocation';
        end

        function Publish(obj)
            obj.AddInput(obj.CTIdentifier,'Volume');
            obj.AddInput(obj.ElectrodeDefinitionIdentifier,'ElectrodeDefinition');
            obj.AddOptionalInput(obj.ElectrodeLocationInIdentifier,'ElectrodeLocation');
            obj.AddOutput(obj.ElectrodeLocationOutIdentifier,'ElectrodeLocation');
            obj.RequestDependency('PaCER','folder');
        end

        function Initialize(obj)
            pacer_path=obj.GetDependency('PaCER');
            addpath(genpath(pacer_path));

        end

        function [elLoc] = Process(obj,CT,elDef,~,elLocIn)
            elLoc=obj.CreateOutput(obj.ElectrodeLocationOutIdentifier);
            if(exist('elLocIn','var')) 
                elLoc.DefinitionIdentifier=elLocIn.DefinitionIdentifier;
                elLoc.Location=elLocIn.Location;
            end
            pacer_ct=NiftiModSPM(CT.Path);
            
            available_types={'Medtronic 3387','Medtronic 3389','Boston Vercise Directional','DBS'};
            for i=1:length(available_types)
                if(any(strcmp({elDef.Definition.Type},available_types{i})))
                    if(any(strcmp({elDef.Definition.Type},'DBS')))
                        elecModels=PaCER(pacer_ct);
                    else
                        elecModels=PaCER(pacer_ct,'electrodeType',available_types{i});
                    end
                    if(sum(strcmp({elDef.Definition.Type},available_types{i})) ~= length(elecModels))
                        error("Electrodes found are not as expected from Electrode Definition!");
                    end
                    locId=find(strcmp({elDef.Definition.Type},available_types{i}));
                    for ii=1:length(locId)
                        loc=pacer_ct.getMatlabIdxFromNiftiWorldCoordinates(elecModels{ii}.getContactPositions3D()')';
                        elLoc.AddWithIdentifier(locId(ii),CT.Vox2Ras([loc(:,1) loc(:,2) loc(:,3)] ));
                    end
                end
            end
        end
    end
end