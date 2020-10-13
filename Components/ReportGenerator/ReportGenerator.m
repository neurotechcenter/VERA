classdef ReportGenerator < AComponent
    %ELECTRODEPROJECTION Summary of this class goes here
    %   Detailed explanation goes here
    
   properties
        MRIIdentifier
        SurfaceIdentifier
        ElectrodeDefinitionIdentifier
        ElectrodeLocationIdentifier
    end
    
    methods
        function obj = ReportGenerator()
            obj.MRIIdentifier='MRI';
            obj.SurfaceIdentifier='Surface';
            obj.ElectrodeDefinitionIdentifier='ElectrodeDefinition';
            obj.ElectrodeLocationIdentifier='ElectrodeLocation';
        end
        function Publish(obj)
            obj.AddInput(obj.MRIIdentifier,'Volume');
            obj.AddInput(obj.SurfaceIdentifier,'Surface');
            obj.AddInput(obj.ElectrodeDefinitionIdentifier,'ElectrodeDefinition');
            obj.AddInput(obj.ElectrodeLocationIdentifier,'ElectrodeLocation');
        end
        function Initialize(obj)
            
        end
        
        function [] = Process(obj,mri,surface,identifiers,electrodes)
            
            
        end
    end
end

