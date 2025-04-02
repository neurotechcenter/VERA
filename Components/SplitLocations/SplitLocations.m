classdef SplitLocations < AComponent
    %SplitLocations allows to select a subset of electrodes to create a new
    %ElectrodeLocation
    % Also see AComponent
    
    properties
        DefinitionIn
        LocationIn
        LocationOut
    end
    
    methods
        function obj = SplitLocations()
           obj.DefinitionIn = 'ElectrodeDefinition';
           obj.LocationIn   = 'ElectrodeLocation';
           obj.LocationOut  = '';
        end
        
        function Publish(obj)
            if isempty(obj.DefinitionIn) || isempty(obj.LocationIn)
                error('Inputs not defined');
            end

            obj.AddInput(obj.DefinitionIn, 'ElectrodeDefinition');
            obj.AddInput(obj.LocationIn,   'ElectrodeLocation');
            obj.AddOutput(obj.LocationOut, 'ElectrodeLocation');
        end
        
        function Initialize(~)
        end
        
        function locOut = Process(obj, defIn, locIn)
            locOut = obj.CreateOutput(obj.LocationOut);

            elDefNames        = {defIn.Definition.Name};
            [selectedElecs,~] = listdlg('PromptString','Select Electrode Subset','SelectionMode','multi','ListString',elDefNames);

            selectedIdx = [];
            for j = 1:length(selectedElecs)
                selectedIdx = [selectedIdx; find(locIn.DefinitionIdentifier == selectedElecs(j))];
            end
            selectedIdx = sort(selectedIdx);

            locOut.DefinitionIdentifier = locIn.DefinitionIdentifier(selectedIdx);
            locOut.Location             = locIn.Location(selectedIdx,:);
            locOut.Label                = locIn.Label(selectedIdx);
            locOut.Annotation           = locIn.Annotation(selectedIdx);
        end
    end
end

