classdef ElectrodeDefinitionConfiguration  < AComponent
    %ElectrodeDefinitionConfiguration Component to define Electrodes (Grids, Strips, Depth Electrodes)
    %This Component is used to define electrode configurations
    
    properties
        Identifier char % Identifier of Output Data, Default is 'ElectrodeDefinition'
        ElectrodeDefinition % Electrode Definitions
    end
    
    properties
        internalDefinitions
    end

    
    
    methods
 function obj = ElectrodeDefinitionConfiguration()
            %ElectrodeDefinitionConfiguration - Constructor
            obj.Identifier='ElectrodeDefinition';
            obj.ElectrodeDefinition=[];
            obj.internalDefinitions=[];
 end
        
        function Publish(obj)
            % Publish - Adds an Output for the ElectrodeDefiniton Data
            % See also AComponent.Publish, ElectrodeDefinition
            obj.AddOutput(obj.Identifier,'ElectrodeDefinition');
        end
        
        function Initialize(obj)
            obj.internalDefinitions=obj.ElectrodeDefinition;
            obj.ElectrodeDefinition=[]; %remove existing definitions until after check
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
                obj.ElectrodeDefinition=obj.internalDefinitions;
                h=figure;
                elView=ElectrodeDefinitionView('Parent',h);
                elView.SetComponent(obj);
                uiwait(h);
             end
             field = fieldnames(obj.ElectrodeDefinition);
             for i=1:length(obj.ElectrodeDefinition)
                 for f=1:length(field)
                     if(isempty(obj.ElectrodeDefinition(i).(field{f})))
                         error([field{f} ' is missing values!']);
                     end
                 end
             end
             out.Definition=obj.ElectrodeDefinition;
        end
    end
end

