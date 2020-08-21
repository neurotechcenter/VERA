classdef ElectrodeProjection < AComponent
    %ElectrodeProjection Projects electrodes onto the hull of the cortex
    %using the NeuralAct package
    
   properties
        SurfaceIdentifier
        ElectrodeLocationIdentifier
        ElectrodeDefinitionIdentifier
    end
    
    methods
        function obj = ElectrodeProjection()
            obj.SurfaceIdentifier='Surface';
            obj.ElectrodeLocationIdentifier='ElectrodeLocation';
            obj.ElectrodeDefinitionIdentifier='ElectrodeDefinition';
        end
        function Publish(obj)
            obj.AddInput(obj.SurfaceIdentifier,'Surface');
            obj.AddInput(obj.ElectrodeDefinitionIdentifier,'ElectrodeDefinition');
            obj.AddInput(obj.ElectrodeLocationIdentifier,'ElectrodeLocation');
            obj.AddOutput(obj.ElectrodeLocationIdentifier,'ElectrodeLocation');
            obj.RequestDependency('NeuralAct','folder');
        end
        function Initialize(obj)
            path=obj.GetDependency('NeuralAct');
            addpath(genpath(path));
            
        end
        
        function [electrodes] = Process(obj,surface,definitions,electrodes)
            hull=hullModel(surface.Model);
            substr.electrodes=[];
            substr.origIdx=[];
            for i=1:size(electrodes.Location,1)
                idx=electrodes.DefinitionIdentifier(i);
                if(~strcmp(definitions.Definition(idx).Type,'Depth'))
                    substr.electrodes(end+1,:)=electrodes.Location(i,:);
                    substr.origIdx(end+1)=i;
                end
                
            end
            substr_out=projectElectrodes(hull,substr,80);
            electrodes.Location(substr_out.origIdx,:)=substr_out.trielectrodes;
            
            
        end
    end
end

