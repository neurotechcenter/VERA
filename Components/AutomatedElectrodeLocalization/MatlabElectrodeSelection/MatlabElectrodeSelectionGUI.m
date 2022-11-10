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
        uiListView % Tree view for selection
         
        elLocations % Electrode Locations
        
        selElectrodeDefinition %Index of selected electrode Definitio in Tree
        elDefinition % Available electrode definitions
        
        elPatches % Patches displated in ax3D using volProps Data
        
        isRunning
        
        trajectories
        
        trajMenu
        optimalShankTreshold
        shankMenu
        progressBar
        ReducedModel
        ReducedT
    end
    
    methods
        function obj = MatlabElectrodeSelectionGUI(varargin)
            

          %   set(obj,'BackgroundColor','k');
            obj.trajectories=[];
            obj.isRunning=false;
            obj.uiListView=uicontrol('Parent',obj,'style','listbox','Callback',@obj.selectListView);%uiw.widget.Tree('Parent',obj,'MouseClickedCallback',@obj.treeClick);
            %obj.uiTree.Root.Name='Electrodes';
            obj.uiGrid=uix.Grid('Parent',obj);
            %set(obj.uiGrid,'BackgroundColor','k');
            obj.Widths=[100 -1];
            obj.ax3D=axes('Parent',obj.uiGrid,'Units','normalized','Color','k');
            obj.slMinThresh=uicontrol('Parent',obj.uiGrid,'Style','slider','Min',0,'Max',1,'Value',1,'SliderStep',[1 1],'Callback',@obj.setMinThresh);
            obj.slBrainAlpha=uicontrol('Parent',obj.uiGrid,'Style','slider','Min',0,'Max',1,'Value',0.1,'SliderStep',[1/100 1/100],'Callback',@obj.setBrainAlpha);
            obj.uiGrid.Heights=[-1,18,18];
            obj.elLocations=ElectrodeLocation();
            obj.elPatches={};
            try
                uix.set( obj, varargin{:} )
            catch e
                delete( obj )
                e.throwAsCaller()
            end
            cm = uicontextmenu(gcf);
            uimenu(cm,'Text','Find all connected locations','Callback', @(~,~) obj.findConnectedElectrodes());
            obj.trajMenu=uimenu(cm,'Text','Auto Detect Trajectory','Callback', @(~,~) obj.findAllElectrodes(),'Enable','off');
            uimenu(cm,'Text','Remove All','Callback', @(~,~) obj.removeElectrodes());
            obj.uiListView.UIContextMenu=cm;
            cameratoolbar(gcf,'NoReset');
            removeToolbarExplorationButtons(gcf);
            menu=uimenu(obj.Parent,'Label','Localization');
            obj.optimalShankTreshold=uimenu(menu,'Label','Determine optimal Threshold','Enable','on','Callback',@(~,~) obj.determineThreshold());
            obj.shankMenu=uimenu(menu,'Label','Run Automated Trajectory Detection','Enable','off','Callback',@(~,~) obj.runFullShankDetection());

            %set(gcf, 'WindowButtonDownFcn', {@(a,b)obj.callbackClickA3DPoint(a,b)}); 
            obj.progressBar=UnifiedProgressBar(obj.Parent);
        end
        
        function SetSurface(obj,surf)
             obj.brainSurf=surf;
            if(isempty(surf))
            else
                obj.brainSurf=surf;
                obj.axSurf=plot3DModel(obj.ax3D,obj.brainSurf.Model);
                alpha(obj.axSurf,obj.slBrainAlpha.Value);
                set(obj.axSurf,'HitTest','off');
                obj.ReducedModel.faces = obj.brainSurf.Model.tri;
                obj.ReducedModel.vertices = obj.brainSurf.Model.vert;
                obj.ReducedModel=reducepatch(obj.ReducedModel,0.1);
                obj.ReducedT=(delaunayn(obj.ReducedModel.vertices));
            end
        end
        
        function SetElectrodeLocation(obj,eLoc)
            obj.elLocations=eLoc;
            obj.updateListView();
        end
        
        function SetElectrodeDefintion(obj,elDef)
            obj.elDefinition=elDef;
            obj.updateListView();
            
        end
        
        
        
        function elLoc=GetElectrodeLocations(obj)
            elLoc=obj.elLocations;

        end
        
        function SetVolume(obj,vol)
            obj.Volume=vol;
            
            obj.slMinThresh.Min=min(min(min(vol.Image.img)));
            obj.slMinThresh.Max=max(max(max(vol.Image.img)));
            obj.slMinThresh.SliderStep=[1/(obj.slMinThresh.Max- obj.slMinThresh.Min) 1/(obj.slMinThresh.Max- obj.slMinThresh.Min)];
            obj.slMinThresh.Value=obj.slMinThresh.Max-20;
            obj.updateView();
        end
        
        function SetTrajectories(obj,traj)
            obj.trajectories=traj;
            obj.updateView();
            set(obj.trajMenu,'Enable','on');
            set(obj.shankMenu,'Enable','on');
       
           
        end
        
    end

    
    methods (Access = protected)
        
        function selectListView(obj,~,~)
            obj.colorPatches(); 
        end
        
        function runFullShankDetection(obj)
            ison=obj.progressBar.IsSuspended();
            if(~ison)
                obj.progressBar.suspendGUIWithMessage('Running Shank detection....');
            end
            f = waitbar(0,'Running Shank detection on');
            for i=1:length(obj.elDefinition.Definition)
                obj.elLocations.RemoveWithIdentifier(i);
            end
            for i=1:length(obj.elDefinition.Definition)
                obj.uiListView.Value=i;
                obj.findAllElectrodes();
                waitbar(i/length(obj.elDefinition.Definition),f,'Name',[' Running Shank detection on ' obj.elDefinition.Definition(i).Name]);
            end
            close(f);
            if(~ison)
                obj.progressBar.resumeGUI();
            end
        end
        
        function determineThreshold(obj)
            obj.progressBar.suspendGUIWithMessage('Determining optimal threshold...');
            Nelecs=sum([obj.elDefinition.Definition.NElectrodes]);

            o.Display='iter';

            o.PlotFcns=[];
            o.OutputFcn=[];
        
            min_tresh=obj.slMinThresh.Min;%+(obj.slMinThresh.Max-obj.slMinThresh.Min)*0.2;
            %min_res=fmincon(@(x) obj.testTreshold(Nelecs,x),obj.slMinThresh.Min,[],[],[],[],min_tresh,obj.slMinThresh.Max,[],o);
            min_res=fminbnd(@(x) obj.testTreshold(Nelecs,x),min_tresh,obj.slMinThresh.Max,o);
            %min_res=obj.findMinimum(@(x) obj.testTreshold(Nelecs,x),min_tresh,obj.slMinThresh.Max,45);
            obj.testTreshold(Nelecs,min_res);

            obj.progressBar.resumeGUI();
        end

        function minRes=findMinimum(obj,fun,Xmin,Xmax,N_steps)
            steps=linspace(Xmin,Xmax,N_steps);
            res=inf(N_steps,1);
            for i=1:length(steps)
                res(i)=fun(steps(i));
                
            end
            [~,I]=min(res);
            minRes=steps(I);
            figure,plot(steps,res);
        end
        
        function metric=testTreshold(obj,NElecs, thresh)
            obj.slMinThresh.Value=thresh;
            obj.updateView();
            if(~isempty(obj.trajectories))
                obj.runFullShankDetection();
                metric=(NElecs-size(obj.elLocations.Location,1)).^2;
            else
                metric=(NElecs-size(obj.getRASCentroids(),1)).^2;
            end
            disp([num2str(thresh) ': ' num2str(metric)]);
        end
        
        function updateListView(obj)
            if(isempty(obj.elDefinition))
                return;
            end
            oldVal=obj.uiListView.Value;
            vals=cell(length(obj.elDefinition.Definition),1);
            for i=1:length(obj.elDefinition.Definition)
               vals{i}=[obj.elDefinition.Definition(i).Name ' (' num2str(sum(obj.elLocations.DefinitionIdentifier == i)) '/' num2str(obj.elDefinition.Definition(i).NElectrodes) ')'];

            end
            obj.uiListView.String=vals;
            obj.uiListView.Value=oldVal;
        end
        
        function removeElectrodes(obj)
            elDefIdx=obj.uiListView.Value;
            elMask=obj.elLocations.DefinitionIdentifier == elDefIdx;
            locs=obj.elLocations.Location(elMask,:);
            if(isempty(locs))
                return;
            end
            obj.elLocations.RemoveWithIdentifier(elDefIdx);
            obj.updateListView();
            obj.colorPatches();  
        end
        
        function findAllElectrodes(obj)
            elDefIdx=obj.uiListView.Value;
           % disp(['Running fully automated Detection on: ' obj.elDefinition.Definition(elDefIdx).Type ' ' obj.elDefinition.Definition(elDefIdx).Name]);
            linep=obj.trajectories.Location((obj.trajectories.DefinitionIdentifier == elDefIdx),:);
            if(isempty(linep))
                return; %skip if no trajectory is available
            end
            centroids=obj.getRASCentroids();
            
            centroid_dist=nan(size(centroids,1),1);

            v1=linep(1,:);
            v2=linep(2,:);
            d=[];%calculate how close electrodes are on a line
            a = v1 - v2;
            for ii=1:size(centroids) 
                b = centroids(ii,:) - v2;
                c = v1 -centroids(ii,:);
                angle_av2=atan2(norm(cross(a,b)),dot(a,b));
                angle_av1=atan2(norm(cross(c,a)),dot(c,a));
                if(angle_av1 < pi/2 && angle_av2 < pi/2)
                    d(ii) = norm(cross(a,b)) / norm(a); %shortest distance to trajectory
                else
                    d(ii)=min(pdist([b;v2]),pdist([c;v2])); %shortest direct distance to anker point
                end
            end
          
            [dist,I]=sort(d);
            I=I(dist < obj.elDefinition.Definition(elDefIdx).Spacing);
            closest_centroid=centroids(I,:);
            found_els=closest_centroid;
            
            obj.elLocations.RemoveWithIdentifier(elDefIdx);
            obj.elLocations.AddWithIdentifier(elDefIdx,found_els);
            if(size(found_els,1) > 0)
             obj.findConnectedElectrodes(true);
            end
        end
                
        function findConnectedElectrodes(obj,override)
            if(~exist('override','var'))
                override=true;
            end
            elDefIdx=obj.uiListView.Value;
            %disp(['Running Detection on: ' obj.elDefinition.Definition(elDefIdx).Type ' ' obj.elDefinition.Definition(elDefIdx).Name]);
            
            elMask=obj.elLocations.DefinitionIdentifier == elDefIdx;
            locs=obj.elLocations.Location(elMask,:);
            if(isempty(locs))
               error('The automated detection Algorithm requires at least 1 electrode preselected. Preferable an Edge Location');
            end
            o.TolX=0.01;
            o.PlotFcns=[];
            o.OutputFcn=[];
            o.Display='off';
            
            
            centroids=obj.getRASCentroids();
            %remove centroids already used
            usedelMask=obj.elLocations.DefinitionIdentifier ~= elDefIdx;
            occupiedLocs=obj.elLocations.Location(usedelMask,:);
            occIdx=zeros(size(occupiedLocs,1),1);
            for i=1:size(occupiedLocs,1)
                 buffIdx=obj.findPrevSelectedPoint(pointCloud(centroids),occupiedLocs(i,:));
                 if(~isempty(buffIdx))
                    occIdx(i)= buffIdx;
                 end
            end
            occIdx(occIdx == 0)=[];
            centroids(occIdx,:)=[];
            %bNames=1:size(centroids,1);

            gdist=obj.elDefinition.Definition(elDefIdx).Spacing;
            found_locs=cell(size(locs,1),1);
            numElFound=zeros(size(locs,1),1);
            pIdx=[];
            
            for iel=1:size(locs,1)
                p=obj.findPrevSelectedPoint(pointCloud(centroids),locs(iel,:));
                if(isempty(p))
                    continue
                end
                pIdx(end+1)=p;
                lcentroids=centroids;
                bNames=1:size(centroids,1);
                lcentroids(pIdx(end),:)=[];
                bNames(pIdx(end))=[];
                if(strcmp(obj.elDefinition.Definition(elDefIdx).Type,'Grid'))
                   % poss=findNeighbour(pIdx,locs(iel,:),lcentroids,90,bNames,gvar_best,gdist,true);
                    func=@(x)(numel(TraverseTree(findNeighbour(pIdx(end),locs(iel,:),lcentroids,90,bNames,x,gdist,true),['A','B']))-obj.elDefinition.Definition(elDefIdx).NElectrodes).^2;
                else
                   % poss=findStripNeighbour(pIdx,locs(iel,:),lcentroids,bNames,gvar_best,gdist);
                    func=@(x)(numel(TraverseTree(findStripNeighbour(pIdx(end),locs(iel,:),lcentroids,bNames,x,gdist,false),['A','B']))-obj.elDefinition.Definition(elDefIdx).NElectrodes).^2;
                end
                gvar_best=fminbnd(func,0.0,0.3,o);
                %disp(gvar_best);
                if(strcmp(obj.elDefinition.Definition(elDefIdx).Type,'Grid'))
                   poss=findNeighbour(pIdx(end),locs(iel,:),lcentroids,90,bNames,gvar_best,gdist,true);
                   % func=@(x)(numel(TraverseTree(findNeighbour(pIdx,locs(iel,:),lcentroids,90,bNames,x,gdist,true),['A','B']))-obj.elDefinition.Definition(elDefIdx).NElectrodes).^2;
                else
                   poss=findStripNeighbour(pIdx(end),locs(iel,:),lcentroids,bNames,gvar_best,gdist,true);
                    %func=@(x)(numel(TraverseTree(findStripNeighbour(pIdx,locs(iel,:),lcentroids,bNames,x,gdist),['A','B']))-obj.elDefinition.Definition(elDefIdx).NElectrodes).^2;
                end

                found_locs{iel}=TraverseTree(poss,['A','B']);
                numElFound(iel)=numel(found_locs{iel});

                    
                
            end
            if(~override)
                remList=[];
                for iel=1:size(locs,1)
                    if(numel(intersect(found_locs{iel},pIdx)) < length(pIdx))
                        remList(end+1)=iel;
                    end
                end
                numElFound(remList)=[];
                found_locs(remList)=[];
            end

            [~,idx]=max(numElFound);
            if(isempty(numElFound))
                disp('No Electrodes found that match the criteria');
            else
                %disp(['Electrodes found: ' num2str(numElFound(idx))]);
                obj.elLocations.RemoveWithIdentifier(elDefIdx);
                obj.elLocations.AddWithIdentifier(elDefIdx,centroids(found_locs{idx},:))
            end

            obj.updateListView();
            obj.colorPatches();            
            
        end
        

        
        function setMinThresh(obj,hObject,eventdata,handles)
            obj.updateView();
        end
        
        
        function setBrainAlpha(obj,hObject,eventdata,handles)
            alpha(obj.axSurf,obj.slBrainAlpha.Value);
        end
        
        function updateView(obj)
            if(isempty(obj.Volume) || obj.isRunning)
                return;
            end
            ison=obj.progressBar.IsSuspended();
            obj.isRunning=true;
            if(~ison)
                obj.progressBar.suspendGUIWithMessage('Recalculating Segmentation....');
            end
            obj.progressBar.ShowProgressBar(0,'Initializing Segmentation...');
            if(~isempty(obj.brainSurf))
                [annotation_remap,cmap]=createColormapFromAnnotations(obj.brainSurf);
                obj.axSurf=plot3DModel(obj.ax3D,obj.brainSurf.Model,annotation_remap);
                alpha(obj.axSurf,obj.slBrainAlpha.Value);
                set(obj.axSurf,'HitTest','off');
                set(obj.axSurf,'PickableParts','none');
                colormap(obj.ax3D,cmap);
                hold(obj.ax3D,'on');
            else
                camlight(obj.ax3D,'headlight');
                set(obj.ax3D,'xtick',[]);
                set(obj.ax3D,'ytick',[]);
                axis(obj.ax3D,'equal');
                axis(obj.ax3D,'off');
                xlim(obj.ax3D,'auto');
                ylim(obj.ax3D,'auto');
                set(obj.ax3D,'clipping','off');
                set(obj.ax3D,'XColor', 'none','YColor','none','ZColor','none')
            end
            obj.plotTrajectories();
            obj.elPatches={};
            V=permute(obj.Volume.Image.img,[2 1 3]);
            %V=smooth3(V,'gaussian');
            %V(V <= obj.slMinThresh.Value) = 0;
            %V(V > obj.slMinThresh.Value) = 1;
            %obj.volProps=regionprops3(bwconncomp(V),'Volume','Centroid','BoundingBox');
            %V(V <= obj.slMinThresh.Value) = 0;
            %V(V > obj.slMinThresh.Value) = 1;
            %V=smooth3(V,'box',3);
            V=(V > obj.slMinThresh.Value);
            %disp('Running Watershed');
            %tic
            %D = bwdist(V);
            %D(~V) = Inf;
            %w_shed=watershed(D);
            %w_shed(~V)=0;
            %toc
            obj.progressBar.ShowProgressBar(30,'Segmenting...');
            %tic
            obj.volProps=regionprops3(bwconncomp(V,26),'Volume','Centroid','BoundingBox');
            %toc
            obj.progressBar.ShowProgressBar(60,'Plotting Segments...');
            tic
            hold(obj.ax3D,'on');
            %A=[obj.Volume.Image.hdr.hist.srow_x; obj.Volume.Image.hdr.hist.srow_y; obj.Volume.Image.hdr.hist.srow_z;0 0 0 1];
            %[f,v]=isosurface(V,0);
            % v=[v ones(size(v,1),1)]*A';
            %p = patch(obj.ax3D,'Faces',f,'Vertices',v(:,1:3),'FaceAlpha',0.1,'EdgeColor','none');
            %convhull(obj.brainSurf.Model.vert,'Simplify',true);

            [x,y,z]=sphere;
            to_remove=[];
            if(~isempty(obj.brainSurf) && ~isempty(obj.volProps.Centroid))
                [k,d]=dsearchn(obj.ReducedModel.vertices,obj.ReducedT,reshape(obj.Volume.Vox2Ras(obj.volProps.Centroid(:,1:3)),[],3),-1);
            else
                k=ones(size(obj.volProps.Centroid,1),1);
            end
            rem_centroids=[];
            for i=1:size(obj.volProps.BoundingBox,1)
                %obj.elPatches{i}=plotEllipse(obj.ax3D,obj.Volume.Vox2Ras(obj.volProps.BoundingBox(i,1:3)),obj.volProps.BoundingBox(i,4:6)/2);
                
                
                
                if(~isempty(obj.brainSurf))
                    %k=dsearchn(Mf.vertices,T,patch_center,-1);
                    
                    if(k(i) == -1 && d(i) > 1.5)
                        patch_center=[];
                        rem_centroids(end+1)=i;
                    end
                end
            end
            obj.volProps(rem_centroids,:)=[];
            if size(obj.volProps.BoundingBox,1) > 1000
                warning('Only first 1000 segments displayed');
                obj.volProps(1001:end,:)=[];

            end
            for i=1:size(obj.volProps.BoundingBox,1)
    
                    patch_center=obj.Volume.Vox2Ras(obj.volProps.Centroid(i,1:3))';
                    end_idx=length(obj.elPatches)+1;
                    hold(obj.ax3D,'on');

                    obj.elPatches{end_idx}=surf(obj.ax3D,x+patch_center(1),y+patch_center(2),z+patch_center(3),'ButtonDownFcn',@obj.callbackClickA3DPoint,'UserData',end_idx,'EdgeColor','none','FaceAlpha',1,'FaceLighting','none'); %plotcube(obj.ax3D,obj.volProps.BoundingBox(i,4:6).*obj.Volume.Image.hdr.dime.pixdim(2:4),obj.Volume.Vox2Ras(obj.volProps.BoundingBox(i,1:3))',1,[1 0 0],@obj.callbackClickA3DPoint,i);
                    %scatter3(obj.ax3D,patch_center(1),patch_center(2),patch_center(3),60,'+','LineWidth',2); %plotcube(obj.ax3D,obj.volProps.BoundingBox(i,4:6).*obj.Volume.Image.hdr.dime.pixdim(2:4),obj.Volume.Vox2Ras(obj.volProps.BoundingBox(i,1:3))',1,[1 0 0],@obj.callbackClickA3DPoint,i);

                    material(obj.elPatches{end_idx},'dull');
                    set(obj.elPatches{end_idx},'clipping','off');

       
            end
            toc
            hold(obj.ax3D,'off');
            obj.colorPatches();
            axis(obj.ax3D,'equal');
            obj.isRunning=false;
            if(~ison)
                obj.progressBar.resumeGUI();
            end
            
        end
        
        function plotTrajectories(obj)
            
            if(~isempty(obj.trajectories))
                identifiers=unique(obj.trajectories.DefinitionIdentifier);
                hold(obj.ax3D,'on');
                for i=1:length(identifiers)
                    traj=obj.trajectories.Location(obj.trajectories.DefinitionIdentifier==identifiers(i),:);
                    plot3(obj.ax3D,traj(:,1),traj(:,2),traj(:,3),'r','LineWidth',3);
                    text(obj.ax3D,traj(1,1),traj(1,2),traj(1,3),obj.elDefinition.Definition(identifiers(i)).Name,'FontSize',16,'Interpreter','none','BackgroundColor','w');
                    
                end
                hold(obj.ax3D,'off');
            end
        end
        
        function colorPatches(obj)
            
            for i=1:length(obj.elPatches)
                patches=obj.elPatches{i};
                for ip=1:length(patches)
                    patches(ip).FaceColor=[1 0 0];
                end
            end
            rasCentroids=obj.getRASCentroids();
            for i=1:size(obj.elLocations.Location,1)
                pIdx=obj.findPrevSelectedPoint(pointCloud(rasCentroids),obj.elLocations.Location(i,:));
                if(~isempty(pIdx))
                    patches=obj.elPatches{pIdx};
                    for ip=1:length(patches)
                        patches(ip).FaceColor=[0.2 0.2 0.2];
                    end
                end
            end
    
            
            if(obj.uiListView.Value > 0)
                elMask=obj.elLocations.DefinitionIdentifier == obj.uiListView.Value;
                locs=obj.elLocations.Location(elMask,:);
                
                
                for i=1:size(locs,1) %check if loc is close enough to a patch

                    pIdx=obj.findPrevSelectedPoint(pointCloud(rasCentroids),locs(i,:));
                    if(~isempty(pIdx))
                        patches=obj.elPatches{pIdx};
                        for ip=1:length(patches)
                            patches(ip).FaceColor=[0 1 0];
                        end
                    else
                        disp('No Location found that is close enough');
                        hold(obj.ax3D,'on');
                        [x,y,z]=sphere;
                        surf(obj.ax3D,x+locs(i,1),y+locs(i,2),z+locs(i,3),'EdgeColor','none','FaceAlpha',1,'FaceLighting','none','FaceColor',[1 1 0]);
                        hold(obj.ax3D,'off');
                    end
                end
            end
        end
        
        function rasCentroids=getRASCentroids(obj,locs)
            if(~exist('locs','var'))
                locs=obj.volProps.Centroid;
            end
            rasCentroids=zeros(size(locs,1),3);
            for i=1:size(locs,1)
                rasCentroids(i,:)=obj.Volume.Vox2Ras(locs(i,:));
            end
        end
        
        function pIdx=findPrevSelectedPoint(obj,pCloud,point)
                [idx,dist]=findNearestNeighbors(pCloud,point(:)',1);
                if(dist < (obj.elDefinition.Definition(obj.uiListView.Value).Spacing/2))
                    pIdx=idx;
                else
                    pIdx=[];
                end
            
                
        end
        
        function callbackClickA3DPoint(obj,src, eventData)
           % fprintf('you clicked on point number %d\n', src.UserData);
            if(obj.uiListView.Value < 1)
                warning('No Electrode Definition selected, Location will not be added');
            else
                selCentroid=obj.Volume.Vox2Ras(obj.volProps.Centroid(src.UserData,:));
                if(~isempty(obj.elLocations.Location))
                    pIdx=obj.findPrevSelectedPoint(pointCloud(obj.elLocations.Location),selCentroid);
                else
                    pIdx=[];
                end
                centroids=obj.getRASCentroids();
                usedelMask=obj.elLocations.DefinitionIdentifier ~= obj.uiListView.Value;
                occupiedLocs=obj.elLocations.Location(usedelMask,:);
                occIdx=zeros(size(occupiedLocs,1),1);
                for i=1:size(occupiedLocs,1)
                     buffIdx=obj.findPrevSelectedPoint(pointCloud(centroids),occupiedLocs(i,:));
                     if(~isempty(buffIdx))
                        occIdx(i)= buffIdx;
                     end
                end
                
                if(any(occIdx == src.UserData))
                    warning('This point is already part of another Group!');
                    return;
                end
                
                if(~isempty(pIdx))
                    obj.elLocations.Location(pIdx,:)=[];
                    obj.elLocations.DefinitionIdentifier(pIdx)=[];
                else
                    obj.elLocations.Location(end+1,:)=selCentroid;
                    obj.elLocations.DefinitionIdentifier(end+1)=obj.uiListView.Value;
                end
                obj.updateListView();
                obj.colorPatches();
                
            end

        end

        
    end
end

