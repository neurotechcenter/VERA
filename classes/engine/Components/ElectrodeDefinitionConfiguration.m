classdef ElectrodeDefinitionConfiguration  < AComponent
    %INPUT Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        Identifier char
        ElectrodeDefinition 
    end
    
    methods
 function obj = ElectrodeDefinitionConfiguration()
            obj.Identifier='ElectrodeDefinition';
            obj.ElectrodeDefinition=[];
 end
        
        function Publish(obj)
            obj.AddOutput(obj.Identifier,'ElectrodeDefinition');
        end
        
        function Initialize(obj)
            if(isempty(obj.Identifier))
                error('No Identifier Tag specified');
            end
        end
        
        function [out] = Process(obj)
             out=obj.CreateOutput(obj.Identifier);
             if(isempty(obj.ElectrodeDefinition))
                 error('No Electrodes Defined!');
             end
             out.Definition=obj.ElectrodeDefinition;
        end
    end
end

