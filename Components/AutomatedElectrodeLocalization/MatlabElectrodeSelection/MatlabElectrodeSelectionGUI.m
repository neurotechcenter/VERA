classdef MatlabElectrodeSelectionGUI < uix.HBoxFlex
    %MATLABELECTRODESELECTIONGUI GUI for semi automated electrode
    %Localization
    
    properties (Access = protected)
        minThresh % CT Threshold
        ax3D % Axis for 3D view
        Volume % CT 
        
        %Slider Definitions
        slMinThresh
        slBrainAlpha
        
        volProps %Properties of regionprops
        
        brainSurf % 3D Brain Model
        axSurf % 3D Brain on axis (trisurf)
        
        uiGrid % Main Grid for 3D View and Sliders
        uiTree % Tree view for selection
         
        elLocations % Electrode Locations
        
        selElectrodeDefinition %Index of selected electrode Definitio in Tree
        elDefintion % Available electrode definitions
        
        elPatches % Patches displated in ax3D using volProps Data
        
        
    end
    
    methods
        function obj = MatlabElectrodeSelectionGUI(varargin)
            
            cameratoolbar(gcf,'NoReset');
            removeToolbarExplorationButtons(gcf);
            set(obj,'BackgroundColor','k');
            obj.uiTree=uiw.widget.Tree('Parent',obj,'MouseClickedCallback',@obj.treeClick);
            obj.uiTree.Root.Name='Electrodes';
            obj.uiGrid=uix.Grid('Parent',obj);
            obj.Widths=[100 -1];
            obj.ax3D=axes('Parent',obj.uiGrid,'Units','normalized','Color','k');
            obj.slMinThresh=uicontrol('Parent',obj.uiGrid,'Style','slider','Min',0,'Max',1,'Value',1,'Callback',@obj.setMinThresh);
            obj.slBrainAlpha=uicontrol('Parent',obj.uiGrid,'Style','slider','Min',0,'Max',1,'Value',0.2,'SliderStep',[1/100 1/100],'Callback',@obj.setBrainAlpha);
            obj.uiGrid.Heights=[-1,18,18];
            obj.elLocations=ElectrodeLocation();
            obj.selElectrodeDefinition=0;
            obj.elPatches={};
            try
                uix.set( obj, varargin{:} )
            catch e
                delete( obj )
                e.throwAsCaller()
            end
            %set(gcf, 'WindowButtonDownFcn', {@(a,b)obj.callbackClickA3DPoint(a,b)}); 
        end
        
        function SetSurface(obj,surf)
             obj.brainSurf=surf;
            if(isempty(surf))
            else
                obj.brainSurf=surf;
                obj.axSurf=plot3DModel(obj.ax3D,obj.brainSurf.Model);
                alpha(obj.axSurf,obj.slBrainAlpha.Value);
                set(obj.axSurf,'HitTest','off');
            end
        end
        
        function SetElectrodeLocation(obj,eLoc)
            obj.elLocations=eLoc;
        end
        
        function SetElectrodeDefintion(obj,elDef)
            obj.elDefintion=elDef;
            for i=1:length(elDef.Definition)
                uiw.widget.TreeNode('Name',...
                    [elDef.Definition(i).Name ' (' num2str(sum(obj.elLocations.DefinitionIdentifier == i)) '/' num2str(elDef.Definition(i).NElectrodes) ')'],...
                    'Parent',obj.uiTree.Root,'UserData',i,'UIContextMenu',obj.buildContextMenu(i));
                

            end
        end
        
        function elLoc=GetElectrodeLocations(obj)
            elLoc=obj.elLocations;

        end
        
        function SetVolume(obj,vol)
            obj.Volume=vol;
            obj.slMinThresh.Min=min(min(min(vol.Image.img)));
            obj.slMinThresh.Max=max(max(max(vol.Image.img)));
            obj.slMinThresh.Value=obj.slMinThresh.Max-20;
            obj.updateView();
        end
        
    end

    
    methods (Access = protected)
        
                
        function cm=buildContextMenu(obj,elDefIdx)
                cm = uicontextmenu(gcf);
                uimenu(cm,'Text','Find Grid','Callback', @(~,~) obj.findConnectedElectrodes(elDefIdx));
        end
        
        function findConnectedElectrodes(obj,elDefIdx)
            disp(['Running automated Detection on: ' obj.elDefintion.Definition(elDefIdx).Type ' ' obj.elDefintion.Definition(elDefIdx).Name]);
            
            elMask=obj.elLocations.DefinitionIdentifier == elDefIdx;
            locs=obj.elLocations.Location(elMask,:);
            if(isempty(locs))
                Error('The automated detection Algorithm requires at least 1 electrode preselected. Preferable an Edge Location');
            end
            o.Display='iter';
            o.PlotFcns=[];
            o.OutputFcn=[];
            
            centroids=obj.getRASCentroids();
            %remove centroids already used
            usedelMask=obj.elLocations.DefinitionIdentifier ~= elDefIdx;
            occupiedLocs=obj.elLocations.Location(usedelMask,:);
            occIdx=zeros(occupiedLocs,1);
            for i=1:size(occupiedLocs,1)
                occIdx(i)=obj.findPrevSelectedPoint(pointCloud(centroids),occupiedLocs(i,:));
            end
            centroids(occIdx,:)=[];
            bNames=1:size(centroids,1);
            gvar=0.2;
            gdist=obj.elDefintion.Definition(elDefIdx).Spacing;
            found_locs=cell(size(locs,1),1);
            numElFound=zeros(size(locs,1),1);
            
            
            for iel=1:size(locs,1)
                pIdx(iel)=obj.findPrevSelectedPoint(pointCloud(centroids),locs(iel,:));
                lcentroids=centroids;
                lcentroids(pIdx(iel),:)=[];
                if(strcmp(obj.elDefintion.Definition(elDefIdx).Type,'Grid'))
                   % poss=findNeighbour(pIdx,locs(iel,:),lcentroids,90,bNames,gvar_best,gdist,true);
                    func=@(x)(numel(TraverseTree(findNeighbour(pIdx(iel),locs(iel,:),lcentroids,90,bNames,x,gdist,true),['A','B']))-obj.elDefintion.Definition(elDefIdx).NElectrodes).^2;
                else
                   % poss=findStripNeighbour(pIdx,locs(iel,:),lcentroids,bNames,gvar_best,gdist);
                    func=@(x)(numel(TraverseTree(findStripNeighbour(pIdx(iel),locs(iel,:),lcentroids,bNames,x,gdist),['A','B']))-obj.elDefintion.Definition(elDefIdx).NElectrodes).^2;
                end
                gvar_best=fminsearchbnd(func,gvar,0.05,0.2,o);
                if(strcmp(obj.elDefintion.Definition(elDefIdx).Type,'Grid'))
                   poss=findNeighbour(pIdx(iel),locs(iel,:),lcentroids,90,bNames,gvar_best,gdist,true);
                   % func=@(x)(numel(TraverseTree(findNeighbour(pIdx,locs(iel,:),lcentroids,90,bNames,x,gdist,true),['A','B']))-obj.elDefintion.Definition(elDefIdx).NElectrodes).^2;
                else
                   poss=findStripNeighbour(pIdx(iel),locs(iel,:),lcentroids,bNames,gvar_best,gdist);
                    %func=@(x)(numel(TraverseTree(findStripNeighbour(pIdx,locs(iel,:),lcentroids,bNames,x,gdist),['A','B']))-obj.elDefintion.Definition(elDefIdx).NElectrodes).^2;
                end

                found_locs{iel}=TraverseTree(poss,['A','B']);
                numElFound(iel)=numel(found_locs{iel});

                    
                
            end
            remList=[];
            for iel=1:size(locs,1)
                if(numel(intersect(found_locs{iel},pIdx)) < size(pIdx,1))
                    remList(end+1)=iel;
                end
            end
            numElFound(remList)=[];
            found_locs(remList)=[];
            [~,idx]=max(numElFound);
            if(isempty(numElFound))
                disp('No Electrodes found that match the criteria');
            else
                disp(['Electrodes found: ' num2str(numElFound(idx))]);
            end
            obj.elLocations.DefinitionIdentifier(elMask)=[];
            obj.elLocations.Location(elMask,:)=[];
            obj.elLocations.Location(end+1:end+numElFound(idx),:)=centroids(found_locs{idx},:);
            obj.elLocations.DefinitionIdentifier(end+1:end+numElFound(idx))=elDefIdx*ones(numElFound(idx),1);
            obj.uiTree.Root.Children(elDefIdx).Name = [obj.elDefintion.Definition(elDefIdx).Name ' (' num2str(sum(obj.elLocations.DefinitionIdentifier == elDefIdx)) ...
                    '/' num2str(obj.elDefintion.Definition(elDefIdx).NElectrodes) ')'];
            obj.colorPatches();            
            
        end
        

        
        function treeClick(obj,a,b)
            if(isprop(b,'Nodes') && any(isprop(b.Nodes,'UserData')) && ~isempty(b.Nodes.UserData) && strcmp(b.SelectionType,'normal'))
                obj.selElectrodeDefinition=b.Nodes.UserData;
                obj.colorPatches();
            else
                if(any(isprop(b.Nodes,'UserData')) && strcmp(b.SelectionType,'normal')) %make sure it is not the expander
                    obj.selElectrodeDefinition=0;
                    obj.colorPatches();
                end
            end
        end
        
        function setMinThresh(obj,hObject,eventdata,handles)
            obj.updateView();
        end
        
        
        function setBrainAlpha(obj,hObject,eventdata,handles)
            alpha(obj.axSurf,obj.slBrainAlpha.Value);
        end
        
        function updateView(obj)
            if(isempty(obj.Volume))
                return;
            end
            mb=msgbox('Recalculating Segmentation....');
            if(~isempty(obj.brainSurf))
                obj.axSurf=plot3DModel(obj.ax3D,obj.brainSurf.Model);
                alpha(obj.axSurf,obj.slBrainAlpha.Value);
                set(obj.axSurf,'HitTest','off');
                set(obj.axSurf,'PickableParts','none');
                hold(obj.ax3D,'on');
            end
            obj.elPatches={};
            V=permute(obj.Volume.Image.img,[2 1 3]);
            V(V < obj.slMinThresh.Value) = 0;
            V=smooth3(V,'box',3);
            V=(V > obj.slMinThresh.Value);
            %[x,y,z]=meshgrid(1:size(V,2),1:size(V,1),1:size(V,3));
            %fv=isosurface(x,y,z,V);
            %p=patch(obj.ax3D,fv,'FaceColor','w','LineStyle','none');
            obj.volProps=regionprops3(bwlabeln(V),'Volume','Centroid','BoundingBox');
            for i=1:size(obj.volProps.BoundingBox,1)
                obj.elPatches{i}=plotcube(obj.ax3D,obj.volProps.BoundingBox(i,4:6).*obj.Volume.Image.hdr.dime.pixdim(2:4),obj.Volume.Vox2Ras(obj.volProps.BoundingBox(i,1:3))',1,[1 0 0],@obj.callbackClickA3DPoint,i);
                hold(obj.ax3D,'on');
                
            end
            hold(obj.ax3D,'off');
            obj.colorPatches();
            close(mb);
        end
        
        function colorPatches(obj)
            
            for i=1:length(obj.elPatches)
                patches=obj.elPatches{i};
                for ip=1:length(patches)
                    patches(ip).FaceColor=[1 0 0];
                end
            end
            if(obj.selElectrodeDefinition > 0)
                elMask=obj.elLocations.DefinitionIdentifier == obj.selElectrodeDefinition;
                locs=obj.elLocations.Location(elMask,:);

                rasCentroids=obj.getRASCentroids();
                for i=1:size(locs,1) %check if loc is close enough to a patch
                    pIdx=obj.findPrevSelectedPoint(pointCloud(rasCentroids),locs(i,:));
                    if(~isempty(pIdx))
                        patches=obj.elPatches{pIdx};
                        for ip=1:length(patches)
                            patches(ip).FaceColor=[0 1 0];
                        end
                    else
                        warning('No Location found that is close enough');
                    end
                end
            end
        end
        
        function rasCentroids=getRASCentroids(obj,locs)
            if(~exist('locs','var'))
                locs=obj.volProps.Centroid;
            end
            rasCentroids=zeros(size(locs));
            for i=1:size(locs,1)
                rasCentroids(i,:)=obj.Volume.Vox2Ras(locs(i,:));
            end
        end
        
        function pIdx=findPrevSelectedPoint(obj,pCloud,point)
                [idx,dist]=findNearestNeighbors(pCloud,point(:)',1);
                if(dist < (obj.elDefintion.Definition(obj.selElectrodeDefinition).Spacing/2))
                    pIdx=idx;
                else
                    pIdx=[];
                end
            
                
        end
        
        function callbackClickA3DPoint(obj,src, eventData)
            fprintf('you clicked on point number %d\n', src.UserData);
            if(obj.selElectrodeDefinition < 1)
                warning('No Electrode Definition selected, Location will not be added');
            else
                selCentroid=obj.Volume.Vox2Ras(obj.volProps.Centroid(src.UserData,:));
                if(~isempty(obj.elLocations.Location))
                    pIdx=obj.findPrevSelectedPoint(pointCloud(obj.elLocations.Location),selCentroid);
                else
                    pIdx=[];
                end
                if(~isempty(pIdx))
                    obj.elLocations.Location(pIdx,:)=[];
                    obj.elLocations.DefinitionIdentifier(pIdx)=[];
                else
                    obj.elLocations.Location(end+1,:)=selCentroid;
                    obj.elLocations.DefinitionIdentifier(end+1)=obj.selElectrodeDefinition;
                end
                obj.uiTree.Root.Children(obj.selElectrodeDefinition).Name = [obj.elDefintion.Definition(obj.selElectrodeDefinition).Name ' (' num2str(sum(obj.elLocations.DefinitionIdentifier == obj.selElectrodeDefinition)) ...
                        '/' num2str(obj.elDefintion.Definition(obj.selElectrodeDefinition).NElectrodes) ')'];
                obj.colorPatches();
                
            end

        end

        
    end
end

