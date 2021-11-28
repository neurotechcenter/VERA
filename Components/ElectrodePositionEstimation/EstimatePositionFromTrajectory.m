classdef EstimatePositionFromTrajectory < AComponent
    %ESTIMATEPOSITIONFROMTRAJECTORY Summary of this class goes here
    %   Detailed explanation goes here
    
    properties

        TrajectoryIdentifier
        ElectrodeDefinitonIdentifier
        ElectrodeLocationIdentifier
    end
    
    methods
        function obj = EstimatePositionFromTrajectory()
            %ESTIMATEPOSITIONFROMTRAJECTORY Construct an instance of this class
            %   Detailed explanation goes here
            obj.TrajectoryIdentifier='Trajectory';
            obj.ElectrodeDefinitonIdentifier='ElectrodeDefinition';
            obj.ElectrodeLocationIdentifier='EstimatedElectrodeLocation';
        end
        
        function Publish(obj)
            obj.AddInput(obj.TrajectoryIdentifier,'ElectrodeLocation');
            obj.AddInput(obj.ElectrodeDefinitonIdentifier,'ElectrodeDefinition');
            obj.AddOutput(obj.ElectrodeLocationIdentifier,'ElectrodeLocation');
        end

        function Initialize(obj)
        end

        function eLocs=Process(obj,traj,eDef)
            eLocs=obj.CreateOutput(obj.ElectrodeLocationIdentifier);
            for idx=1:length(eDef.Definition)
                trajectory_length=pdist(traj.GetWithIdentifier(idx));
                trajectories=zeros(eDef.Definition(idx).NElectrodes,3);
                for idx_contact = 1:eDef.Definition(idx).NElectrodes
                    trajectories(idx_contact,:) =   traj.Location(2,:) ... % origin
                                                              + ((traj.Location(1,:) - traj.Location(2,:)) ./ trajectory_length) * 1 ... % mm, center of first electrode
                                                              + ((traj.Location(1,:) - traj.Location(2,:)) ./ trajectory_length) * (idx_contact-1) * eDef.Definition(idx).Spacing; 
                end
                eLocs.AddWithIdentifier(idx,trajectories);
            end

        end
    end
end

