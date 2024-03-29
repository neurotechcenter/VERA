classdef ReorderElectrodes < AComponent
    %ReorderElectrodes Reorder electrodes so that order matches channel
    %locations in intracranial recording channel locations. 
    
    properties
        ElectrodeLocationIdentifier
        SurfaceIdentifier
        ElectrodeDefinitionIdentifier
        
    end
    
    methods
        function obj = ReorderElectrodes()
            %REORDERELECTRODES Construct an instance of this class
            %   Detailed explanation goes here
            obj.ElectrodeLocationIdentifier='ElectrodeLocation';
            obj.ElectrodeDefinitionIdentifier='ElectrodeDefinition';
            obj.SurfaceIdentifier='Surface';
        end
        
        function Publish(obj)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            obj.AddInput(obj.ElectrodeLocationIdentifier,'ElectrodeLocation');
            obj.AddInput(obj.ElectrodeDefinitionIdentifier,'ElectrodeDefinition');
            obj.AddOptionalInput(obj.SurfaceIdentifier,'Surface');
            obj.AddOutput(obj.ElectrodeLocationIdentifier,'ElectrodeLocation');
            obj.AddOutput(obj.ElectrodeDefinitionIdentifier,'ElectrodeDefinition');
        end
        
        function Initialize(obj)
        end
        
        function [eLocs,eDef]= Process(obj, eLocs,eDef,varargin)
            f=figure('MenuBar', 'none', ...
                'Toolbar', 'none');
            elOrdergui=ElectrodeOrderGUI('Parent',f);
            if(length(varargin) == 2)
                elOrdergui.setBrainSurface(varargin{2});
            end
            
            elOrdergui.setElectrodes(eDef,eLocs);

            waitfor(f);
            %eLocs=elOrdergui.getUpdatedElectrodeLocations();
        end
        

    end
end

