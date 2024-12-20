classdef PointSelector3D < AComponent
    %PointSelector3D Allows manual definition of points
    
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
            obj.buttonActivity=struct('IsPressed',false,'Point',0,'Button',0);
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
            
            [annotation_remap,cmap]=createColormapFromAnnotations(surf);
            mp=plot3DModel(gca,surf.Model,annotation_remap);
            mp.ButtonDownFcn=@(x,y)obj.callbackClickA3DPoint(x,y);
            alpha(mp,0.3)
            hold on;
            colormap(gca,cmap);
            cont=true;
            while(cont)
                button=2;
                [point,button]=obj.wait3dPointClick(f);
                switch(button)
                    case 1
                        points.Location(end+1,:)=point;
                        plotBallsOn3DImage(gca,point,[],2);
                    case 2
                        cont=false;
                    case 3
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
            idx=obj.buttonActivity.Point;
            button=obj.buttonActivity.Button;
        end
        
        
        function callbackClickA3DPoint(obj,src, eventData)
        % CALLBACKCLICK3DPOINT mouse click callback function for CLICKA3DPOINT
        % using https://www.mathworks.com/matlabcentral/fileexchange/7191-rbb3select
        x = src.XData; 
        y = src.YData; 
        z = src.ZData; 
        pt = eventData.IntersectionPoint;       % The (x0,y0,z0) coordinate you just selected
        coordinates = [x(:),y(:),z(:)];     % matrix of your input coordinates
        dist = pdist2(pt,coordinates);      %distance between your selection and all points
        [~, minIdx] = min(dist);            % index of minimum distance to points
        coordinateSelected = coordinates(minIdx,:); %the selected coordinate
        % from here you can do anything you want with the output.  This demo
        % just displays it in the command window.  
       % fprintf('[x,y,z] = [%.5f, %.5f, %.5f]\n', coordinateSelected)


            obj.buttonActivity.Point=coordinateSelected;

            obj.buttonActivity.Button=eventData.Button;

            obj.buttonActivity.IsPressed=true;
            %fprintf('you clicked on point number %d\n', pointCloudIndex);
        end
    end
end

