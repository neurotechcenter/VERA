classdef AlterElectrodeLabels < AComponent
    %AlterElectrodeLabels - Component to swap the Electrode Label between
    %Grids/Strips/Depth electrodes with identical properties
    
    properties
        ElectrodeDefinitionIdentifier %Data Identifier for Electrode Definition
        ElectrodeLocationIdentifier % Data Identifier for Electrode Location
        SurfaceIdentifier % Optional Input Surface Data 
        NewLabelIds 
    end
    
    properties (Access = protected)
        acceptId
    end
    methods
        function obj = AlterElectrodeLabels()
            obj.ElectrodeDefinitionIdentifier='ElectrodeDefinition';
            obj.ElectrodeLocationIdentifier='ElectrodeLocation';
            obj.SurfaceIdentifier='Surface';
            
        end
        
        function Publish(obj)
            obj.AddInput(obj.ElectrodeDefinitionIdentifier,'ElectrodeDefinition');
            obj.AddInput(obj.ElectrodeLocationIdentifier,'ElectrodeLocation');
            obj.AddOptionalInput(obj.SurfaceIdentifier,'Surface');
            obj.AddOutput(obj.ElectrodeLocationIdentifier,'ElectrodeLocation');
        end
        
        function Initialize(obj)
        end
        
        function [eLoc]=Process(obj,eDef,eLoc,varargin)
            if(length(varargin) == 2)
                surf=varargin{2};
            else
                surf=[];
            end
            grpDef=eDef.GetGroupedDefinitions();
            if(length(obj.NewLabelIds) ~= length(eDef.Definition))
                missing_idx=setdiff(obj.NewLabelIds,1:length(eDef.Definition));
                obj.NewLabelIds=[obj.NewLabelIds(:) missing_idx(:)];
            end
            for iEl=1:length(grpDef)
               if(length(grpDef(iEl).Id) > 1)
                   eLoc=selectCorrectLabel(obj,surf,eLoc,grpDef(iEl));
               end
            end
            
            %check if there are multiple definitions that could be shuffled
        end


        function eLoc=selectCorrectLabel(obj,surf,eLoc,grpDef)
            idef=intersect(eLoc.DefinitionIdentifier,grpDef.Id);
            inewDef=zeros(length(idef),1);
            
            for i=1:length(idef)
                selfig=figure('MenuBar', 'none', ...
                'Toolbar', 'none');
                cameratoolbar(selfig,'NoReset');
                flexb=uix.HBoxFlex('Parent',selfig);
                selPanel=uix.Panel('Parent',flexb,'Title','Select Correct Definition');
                selV=uix.VBox('Parent',selPanel);
                elSelection=uicontrol(selV,'Style','listbox');
                uicontrol('Style','pushbutton','Parent',selV,'String','Accept','Callback',@(~,~)obj.acceptFcn(selfig,elSelection));
                uicontrol('Style','pushbutton','Parent',selV,'String','Delete','Callback',@(~,~)obj.deleteFcn(selfig,elSelection));
                elSelection.String=grpDef.Name;
                elView=axes('Parent',flexb);
                flexb.Units='normalized';
                flexb.Widths=[-0.3 -0.7];
                selV.Heights=[-0.9,-0.05 -0.05];
                obj.acceptId= 0;

                if(~isempty(surf))
                   [annotation_remap,cmap]=createColormapFromAnnotations(surf);
                    mp=plot3DModel(elView,surf.Model,annotation_remap);
                    alpha(mp,0.3);
                   % trisurf(surface.Model.tri, surface.Model.vert(:, 1), surface.Model.vert(:, 2), surface.Model.vert(:, 3),annotation_remap ,'Parent',obj.axModel,settings{:});
                    colormap(elView,cmap);
                end

                plotBallsOnVolume(elView,eLoc.Location(idef(i) ~= eLoc.DefinitionIdentifier,:),[0 0 0],2);
                plotBallsOnVolume(elView,eLoc.Location(idef(i) == eLoc.DefinitionIdentifier,:),[1 1 0],4);
                waitfor(selfig);
                if(obj.acceptId>0)
                    inewDef(i)=(obj.acceptId);
                else
                    eLoc.Location(eLoc.DefinitionIdentifier == idef(i),:)=[];
                    eLoc.DefinitionIdentifier(eLoc.DefinitionIdentifier == idef(i))=[];
                    inewDef(i)=-1;
                end
                
                
            end

            for i=1:length(idef)
                if(inewDef(i) > 0)
                    eLoc.DefinitionIdentifier(eLoc.DefinitionIdentifier == idef(i))=grpDef.Id(inewDef(i));
                end
            end

        end

        function acceptFcn(obj,f,idSel)
            obj.acceptId=idSel.Value;
            close(f);
        end
        
        function deleteFcn(obj,f,idSel)
            obj.acceptId=-1;
            close(f);
        end
    end

end

