classdef TalairachProjection < AComponent
    %TalairachProjection Projects a Surface into Talairach Coordinates
    
    properties
        SurfaceIdentifier
        SurfaceOutIdentifier
        ElectrodeLocationOutIdentifier
        ACIdentifier
        PCIdentifier
        MidSagIdentifier
        ElectrodeLocationIdentifier
    end
    
    methods
        function obj = TalairachProjection()
            %UNTITLED Construct an instance of this class
            %   Detailed explanation goes here
            obj.SurfaceIdentifier='Surface';
            obj.SurfaceOutIdentifier='Surface';
            obj.ElectrodeLocationIdentifier='ElectrodeLocation';
            obj.ElectrodeLocationOutIdentifier='ElectrodeLocation';
            obj.ACIdentifier='AC';
            obj.PCIdentifier='PC';
            obj.MidSagIdentifier='MidSag';
            
        end
        
        function Publish(obj)
            obj.AddInput(obj.SurfaceIdentifier,'Surface');
            obj.AddInput(obj.ElectrodeLocationIdentifier,'ElectrodeLocation')
            obj.AddInput(obj.ACIdentifier,'PointSet');
            obj.AddInput(obj.PCIdentifier,'PointSet');
            obj.AddInput(obj.MidSagIdentifier,'PointSet');
            obj.AddOutput(obj.SurfaceOutIdentifier,'Surface');
            obj.AddOutput(obj.ElectrodeLocationOutIdentifier,'ElectrodeLocation')
        end
        
        function Initialize(obj)
        end
        
        function [surf,eLocs]=Process(obj,surf,eLocs,ac,pc,midsag)
            [surf.Model,eLocs.Location]=projectToStandard(surf.Model,eLocs.Location,[ac.Location;pc.Location;midsag.Location],'talairach');
        end
    end
end

