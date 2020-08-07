classdef ElectrodeDefinitionConfiguration  < AComponent
    %ElectrodeDefinitionConfiguration Component to define Electrodes (Grids, Strips, Depth Electrodes)
    %This Component is used to define electrode configurations
    
    properties
        Identifier char % Identifier of Output Data, Default is 'ElectrodeDefinition'
        ElectrodeDefinition % Electrode Definitions
    end
    
    methods
 function obj = ElectrodeDefinitionConfiguration()
            %ElectrodeDefinitionConfiguration - Constructor
            obj.Identifier='ElectrodeDefinition';
            obj.ElectrodeDefinition=[];
 end
        
        function Publish(obj)
            % Publish - Adds an Output for the ElectrodeDefiniton Data
            % See also AComponent.Publish, ElectrodeDefinition
            obj.AddOutput(obj.Identifier,'ElectrodeDefinition');
        end
        
        function Initialize(obj)
            % Initialize - Check if Identifier Tag is initialized
            % See also AComponent.Initialize
            if(isempty(obj.Identifier))
                error('No Identifier Tag specified');
            end
        end
        
        function [out] = Process(obj)
            %Process - Returns a new ElectrodeConfiguration object
            %Creates a ElectrodeConfiguration object with the information
            %contained in the property ElectrodeConfiguration. This
            %property is usually set in the GUI via the ElectrodeDefinition
            %View
            %See also AComponent.Process, ElectrodeConfiguration,
            %ElectrodeDefinitionView
             out=obj.CreateOutput(obj.Identifier);
             if(isempty(obj.ElectrodeDefinition))
                 error('No Electrodes Defined!');
             end
             out.Definition=obj.ElectrodeDefinition;
        end
    end
end

