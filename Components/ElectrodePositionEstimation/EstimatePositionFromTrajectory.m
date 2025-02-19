classdef EstimatePositionFromTrajectory < AComponent
    %EstimatePositionFromTrajectory Tries to estimate the electrode
    %locations based on planned trajectories
    
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
                curr_traj=traj.GetWithIdentifier(idx);
                trajectory_length=pdist(curr_traj);
                trajectories=zeros(eDef.Definition(idx).NElectrodes,3);
                for idx_contact = 1:eDef.Definition(idx).NElectrodes
                    % trajectories(idx_contact,:) =   curr_traj(2,:) ... % origin
                    %                                           + ((curr_traj(1,:) - curr_traj(2,:)) ./ trajectory_length) * 1 ... % mm, center of first electrode
                    %                                           + ((curr_traj(1,:) - curr_traj(2,:)) ./ trajectory_length) * (idx_contact-1) * eDef.Definition(idx).Spacing; 

                    trajectories(idx_contact,:) =   curr_traj(1,:) ... % origin
                                                              + ((curr_traj(2,:) - curr_traj(1,:)) ./ trajectory_length) * (idx_contact-1) * eDef.Definition(idx).Spacing; 
                end
                eLocs.AddWithIdentifier(idx,trajectories);
            end

        end
    end
end

