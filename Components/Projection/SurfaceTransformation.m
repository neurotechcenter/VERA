classdef SurfaceTransformation < AComponent
    %SurfaceTransformation Apply Transform matrix to surface vertex coordinates 
    
    properties
        SurfaceIdentifier
        TIdentifier
    end
    
    methods
        function obj = SurfaceTransformation()
            obj.SurfaceIdentifier='Surface';
            obj.TIdentifier='T_MNI';
        end
        
        function Publish(obj)
            obj.AddInput(obj.SurfaceIdentifier,'Surface');
            obj.AddInput(obj.TIdentifier,'TransformationMatrix');
            obj.AddOutput(obj.SurfaceIdentifier,'Surface');

        end

        function Initialize(~)
        end

        function surfOut=Process(obj,surf,T)
                surfOut=obj.CreateOutput(obj.SurfaceIdentifier,surf);
            for i=1:size(surfOut.Model.vert,1)
                traj_temp=[surfOut.Model.vert(i,:) 1];
                for ii=1:size(T.T,3)
                    traj_temp=(T.T(:,:,ii)*traj_temp')';
                end
                surfOut.Model.vert(i,:)=traj_temp(1:3);
            end 
        end

    end
end

