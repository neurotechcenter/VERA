classdef MatlabElectrodeSelection < AComponent
    %MatlabElectrodeSelection This Component allows manual and
    %(semi)automated localization of electrode grids, fully implemented in
    %Matlab

    
    properties
        ElectrodeDefinitionIdentifier % Identifier for ElectrodeDefinition Data
        CTIdentifier % Identifier for CT
        SurfaceIdentifier % Optional Surface Identifier
        ElectrodeLocationIdentifier % Identifier for Electrode Locations
    end
    properties (Access = private)
        buttonActivity
    end
    
    methods
        function obj = MatlabElectrodeSelection()
            obj.ElectrodeDefinitionIdentifier='ElectrodeDefinition';
            obj.ElectrodeLocationIdentifier='ElectrodeLocation';
            obj.CTIdentifier='CT';
            obj.SurfaceIdentifier='Surface';
            obj.buttonActivity=struct('IsPressed',false,'Point',0,'Button',0);
        end
        
        function Publish(obj)
            obj.AddInput(obj.CTIdentifier,'Volume');
            obj.AddInput(obj.ElectrodeDefinitionIdentifier,'ElectrodeDefinition');
            obj.AddOptionalInput(obj.SurfaceIdentifier,'Surface');
            obj.AddOutput(obj.ElectrodeLocationIdentifier,'ElectrodeLocation');
        end
        
        function Initialize(obj)
        end
        
        function out=Process(obj,ct,def,varargin)
            
            f=figure('MenuBar', 'none', ...
                'Toolbar', 'none');
            selFig=MatlabElectrodeSelectionGUI('Parent',f);
            if(length(varargin) == 2)
                selFig.SetSurface(varargin{2});
            end
            out=obj.CreateOutput(obj.ElectrodeLocationIdentifier);
            selFig.SetElectrodeLocation(out);
            selFig.SetElectrodeDefintion(def);
            selFig.SetVolume(ct);
            
            uiwait(f);

        end
    end
end

