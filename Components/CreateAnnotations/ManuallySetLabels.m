classdef ManuallySetLabels < AComponent
    %ManuallySetLabels The ManuallySetLabels Component allows the user to
    %modify the labels manually in a table
    
    properties
        ElectrodeLocationIdentifier
        ElectrodeDefinitionIdentifier
        Labels
        ElectrodeDefinition
    end

    methods
        function obj = ManuallySetLabels()
            obj.ElectrodeLocationIdentifier   = 'ElectrodeLocation';
            obj.ElectrodeDefinitionIdentifier = 'ElectrodeDefinition';
        end

        function Publish(obj)
            obj.AddInput(obj.ElectrodeLocationIdentifier,   'ElectrodeLocation');
            obj.AddInput(obj.ElectrodeDefinitionIdentifier, 'ElectrodeDefinition');
            obj.AddOutput(obj.ElectrodeLocationIdentifier,  'ElectrodeLocation');
        end
        function Initialize(obj)
        end

        function out=Process(obj,elLocs,eDef)
            out = obj.CreateOutput(obj.ElectrodeLocationIdentifier, elLocs);
            obj.Labels             = elLocs;
            obj.ElectrodeDefinition = eDef;

            % create view to modify labels
            h      = figure('Name',obj.Name,'Position',[200,150,700,500]);
            elView = ElectrodeLocationTableView(h,obj.Labels);
            elView.SetComponent(obj);
            uiwait(h);

            out.Label = elLocs.Label;
        end
    end
end