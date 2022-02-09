classdef MatlabElectrodeSelection < AComponent
    %MatlabElectrodeSelection This Component allows manual and
    %(semi)automated localization of electrode grids, fully implemented in
    %Matlab

    
    properties
        ElectrodeDefinitionIdentifier % Identifier for ElectrodeDefinition Data
        CTIdentifier % Identifier for CT
        SurfaceIdentifier % Optional Surface Identifier
        ElectrodeLocationIdentifier % Identifier for Electrode Locations
        TrajectoryIdentifier
        Data
        
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
            obj.TrajectoryIdentifier='Trajectory';
            obj.buttonActivity=struct('IsPressed',false,'Point',0,'Button',0);
            obj.Data=[];
        end
        
        function Publish(obj)
            obj.AddInput(obj.CTIdentifier,'Volume');
            obj.AddInput(obj.ElectrodeDefinitionIdentifier,'ElectrodeDefinition');
            obj.AddOptionalInput(obj.SurfaceIdentifier,'Surface');
            obj.AddOptionalInput(obj.TrajectoryIdentifier,'ElectrodeLocation');
            obj.AddOptionalInput(obj.ElectrodeLocationIdentifier,'ElectrodeLocation');
            obj.AddOutput(obj.ElectrodeLocationIdentifier,'ElectrodeLocation');
        end
        
        function Initialize(obj)
        end
        
        function out=Process(obj,ct,def,varargin)
            if(isempty(obj.Data))
                obj.Data=obj.CreateOutput(obj.ElectrodeLocationIdentifier);
            end
            
            out=obj.Data;
            f=figure('MenuBar', 'none', ...
                'Toolbar', 'none','Name',obj.Name);
            selFig=MatlabElectrodeSelectionGUI('Parent',f);
            if(length(varargin) > 1)
                for i=1:2:length(varargin)
                    if(strcmp(varargin{i},obj.SurfaceIdentifier))
                        selFig.SetSurface(varargin{i+1});
                    end
                    if(strcmp(varargin{i},obj.TrajectoryIdentifier))
                        selFig.SetTrajectories(varargin{i+1});
                    end
                    
                    if(strcmp(varargin{i},obj.ElectrodeLocationIdentifier))
                        if(isempty(obj.Data))
                            out.DefinitionIdentifier=varargin{i+1}.DefinitionIdentifier;
                            out.Location=varargin{i+1}.Location;
                        elseif(strcmp(questdlg('Old Matlab Electrode information available, do you want to override existing data?','Override existing data?','Override','Keep',''),'Override'))
                            out.DefinitionIdentifier=varargin{i+1}.DefinitionIdentifier;
                            out.Location=varargin{i+1}.Location;
                        end
                    end
                end
            end
            %out=obj.CreateOutput(obj.ElectrodeLocationIdentifier);
            selFig.SetElectrodeLocation(out);
            selFig.SetElectrodeDefintion(def);
            selFig.SetVolume(ct);
            
            uiwait(f);
        end
    end
end

