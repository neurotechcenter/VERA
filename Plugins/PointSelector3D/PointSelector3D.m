classdef PointSelector3D < AComponent
    %POINTSELECTOR3D Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        PointDefinitionIdentifier
        ModelIdentifier
    end
    properties (Access = private)
        buttonActivity
    end
    
    methods
        function obj = PointSelector3D()
            obj.PointDefinitionIdentifier='ElectrodeLocation';
            obj.ModelIdentifier='Surface';
            obj.buttonActivity=struct('IsPressed',false,'PointIndex',0,'Button',0);
        end
        
        function Publish(obj)
            obj.AddInput(obj.ModelIdentifier,'Surface');
            obj.AddOutput(obj.PointDefinitionIdentifier,'ElectrodeLocation');
        end
        
        function Initialize(obj)
        end
        
        function points=Process(obj,surf)
            points=obj.CreateOutput(obj.PointDefinitionIdentifier);
            
            f=figure;
            cameratoolbar(f,'NoReset');
            
            set(f, 'WindowButtonDownFcn', {@(a,b,c)obj.callbackClickA3DPoint(a,b,c), surf.Model.vert'}); 
            [annotation_remap,cmap]=createColormapFromAnnotations(surf);
            mp=plot3DModel(gca,surf.Model,annotation_remap);
            alpha(mp,0.3)
            hold on;
            colormap(gca,cmap);
            cont=true;
            while(cont)
                [closestPIdx,button]=obj.wait3dPointClick(f);
                if(button ==1)
                    
                    points.Location(end+1,:)=surf.Model.vert(closestPIdx,:);
                    plotBallsOn3DImage(gca,surf.Model.vert(closestPIdx,:),[],2);
                else
                    cont=false;
                end
            end
            close(f);
            
        end
        
        
        function [idx,button]=wait3dPointClick(obj,fig)
            obj.buttonActivity.IsPressed=false;
            obj.buttonActivity.PointIndex=0;
            obj.buttonActivity.Button=0;
            while(~obj.buttonActivity.IsPressed && ishandle(fig))
                pause(0.01);
            end
            idx=obj.buttonActivity.PointIndex;
            button=obj.buttonActivity.Button;
        end
        
        
        function callbackClickA3DPoint(obj,src, eventData, pointCloud)
        % CALLBACKCLICK3DPOINT mouse click callback function for CLICKA3DPOINT
        %
        %   The transformation between the viewing frame and the point cloud frame
        %   is calculated using the camera viewing direction and the 'up' vector.
        %   Then, the point cloud is transformed into the viewing frame. Finally,
        %   the z coordinate in this frame is ignored and the x and y coordinates
        %   of all the points are compared with the mouse click location and the 
        %   closest point is selected.
        %
        %   Babak Taati - May 4, 2005
        %   revised Oct 31, 2007
        %   revised Jun 3, 2008
        %   revised May 19, 2009

            point = get(gca, 'CurrentPoint'); % mouse click position
            camPos = get(gca, 'CameraPosition'); % camera position
            camTgt = get(gca, 'CameraTarget'); % where the camera is pointing to

            camDir = camPos - camTgt; % camera direction
            camUpVect = get(gca, 'CameraUpVector'); % camera 'up' vector

            % build an orthonormal frame based on the viewing direction and the 
            % up vector (the "view frame")
            zAxis = camDir/norm(camDir);    
            upAxis = camUpVect/norm(camUpVect); 
            xAxis = cross(upAxis, zAxis);
            yAxis = cross(zAxis, xAxis);

            rot = [xAxis; yAxis; zAxis]; % view rotation 

            % the point cloud represented in the view frame
            rotatedPointCloud = rot * pointCloud; 

            % the clicked point represented in the view frame
            rotatedPointFront = rot * point' ;

            % find the nearest neighbour to the clicked point 
            pointCloudIndex = dsearchn(rotatedPointCloud(1:2,:)', ... 
                rotatedPointFront(1:2));


            obj.buttonActivity.PointIndex=pointCloudIndex;
            if(strcmp(src.SelectionType,'normal'))
                obj.buttonActivity.Button=1;
            else
                obj.buttonActivity.Button=2;
            end
            obj.buttonActivity.IsPressed=true;
            fprintf('you clicked on point number %d\n', pointCloudIndex);
        end
    end
end

