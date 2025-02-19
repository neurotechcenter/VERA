classdef ElectrodeOrderGUI < uix.Grid & handle
    %ElectrodeOrderGUI GUI to run Reorderelectrodes
    properties 
    end
    properties (Access = protected)
        elSelection
        brainView
        elocViewList
        eDefinitions
        eLocations
        btnClinical
        btnUp
        btnDown
        curSurf
    end
    
    properties (Access = private)
        buttonActivity 
    end
    
    methods
        function obj = ElectrodeOrderGUI(varargin)
                obj.buttonActivity=struct('IsPressed',false,'PointIndex',0,'Button',0);
                obj.elocViewList={};
                flexb=uix.HBoxFlex('Parent',obj);
                selPanel=uix.Panel('Parent',flexb,'Title','Select Correct Definition');
                selV=uix.VBox('Parent',selPanel);
                mainviewBox=uix.HBox('Parent',selV);
                
                selBox=uix.HBox('Parent',mainviewBox);
                obj.elSelection=uicontrol(selBox,'Style','listbox','Min',0,'Max',2,'callback',@(~,~)obj.selectionChanged());%enable multiselect
                uicontrol(selV,'Style','pushbutton','String','Accept','callback',@(~,~)close(obj.Parent));
                buttonBox=uix.VBox('Parent',selBox);
                uicontrol(buttonBox,'Style','pushbutton','String','Up','callback',@(~,~)obj.resortElUp());
                uicontrol(buttonBox,'Style','pushbutton','String','Down','callback',@(~,~)obj.resortElDown());
                uix.Empty('Parent',buttonBox);
                buttonBox.Heights=[-0.15 -0.15 -0.7];
                selBox.Widths=[-0.9 -0.1];
                
                controlsBox=uix.Grid('Parent',flexb);
                p=uicontainer('Parent',controlsBox);
                obj.brainView=axes('Parent',p,'Color','k');
                flexb.Units='normalized';
                
                
                flexb.Widths=[-0.3 -0.7];
                selV.Heights=[-0.9,-0.1];
                buttonBox=uix.Grid('Parent',controlsBox);
                uicontrol(buttonBox,'Style','pushbutton','String','Auto-Sort','callback',@(~,~)obj.autosort());
                uicontrol(buttonBox,'Style','pushbutton','String','Re-sort Indices','callback',@(~,~)obj.resort());
                buttonBox.Widths=[-1 -1];
                buttonBox.Heights=[-1];   
                btngrp=uibuttongroup('Parent',controlsBox,'SelectionChangedFcn',@(~,~)obj.selectionChanged());
                obj.btnClinical=uicontrol(btngrp,'Style','radiobutton','String','Clinical Numbering Scheme','Max',true,'Min',false,'Value',true,'Position',[0 0 150 50]);
                uicontrol(btngrp,'Style','radiobutton','String','Research Numbering Scheme','Position',[150 0 250 50]);
                controlsBox.Widths=[-1];
                controlsBox.Heights=[-0.9 -0.05 -0.1];                
                
            try
                uix.set( obj, varargin{:} )
            catch e
                delete( obj )
                e.throwAsCaller()
            end
            cameratoolbar(ancestor(obj,'figure'),'NoReset');
        end
        
        function setBrainSurface(obj,surf)
                 cla(obj.brainView);
                 obj.curSurf=surf;
                 if(~isempty(surf))
                     [annotation_remap,cmap]=createColormapFromAnnotations(obj.curSurf);
                     mp=plot3DModel(obj.brainView,obj.curSurf.Model,annotation_remap);
                     alpha(mp,0.1);
                     colormap(obj.brainView,cmap);
                 end
                   % trisurf(surface.Model.tri, surface.Model.vert(:, 1), surface.Model.vert(:, 2), surface.Model.vert(:, 3),annotation_remap ,'Parent',obj.axModel,settings{:});
                 
        end
        
        function setElectrodes(obj,eDef,eLoc)
            obj.eDefinitions=eDef;
            obj.eLocations=eLoc;
            obj.elSelection.String={eDef.Definition.Name};
            obj.selectionChanged();
        end
        
        
        function selectionChanged(obj)
            if(~isempty(obj.elocViewList))
                delete([obj.elocViewList{:}]);
                obj.elocViewList={};
            end
             hold(obj.brainView,'on');
            vals=obj.elSelection.Value;
            sc=scatter3(obj.brainView,obj.eLocations.Location(:,1),obj.eLocations.Location(:,2),obj.eLocations.Location(:,3),'filled','k');
            alpha(sc,0);
           % axHidden = axes(obj.brainView.Parent,'Visible','off','hittest','off'); % Invisible axes
            %linkprop([obj.brainView axHidden],{'CameraPosition' 'XLim' 'YLim' 'ZLim' 'Position'}); % The axes should stay aligned
 
            obj.elocViewList={};
            for iv=1:length(vals)
                elLoc=obj.eLocations.Location(obj.eLocations.DefinitionIdentifier == vals(iv),:);
                if(obj.btnClinical.Value)
                    elString=arrayfun(@num2str, 1:obj.eDefinitions.Definition(vals(iv)).NElectrodes, 'UniformOutput', 0);
                else
                    elString=arrayfun(@num2str, find(obj.eLocations.DefinitionIdentifier == vals(iv)), 'UniformOutput', 0);
                end
                
               
                
                for ieloc=1:size(elLoc,1)
                    
                    obj.elocViewList{end+1}=text(obj.brainView,elLoc(ieloc,1),elLoc(ieloc,2),elLoc(ieloc,3),elString{ieloc},'FontSize',8,'BackgroundColor','w');
                end
                
               
            end
            hold(obj.brainView,'off');
            drawnow();
            
        end
        
        
        function resortElDown(obj)
             vals=obj.elSelection.Value;
             for iv=1:length(vals)
                 if(length(obj.eDefinitions.Definition) ==vals(iv))
                     break;
                 end
                 pos1=find(obj.eLocations.DefinitionIdentifier == vals(iv));
                 pos2=find(obj.eLocations.DefinitionIdentifier == (vals(iv)+1));
                 newPos1=pos1+length(pos2);
                 newPos2=pos2-length(pos1);
                 eLocs1=obj.eLocations.Location(pos1,:);
                 eLocs2=obj.eLocations.Location(pos2,:);

                 labelPos1=obj.eLocations.Label(pos1);
                 labelPos2=obj.eLocations.Label(pos2);
                 
                 obj.eLocations.Location(newPos1,:)=eLocs1;
                 obj.eLocations.DefinitionIdentifier(newPos1)=vals(iv)+1;
                 
                 obj.eLocations.Label(newPos1)=labelPos1;
                 
                 obj.eLocations.Location(newPos2,:)=eLocs2;
                 obj.eLocations.DefinitionIdentifier(newPos2)=(vals(iv));
                  
                 obj.eLocations.Label(newPos2)=labelPos2;                
                 
                 def1=obj.eDefinitions.Definition(vals(iv));
                 obj.eDefinitions.Definition(vals(iv))=obj.eDefinitions.Definition(vals(iv)+1);
                 obj.eDefinitions.Definition(vals(iv)+1)=def1;
                 
                 if(~isempty(fieldnames(obj.eLocations.Annotation)))
                     annotPos1=obj.eLocations.Annotation(pos1);
                     annotPos2=obj.eLocations.Annotation(pos2);
                     obj.eLocations.Annotation(newPos1)=annotPos1;
                     obj.eLocations.Annotation(newPos2)=annotPos2;
                 end
             end
             obj.elSelection.String={obj.eDefinitions.Definition.Name};
             obj.elSelection.Value=unique(min(obj.elSelection.Value+1,length(obj.eDefinitions.Definition)));
             obj.selectionChanged();
        end
        
        function resortElUp(obj)
             vals=obj.elSelection.Value;
             for iv=1:length(vals)
                 if(1 ==vals(iv))
                     break;
                 end
                 pos1=find(obj.eLocations.DefinitionIdentifier == vals(iv));
                 pos2=find(obj.eLocations.DefinitionIdentifier == (vals(iv)-1));
                 newPos1=pos1-length(pos2);
                 newPos2=pos2+length(pos1);
                 eLocs1=obj.eLocations.Location(pos1,:);
                 eLocs2=obj.eLocations.Location(pos2,:);

                 labelPos1=obj.eLocations.Label(pos1);
                 labelPos2=obj.eLocations.Label(pos2);
                 
                 obj.eLocations.Location(newPos1,:)=eLocs1;
                 obj.eLocations.DefinitionIdentifier(newPos1)=vals(iv)-1;
                 
                 obj.eLocations.Label(newPos1)=labelPos1;
                 
                 obj.eLocations.Location(newPos2,:)=eLocs2;
                 obj.eLocations.DefinitionIdentifier(newPos2)=(vals(iv));
                  
                 obj.eLocations.Label(newPos2)=labelPos2;                
                 
                 def1=obj.eDefinitions.Definition(vals(iv));
                 obj.eDefinitions.Definition(vals(iv))=obj.eDefinitions.Definition(vals(iv)-1);
                 obj.eDefinitions.Definition(vals(iv)-1)=def1;
                 
                 if(~isempty(fieldnames(obj.eLocations.Annotation)))
                     annotPos1=obj.eLocations.Annotation(pos1);
                     annotPos2=obj.eLocations.Annotation(pos2);
                     obj.eLocations.Annotation(newPos1)=annotPos1;
                     obj.eLocations.Annotation(newPos2)=annotPos2;
                 end
             end
             obj.elSelection.String={obj.eDefinitions.Definition.Name};
             obj.elSelection.Value=unique(max(obj.elSelection.Value-1,1));
             obj.selectionChanged();
        end
        
        function autosort(obj)
            vals=obj.elSelection.Value;
            for i=1:length(vals)
                elLoc=obj.eLocations.Location(obj.eLocations.DefinitionIdentifier == vals(i),:);
                [~,I]=sort(vecnorm(elLoc'));
                orig_idx=find(obj.eLocations.DefinitionIdentifier == vals(i));
                
                obj.eLocations.ResortElectrodes(orig_idx(I));

            end
            obj.selectionChanged();
        end
        
        function resort(obj)
            if(length(obj.elSelection.Value) == 1)
                elLoc=obj.eLocations.Location(obj.eLocations.DefinitionIdentifier == obj.elSelection.Value,:);
                
                com=mean(elLoc,1);
                f=figure;
                [annotation_remap,cmap]=createColormapFromAnnotations(obj.curSurf);
                mp=plot3DModel(gca,obj.curSurf.Model,annotation_remap);
                alpha(mp,0.1);
                colormap(gca,cmap);
                removeToolbarExplorationButtons(f);
                cameratoolbar(f,'NoReset');
                hold on;
                scatter3(elLoc(:,1), elLoc(:,2), elLoc(:,3),'ko','filled'); 
                
                set(f, 'WindowButtonDownFcn', {@(a,b,c)obj.callbackClickA3DPoint(a,b,c), elLoc'}); 
%                 if(psupLabelPos(2) < pmsupLabelPos(2))
%                 set(gca,'ydir','reverse');
%                 end
%                 if(pantLabelPos(1) < pmantLabelPos(1))
%                     set(gca,'xdir','reverse');
%                 end
                
                sortMap=zeros(size(elLoc,1),1);
                labelMap=zeros(size(elLoc,1),1);
                searchI=1;
                while(any(sortMap == 0) && ishandle(f))
                    title(['Please select Electrode number ' num2str(searchI)]);
                    [closestPIdx,button]=obj.wait3dPointClick(f);
                    if(button ==1)
                        if(any(sortMap == closestPIdx))
                            disp(['Replacing point ' num2str(find(sortMap == closestPIdx))]);
                            if(labelMap(sortMap == closestPIdx) ~= 0)
                                delete(labelMap(sortMap == closestPIdx));
                                labelMap(sortMap == closestPIdx)=0;
                            end
                            sortMap(sortMap == closestPIdx)=0;
                        end
                        sortMap(searchI)=closestPIdx;
                        labelMap(searchI)=text(elLoc(closestPIdx,1),elLoc(closestPIdx,2),elLoc(closestPIdx,3),num2str(searchI),'FontSize',8,'BackgroundColor','w');
                    elseif(button == 2)
                        if(labelMap(sortMap == closestPIdx) ~= 0)
                            disp(['Deleting point ' num2str(find(sortMap == closestPIdx))])
                            delete(labelMap(sortMap == closestPIdx));
                            labelMap(sortMap == closestPIdx)=0;
                        end
                        sortMap(sortMap == closestPIdx)=0;
                    end
                    searchI=find(sortMap == 0,1);
                end
                close(f);
%                 [~,sortI]=sort(elLoc(:,2));
%                 start=find(obj.eLocations.DefinitionIdentifier == obj.elSelection.Value,1)-1;
%                 obj.eLocations.Location(start+sortI,:)=elLoc;
%                 obj.selectionChanged();
                origIdx=find(obj.eLocations.DefinitionIdentifier == obj.elSelection.Value);    
                obj.eLocations.ResortElectrodes(origIdx(sortMap));
%                obj.eLocations.Location(obj.eLocations.DefinitionIdentifier == obj.elSelection.Value,:)=elLoc(sortMap,:);
                obj.selectionChanged();
            end
        end
        
        %function elSelClick(obj,)
        
        
        
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

            h = findobj(gca,'Tag','pt'); % try to find the old point
            selectedPoint = pointCloud(:, pointCloudIndex); 

            if isempty(h) % if it's the first click (i.e. no previous point to delete)

                % highlight the selected point
                h = plot3(selectedPoint(1,:), selectedPoint(2,:), ...
                    selectedPoint(3,:), 'r.', 'MarkerSize', 20); 
                set(h,'Tag','pt'); % set its Tag property for later use   

            else % if it is not the first click

                delete(h); % delete the previously selected point

                % highlight the newly selected point
                h = plot3(selectedPoint(1,:), selectedPoint(2,:), ...
                    selectedPoint(3,:), 'r.', 'MarkerSize', 20);  
                set(h,'Tag','pt');  % set its Tag property for later use

            end
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

