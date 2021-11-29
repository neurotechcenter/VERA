classdef FindSurfaceBrodmanLabels < AComponent
    %UNTITLED Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        TalairachSurfaceIdentifier
    end
    
    methods
        function obj = FindBrodmanLabels()
            obj.TalairachElectrodeLocationIdentifier='TailairachSurface';
        end
        
        function Publish(obj)
            obj.AddInput(obj.TalairachElectrodeLocationIdentifier,'Surface');
            obj.AddOutput(obj.TalairachElectrodeLocationIdentifier,'Surface');
        end
        
        function Initialize(obj)
        end
        
        function [surfOut]=Process(obj,surfIn)
            surfOut=obj.CreateOutput(obj.TalairachElectrodeLocationIdentifier,surfIn);
            jarFile=[fileparts(mfilename('fullpath')) '/talairach.jar'];
            BA=findBrodmanLabel(elLocs.Location,jarFile);
            surfOut.Label=BA;
        end
        

    end
end

