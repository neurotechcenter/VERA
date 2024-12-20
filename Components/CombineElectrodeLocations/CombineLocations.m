classdef CombineLocations < AComponent
    %CombineLocations Allows to combine Electrode Location Data objects
    %into a new Dataobject output
    % Also see AComponent
    
    properties
        In1
        In2
        Out
    end
    
    methods
        function obj = CombineLocations()
           obj.Out='ElectrodeLocations';
           obj.In1='';
           obj.In2='';
        end
        
        function Publish(obj)
            if(isempty(obj.In1) || isempty(obj.In2))
                error('Inputs not defined');
            end
            obj.AddInput(obj.In1,'ElectrodeLocation');
            obj.AddInput(obj.In2,'ElectrodeLocation');
            obj.AddOutput(obj.Out,'ElectrodeLocation');
        end
        
        function Initialize(~)
        end
        
        function C=Process(obj,A,B)
            C=obj.CreateOutput(obj.Out);
            C.Location=[A.Location; B.Location];
            C.DefinitionIdentifier=[A.DefinitionIdentifier B.DefinitionIdentifier];
        end
    end
end

