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
            obj.AddInput(obj.ElectrodeLocationIdentifier,  'ElectrodeLocation');
            obj.AddOptionalInput(obj.ElectrodeDefinitionIdentifier, 'ElectrodeDefinition');
            obj.AddOutput(obj.ElectrodeLocationIdentifier, 'ElectrodeLocation');
        end
        function Initialize(obj)
        end

        function out=Process(obj,elLocs,varargin)
            out = obj.CreateOutput(obj.ElectrodeLocationIdentifier, elLocs);
            obj.Labels = elLocs;

            if length(varargin) == 2
                obj.ElectrodeDefinition = varargin{2};
            else
                obj.ElectrodeDefinition = [];
                warning(['ManuallySetLabels: No ElectrodeDefinition input was received - Channel Name ' ...
                    'column will be blank. Make sure the component producing ElectrodeDefinition is ' ...
                    'positioned BEFORE ManuallySetLabels in the pipeline (this is required at pipeline ' ...
                    'load time, independent of the order components are actually run in).']);
            end

            % create view to modify labels
            h      = figure('Name',obj.Name,'Position',[200,150,700,500]);
            elView = ElectrodeLocationTableView(h,obj.Labels);
            elView.SetComponent(obj);
            uiwait(h);

            out.Label = elLocs.Label;
        end
    end
end