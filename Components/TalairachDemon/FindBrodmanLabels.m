classdef FindBrodmanLabels < AComponent
    %UNTITLED Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        TalairachElectrodeLocationIdentifier
    end
    
    methods
        function obj = FindBrodmanLabels()
            obj.TalairachElectrodeLocationIdentifier='TailairachElectrodeLocation';
        end
        
        function Publish(obj)
            obj.AddInput(obj.TalairachElectrodeLocationIdentifier,'ElectrodeLocation');
            obj.AddOutput(obj.TalairachElectrodeLocationIdentifier,'ElectrodeLocation');
        end
        
        function Initialize(obj)
        end
        
        function [elLocs]=Process(obj,elLocsIn)
            elLocs=obj.CreateOutput(obj.TalairachElectrodeLocationIdentifier,elLocsIn);
            jarFile=[fileparts(mfilename('fullpath')) '/talairach.jar'];
            BA=findBrodmanLabel(elLocs.Location,jarFile);
            elLocsIn.Label=BA;
        end
        

    end
end

