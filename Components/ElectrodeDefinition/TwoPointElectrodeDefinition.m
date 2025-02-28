classdef TwoPointElectrodeDefinition  < AComponent
    %ElectrodeDefinitionConfiguration Component to define Electrodes (Grids, Strips, Depth Electrodes)
    %This Component is used to define electrode configurations

    properties
        Identifier char % Identifier of Output Data, Default is 'ElectrodeDefinition'
        TwoPointIdentifier
    end

    methods
        function obj = TwoPointElectrodeDefinition()
            %ElectrodeDefinitionConfiguration - Constructor
            obj.Identifier          = 'ElectrodeDefinition';
            obj.TwoPointIdentifier  = 'ElectrodeDefinition_2Points';
        end

        function Publish(obj)
            % Publish - Adds an Output for the ElectrodeDefiniton Data
            % See also AComponent.Publish, ElectrodeDefinition
            obj.AddInput(obj.Identifier,'ElectrodeDefinition');
            obj.AddOutput(obj.TwoPointIdentifier,'ElectrodeDefinition');
        end

        function Initialize(obj)
        end

        function [out] = Process(obj,edef)
            %Process - Returns a new ElectrodeConfiguration object
            %Creates a ElectrodeConfiguration object with the information
            %contained in the property ElectrodeConfiguration. This
            %property is usually set in the GUI via the ElectrodeDefinition
            %View
            %See also AComponent.Process, ElectrodeConfiguration,
            %ElectrodeDefinitionView

            out = obj.CreateOutput(obj.TwoPointIdentifier);

            out.Definition = edef.Definition;
            for i = 1:size(out.Definition,1)
                out.Definition(i).NElectrodes = 2;
            end

        end
    end
end

