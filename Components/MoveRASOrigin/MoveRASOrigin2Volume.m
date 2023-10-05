classdef MoveRASOrigin2Volume < AComponent
    %MoveRASOrigin Moves the origin of RAS into the Center of the Volume
    %pixels
   properties
        VolumeIdentifier1 % volume to be moved
        VolumeIdentifier2
    end
    
    methods
        function obj = MoveRASOrigin2Volume()
            obj.VolumeIdentifier1='CT';
            obj.VolumeIdentifier2='MRI';
        end
        function Publish(obj)
            obj.AddInput(obj.VolumeIdentifier1,'Volume');
            obj.AddInput(obj.VolumeIdentifier2,'Volume');
            obj.AddOutput(obj.VolumeIdentifier1,'Volume');
        end
        function Initialize(~)
            
        end
        
        function [vol1] = Process(~,vol1,vol2)

            % First move corner of vol1 (CT) to center of vol1
            % modify the sform matrix so the ras coordinate of the center of CT volume is (0,0,0)
            img_size=round(size(vol1.Image.img)/2);
            
            if vol1.Image.hdr.hist.srow_x(1) > 0
                vol1.Image.hdr.hist.srow_x(4) = -vol1.Image.hdr.dime.pixdim(2)*img_size(1);
            else
                vol1.Image.hdr.hist.srow_x(4) = vol1.Image.hdr.dime.pixdim(2)*img_size(1);
            end

            if vol1.Image.hdr.hist.srow_y(2) > 0
                vol1.Image.hdr.hist.srow_y(4) = -vol1.Image.hdr.dime.pixdim(3)*img_size(2);
            else
                vol1.Image.hdr.hist.srow_y(4) = vol1.Image.hdr.dime.pixdim(3)*img_size(2);
            end

            if vol1.Image.hdr.hist.srow_z(3) > 0
                vol1.Image.hdr.hist.srow_z(4) = -vol1.Image.hdr.dime.pixdim(4)*img_size(3);
            else
                vol1.Image.hdr.hist.srow_z(4) = vol1.Image.hdr.dime.pixdim(4)*img_size(3);
            end
            

            % Then find the center of vol2 (MRI)
            center_of_vol2_voxel_coordinates = [size(vol2.Image.img,1)/2, size(vol2.Image.img,2)/2, size(vol2.Image.img,3)/2];
            center_of_vol2_ras_coordinates   = [vol2.Image.hdr.hist.srow_x; vol2.Image.hdr.hist.srow_y; vol2.Image.hdr.hist.srow_z; [0 0 0 1]]*[center_of_vol2_voxel_coordinates, 1]';
            center_of_vol2_ras_coordinates   = center_of_vol2_ras_coordinates(1:3);
            
            % Then move center of vol1 (CT) to center of vol2 (MRI)
            vol1.Image.hdr.hist.srow_x(4)=vol1.Image.hdr.hist.srow_x(4) + center_of_vol2_ras_coordinates(1);
            vol1.Image.hdr.hist.srow_y(4)=vol1.Image.hdr.hist.srow_y(4) + center_of_vol2_ras_coordinates(2);
            vol1.Image.hdr.hist.srow_z(4)=vol1.Image.hdr.hist.srow_z(4) + center_of_vol2_ras_coordinates(3);
        end
    end
end

