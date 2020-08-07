classdef ElectrodeDefinition < AData
    %ElectrodeDefinition - Data object for Electrode Definitons
    %   
    
    properties
        Definition
    end
    
    methods
        function obj = ElectrodeDefinition()
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
                    if(strcmp( newgrp.Type,defBuff(iGrp).Type) && ...
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

