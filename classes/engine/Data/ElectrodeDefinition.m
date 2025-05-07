classdef ElectrodeDefinition < AData
    %ElectrodeDefinition - Data object for Electrode Definitons
    % Class used to interact with ElectrodeDefinition Data
    % Electrode Definitions define what type of electrode is used and its
    % geometric properties
    %
    % Properties:
    %   Definition
    %   The definition struct contains the following fields:
    %   Type - Type of electrodes: available types: 'Micro','Grid','Strip','Depth','DBS','Medtronic 3387','Medtronic 3389','Boston Vercise Directional'
    %   Name - Name of the electrode
    %   NElectrodes - The number of channels the electrode has 
    %   Spacing - Number in mm for center to center spacing between
    %   electrodes
    %   Volume - Volume of the contact in mm^3
    %
    % see also AData
    
    properties
        Definition %Electrode definition struct
    end

    properties(Constant)
        ElectrodeTypes ={'Micro','Grid','Strip (Projectable)','Strip','Depth','GND','DBS','Medtronic 3387','Medtronic 3389','Boston Vercise Directional'} %Available Electrode Types
    end
    
    methods
        function obj = ElectrodeDefinition()
            %ElectrodeDefinition Constructor
            obj.Definition=struct('Type',{},'Name',{},'NElectrodes',{},'Spacing',{},'Volume',{});
        end

        function defIdx=AddDefinition(obj,type,name,N,spacing,vol)
            %AddDefinition - Adds a new definition to the definition struct
            % type - type of electrodes as defined by ElectrodeTypes
            % name - name of the electrode definition
            % N - number of recording electrodes
            % spacing - inter-electrode spacing (center to center)
            % vol - electrode volume in mm^3
            if(~any(strcmp(type,obj.ElectrodeTypes)))
                error('Adding non-existing type');
            end
            obj.Definition(end+1)=struct('Type',type,'Name',name,'NElectrodes',N,'Spacing',spacing,'Volume',vol);
            defIdx=length(obj.Definition);
        end
        
        function grps=GetGroupedDefinitions(obj)
            %GetGroupedDefinitions Groups Electrode Definitions together if identical 
            defBuff=obj.Definition;
            grps=struct('Type',{},'Name',{},'NElectrodes',{},'Spacing',{},'Volume',{},'Id',{});
            ids=1:length(obj.Definition);
            while(~isempty(defBuff))
                newgrp.Name={defBuff(1).Name};
                newgrp.Type=defBuff(1).Type;
                newgrp.NElectrodes=defBuff(1).NElectrodes;
                newgrp.Spacing=defBuff(1).Spacing;
                newgrp.Volume=defBuff(1).Volume;
                newgrp.Id=ids(1);
                defBuff(1)=[];
                ids(1)=[];
                grpDel=[];
                for iGrp=1:length(defBuff)
                    if(strcmp(newgrp.Type,defBuff(iGrp).Type) && ...
                       newgrp.NElectrodes==defBuff(iGrp).NElectrodes && ...
                       newgrp.Spacing==defBuff(iGrp).Spacing && ...
                       newgrp.Volume==defBuff(iGrp).Volume)
                   
                       newgrp.Id(end+1)=ids(iGrp);
                       newgrp.Name{end+1}=defBuff(iGrp).Name;
                       grpDel(end+1)=iGrp;
                    end
                end
                defBuff(grpDel)=[];
                ids(grpDel)=[];
                grps(end+1)=newgrp;
            end
        end
    end
end

