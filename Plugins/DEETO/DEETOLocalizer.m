classdef DEETOLocalizer < AComponent
    %UNTITLED Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        CTIdentifier
        ElectrodeDefinitionIdentifier
        ElectrodeLocationInputIdentifier
        ElectrodeLocationIdentifier
    end
    
    methods
        function obj = DEETOLocalizer()
            obj.CTIdentifier='CT';
            obj.ElectrodeDefinitionIdentifier='ElectrodeDefinition';
            obj.ElectrodeLocationInputIdentifier='ElectrodeLocation';
            obj.ElectrodeLocationIdentifier='ElectrodeLocation';
        end
        
        function Publish(obj)
            obj.AddInput(obj.CTIdentifier,'Volume');
            obj.AddInput(obj.ElectrodeDefinitionIdentifier,'ElectrodeDefinition');
            if(~isempty(obj.ElectrodeLocationInputIdentifier))
                obj.AddOptionalInput(obj.ElectrodeLocationInputIdentifier,'ElectrodeLocation');
            end
            obj.AddOuput(obj.ElectrodeLocationIdentifier,'ElectrodeLocation');
            obj.RequestDependency('DEETO','file');
        end
        
        function Initialize(obj)
        end
        
        function elLoc=Process(obj,ct,elDef,varargin)
            if(length(varargin) == 2)
                elLoc=varargin{2};
            else
                elLoc=obj.CreateOutput(obj.ElectrodeLocationIdentifier);
            end
            fed_file='';
            outFile=fullfile(obj.GetTempPath(),'outfile.txt');
            deeto_path=obj.GetDependency('DEETO');
            system([deeto_path ' -ct ' ct.Path ' -f ' fed_file ' -o ' outFile]);
        end
    end
end

