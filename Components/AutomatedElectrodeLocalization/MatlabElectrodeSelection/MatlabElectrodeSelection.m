classdef MatlabElectrodeSelection < AComponent
    %MatlabElectrodeSelection This Component allows manual and
    %(semi)automated localization of electrode grids, strips and depth electrodes fully implemented in
    %Matlab
    %
    %
    %After an initial threshold of the CT, we create 3D centroids by finding connected voxels.
    %
    %
    %Every Centroid identified after thresholding is used as a seed to create a connected graph based on some conditions:
    %
    %
    %For every centroid, we do the following:
    %For Grids: Find 2 other centroids that create a 90-degree angle with the starting point. The search radius is the
    %inter-electrode distance.
    %For each of the valid points we find we look for other points fitting the criteria - this will create a connected graph.
    %We can then traverse the graph to find out how many points are part of the grid.
    %In addition, there is an uncertainty parameter: which is set to 0.15 or something close to it. This just means we allow
    %up to 15% error in the measurements (since we are not taking into account the curvature of grids,
    %that allows us to still get connected parts that are somewhat curved).
    %
    %
    %For Strips and SEEG electrodes, we just use 180 degrees instead of 90.
    %
    %
    %And lastly, we will sweep through different threshold values of the CT to find where we get the best results.
    %The Cost function for that optimization searches for the minimum of the difference in the number of electrodes
    %found versus the known number of electrodes.

    
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
            %check if appropriate toolboxes are installed!
            if(~exist('regionprops3','file') || ~exist('pdist','file') || ~exist('pointCloud','file'))
                error(sprintf(['MatlabElectrodeSelection requires the following MATLAB toolboxes to be installed: \n' ...
                'Image Processing Toolbox \n' ...
                'Statistics and Machine Learning Toolbox \n' ...
                'Computer Vision Toolbox']));

            end
        end
        
        function out=Process(obj,ct,def,varargin)
            if(isempty(obj.Data))
                obj.Data=obj.CreateOutput(obj.ElectrodeLocationIdentifier);
            else %we need to check obj.Data for consistency, lets see if all the definitions still exist....
                if(max(obj.Data.DefinitionIdentifier) > length(def.Definition)) 
                    obj.Data=obj.CreateOutput(obj.ElectrodeLocationIdentifier);
                end
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

