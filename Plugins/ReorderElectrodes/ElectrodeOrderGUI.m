classdef ElectrodeOrderGUI < uix.Grid & handle
    %ELECTRODEORDERGUI Summary of this class goes here
    %   Detailed explanation goes here
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
    end
    
    methods
        function obj = ElectrodeOrderGUI(varargin)
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
                
                uicontrol(controlsBox,'Style','pushbutton','String','Re-sort Indices','callback',@(~,~)obj.resort());
                btngrp=uibuttongroup('Parent',controlsBox,'SelectionChangedFcn',@(~,~)obj.selectionChanged());
                obj.btnClinical=uicontrol(btngrp,'Style','radiobutton','String','Clinical Numbering Scheme','Max',true,'Min',false,'Value',true,'Position',[0 0 150 50]);
                uicontrol(btngrp,'Style','radiobutton','String','Research Numbering Scheme','Position',[150 0 250 50]);
                controlsBox.Widths=[-1];
                controlsBox.Heights=[-0.9 -0.1 -0.1];                
                
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
                 if(~isempty(surf))
                     [annotation_remap,cmap]=createColormapFromAnnotations(surf);
                     mp=plot3DModel(obj.brainView,surf.Model,annotation_remap);
                     alpha(mp,0.3);
                     colormap(obj.brainView,cmap);
                 end
                   % trisurf(surface.Model.tri, surface.Model.vert(:, 1), surface.Model.vert(:, 2), surface.Model.vert(:, 3),annotation_remap ,'Parent',obj.axModel,settings{:});
                 
        end
        
        function setElectrodes(obj,eDef,eLoc)
            obj.eDefinitions=eDef;
            obj.eLocations=eLoc;
            obj.elSelection.String={eDef.Definition.Name};
        end
        
        
        function selectionChanged(obj)
            if(~isempty(obj.elocViewList))
                delete([obj.elocViewList{:}]);
                obj.elocViewList={};
            end
             hold(obj.brainView,'on');
            vals=obj.elSelection.Value;
            sc=scatter3(obj.brainView,obj.eLocations.Location(:,1),obj.eLocations.Location(:,2),obj.eLocations.Location(:,3),'k');
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
                 obj.eLocations.Location(newPos1,:)=eLocs1;
                 obj.eLocations.DefinitionIdentifier(newPos1)=vals(iv)+1;
                 obj.eLocations.Location(newPos2,:)=eLocs2;
                 obj.eLocations.DefinitionIdentifier(newPos2)=(vals(iv));
                 def1=obj.eDefinitions.Definition(vals(iv));
                 obj.eDefinitions.Definition(vals(iv))=obj.eDefinitions.Definition(vals(iv)+1);
                 obj.eDefinitions.Definition(vals(iv)+1)=def1;
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
                 obj.eLocations.Location(newPos1,:)=eLocs1;
                 obj.eLocations.DefinitionIdentifier(newPos1)=vals(iv)-1;
                 obj.eLocations.Location(newPos2,:)=eLocs2;
                 obj.eLocations.DefinitionIdentifier(newPos2)=(vals(iv));
                 def1=obj.eDefinitions.Definition(vals(iv));
                 obj.eDefinitions.Definition(vals(iv))=obj.eDefinitions.Definition(vals(iv)-1);
                 obj.eDefinitions.Definition(vals(iv)-1)=def1;
             end
             obj.elSelection.String={obj.eDefinitions.Definition.Name};
             obj.elSelection.Value=unique(max(obj.elSelection.Value-1,1));
             obj.selectionChanged();
        end
        
        function resort(obj)
            if(length(obj.elSelection.Value) == 1)
                elLoc=obj.eLocations.Location(obj.eLocations.DefinitionIdentifier == obj.elSelection.Value,:);
                
                com=mean(elLoc,1);

                supLabelPos=com + [0 0 com(3)-max(elLoc(:,3))];
                antLabelPos=com + [0 com(2)-max(elLoc(:,2)) 0];
                rLabelPos=com + [com(1)-max(elLoc(:,1)) 0 0];
                 if(strcmp(obj.eDefinitions.Definition(obj.elSelection.Value).Type,'Grid'))
                     [coeff,score]=pca(elLoc);
                 else
                    score=elLoc;
                 end
                

                
             %   xybase=elLoc(:,1:3).*coeff(:,1:3)';
                
                 limitX=xlim();
                 limitY=ylim();
                 if(strcmp(obj.eDefinitions.Definition(obj.elSelection.Value).Type,'Grid'))
                     psupLabelPos=(supLabelPos/coeff');
                     pmsupLabelPos=((-supLabelPos)/coeff');
                     pantLabelPos=(antLabelPos/coeff');
                     pmantLabelPos=((-antLabelPos)/coeff');
                     prLabelPos=(rLabelPos/coeff');
                 else
                     psupLabelPos=(supLabelPos);
                     pmsupLabelPos=(-supLabelPos);
                     pantLabelPos=(antLabelPos);
                     pmantLabelPos=((-antLabelPos));
                     prLabelPos=(rLabelPos);
                 end
                theta = - atan((pantLabelPos(2))/(pantLabelPos(1)));
                R = [cos(theta) -sin(theta); sin(theta) cos(theta)];
                for i=1:size(score,1), score(i,1:2)=(R*score(i,1:2)')'; end
                selfig=figure;scatter(score(:,1),score(:,2));
                psupLabelPos(1:2)=(R*psupLabelPos(1:2)')';
                pantLabelPos(1:2)=(R*pantLabelPos(1:2)')';
                prLabelPos(1:2)=(R*prLabelPos(1:2)')'; 
                %psupLabelPos=R*psupLabelPos;
               % pantLabelPos=R*pantLabelPos;
               % prLabelPos=R*prLabelPos;
               hold on;
                text(psupLabelPos(1),psupLabelPos(2),'Superior');
                text(pantLabelPos(1),pantLabelPos(2),'Anterior');
                text(prLabelPos(1),prLabelPos(2),'Right');
                xlim([min([limitX(1) pantLabelPos(1) prLabelPos(1)]) max([limitX(2) pantLabelPos(1) prLabelPos(1)])]);
                xlim([min([limitY(1) pantLabelPos(2) prLabelPos(2)]) max([limitY(2) pantLabelPos(2) prLabelPos(2)])]);
%                 if(psupLabelPos(2) < pmsupLabelPos(2))
%                     set(gca,'ydir','reverse');
%                 end
%                 if(pantLabelPos(1) < pmantLabelPos(1))
%                     set(gca,'xdir','reverse');
%                 end
                
                sortMap=zeros(length(elLoc),1);
                labelMap=zeros(length(elLoc),1);
                searchI=1;
                while(any(sortMap == 0))
                    title(['Please select Electrode number ' num2str(searchI)]);
                    [x,y,button]=ginput(1);
                    [~,closestPIdx]=min((score(:,1)-x).^2 + (score(:,2)-y).^2);
                    disp(['Closest point index'  num2str(closestPIdx)]);
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
                        labelMap(searchI)=text(score(closestPIdx,1),score(closestPIdx,2),num2str(searchI));
                    elseif(button == 3)
                        if(labelMap(sortMap == closestPIdx) ~= 0)
                            disp(['Deleting point ' num2str(find(sortMap == closestPIdx))])
                            delete(labelMap(sortMap == closestPIdx));
                            labelMap(sortMap == closestPIdx)=0;
                        end
                        sortMap(sortMap == closestPIdx)=0;
                    end
                    searchI=find(sortMap == 0,1);
                end
                close(selfig);
%                 [~,sortI]=sort(elLoc(:,2));
%                 start=find(obj.eLocations.DefinitionIdentifier == obj.elSelection.Value,1)-1;
%                 obj.eLocations.Location(start+sortI,:)=elLoc;
%                 obj.selectionChanged();
                obj.eLocations.Location(obj.eLocations.DefinitionIdentifier == obj.elSelection.Value,:)=elLoc(sortMap,:);
                obj.selectionChanged();
            end
        end
        
        %function elSelClick(obj,)
        
        
        
        

    end
end

