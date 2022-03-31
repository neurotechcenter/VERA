classdef ElectrodeTransformation < AComponent
    %ElectrodeTransformation Projects electrode locations based on the
    %supplied transformation matrix
    
    properties
        ElectrodeLocationIdentifier
        TIdentifier
    end
    
    methods
        function obj = ElectrodeTransformation()
            obj.ElectrodeLocationIdentifier='ElectrodeLocation';
            obj.TIdentifier='T';
        end
        
        function Publish(obj)
            obj.AddInput(obj.TIdentifier,'TransformationMatrix');
            obj.AddInput(obj.ElectrodeLocationIdentifier,'ElectrodeLocation');
            obj.AddOutput(obj.ElectrodeLocationIdentifier,'ElectrodeLocation');
        end
        function Initialize(obj)
        end
        
        function elLocs=Process(obj,T,elLocs)
            
            for i=1:size(elLocs.Location,1)
                traj_temp=[elLocs.Location(i,:) 1];
                for ii=1:size(T.T,3)
                    traj_temp=(T.T(:,:,ii)*traj_temp')';
                end
                elLocs.Location(i,:)=traj_temp(1:3);
            end
        end
    end
end

