
classdef SliceViewer < uix.Grid
    %SliceViewer View for Volume Data
    %Allows the view of different Volumes on top of each other and moving
    %through slices as well as changing transparency
    properties (Access = public,SetObservable)
        Images = {} %List of Volumes to be displayed. See also Volume 
        ImageAlphas = {} %Transparency for each Volume
        SliderOrientation = 'west'  %north, west, south, east, hide      
        CursorPosition = []; %Cursor position for each image
        Slice =1 %Slice to be displayed
        CursorChangedFcn = [];
        SliceChangedFcn = [];
        ViewAxis = [1 2 3]; %Axis to be viewed (x,y, slider)
        SliderVisible= 'on'      
        ElectrodeLocation
    end
    properties (Access = protected)
        slider
        imageView
        currCursor = []
        posText=[]
        silentChange = false
        imageObjs = {}
        currElectrodes = {}
      %  oldImages={};
    end
    
    methods
        
        function obj=SliceViewer(varargin)
            obj.slider=uicontrol('Parent', obj,'Style', 'slider','Units','normalized','Min',1,'Max',2,'Value',1);
            addlistener(obj.slider, 'Value', 'PreSet',@obj.sliderChanged);
            obj.imageView=axes('Parent',obj,'Units','normalized','Color','k');
            axis(obj.imageView,'fill')
            addlistener(obj,'Images','PreSet',@obj.imagePreChanged);
            addlistener(obj,'Images','PostSet',@obj.imageChanged);
            addlistener(obj,'ImageAlphas','PostSet',@obj.alphaChanged);
            addlistener(obj,'SliderVisible','PostSet',@obj.sliderVisibilityChanged);
            
            addlistener(obj,'CursorPosition','PostSet',@obj.cursorPosChanged);
            addlistener(obj,'SliderOrientation','PostSet',@obj.SliderOrientationChanged);
             addlistener(obj,'Slice','PostSet',@obj.SliceChanged);
            obj.SliderOrientationChanged();
            obj.slider.Value=obj.Slice;
            %remove borders from axis
            set(obj.imageView,'units','pixels'); % set the axes units to pixels
            x = get(obj.imageView,'position'); % get the position of the axes
            set(obj.imageView,'units','pixels'); % set the figure units to pixels
            y = get(obj.imageView,'position'); % get the figure position
            set(obj.imageView,'position',[y(1) y(2) x(3) x(4)]);% set the position of the figure to the length and width of the axes
            set(obj.imageView,'units','normalized','position',[0 0 1 1]); % set the axes units to pixels
            
            axis(obj.imageView,'square');
            try
                uix.set( obj, varargin{:} )
            catch e
                delete( obj )
                e.throwAsCaller()
            end
        end
        
        function SetColorLimits(obj,lims)
            if(~isempty(lims))
                set(obj.imageView,'clim',lims);
            end
        end
        
        function lim=GetColorLimits(obj)
            lim=get(obj.imageView,'clim');
        end

    end
    methods (Access = protected)
        
        function alphaChanged(obj,~,~)

           if(~isempty(obj.imageObjs) && ~obj.silentChange)
               for i=1:length(obj.ImageAlphas)
                    if(length(obj.imageObjs) < i)
                        continue;
                    end
                    curr_slice=zeros(3,1);
                    curr_slice(obj.ViewAxis(3))=obj.Slice;
                    sliderSlice=round(obj.Images{i}.Ras2Vox(curr_slice));
                    slice_num=sliderSlice(obj.ViewAxis(3));
                    if(slice_num > 0 && slice_num < size(obj.Images{i}.Image.img,obj.ViewAxis(3)))
                        alpha(obj.imageObjs{i},obj.ImageAlphas{i});
                    end
               end
           end
        end
        
        function drawImage(obj,imgIdx)
            slice=zeros(3,1);
            slice(obj.ViewAxis(3))=obj.Slice;
            sliderSlice=round(obj.Images{imgIdx}.Ras2Vox(slice));
            x=1:size(obj.Images{imgIdx}.Image.img,1);
            y=1:size(obj.Images{imgIdx}.Image.img,2);
            z=1:size(obj.Images{imgIdx}.Image.img,3);
             XYZ=cell(3,1);
            [XYZ{:}]=obj.Images{imgIdx}.GetRasAxis();
          
            X=XYZ{obj.ViewAxis(1)};
            Y=XYZ{obj.ViewAxis(2)};
            
            switch obj.ViewAxis(3)
                case 1
                    x=sliderSlice(obj.ViewAxis(3));
                case 2
                    y=sliderSlice(obj.ViewAxis(3));
                case 3
                    z=sliderSlice(obj.ViewAxis(3));
            end
            if(any([x y z] < 1) || (max(x) > size(obj.Images{imgIdx}.Image.img,1) || max(y) > size(obj.Images{imgIdx}.Image.img,2) || max(z) > size(obj.Images{imgIdx}.Image.img,3)))
                img=NaN;
            else
                img=obj.Images{imgIdx}.Image.img(x,y,z,:);
                 img=squeeze(permute(img,obj.ViewAxis))';
            end
            
           
            hold(obj.imageView,'on');
            if((imgIdx > length(obj.imageObjs)))
             
                if(~isnan(img))      
                    obj.imageObjs{imgIdx}=imagesc(obj.imageView,'XData',X,'YData',Y,'CDATA',img,'ButtonDownFcn',@obj.click,'Clipping','off','AlphaData',obj.ImageAlphas{imgIdx});
                else
                    obj.imageObjs{imgIdx}=imagesc(obj.imageView,'XData',X,'YData',Y,'CDATA',zeros(length(Y),length(X)),'ButtonDownFcn',@obj.click,'Clipping','off','AlphaData',0);
                end
                set(obj.imageView,'YDir','normal');
                 if(obj.ViewAxis(1) == 1)
                    set(obj.imageView,'XDir','reverse');
                 end
                 set(obj.imageView,'xtick',[])
                  set(obj.imageView,'ytick',[])
                 
                 xlim(obj.imageView,'auto')
                 ylim(obj.imageView,'auto')
                 set(obj.imageView,'Color','k')
                colormap(obj.imageView,'gray');
                [xl,yl]=getLims(obj);
                set(obj.imageView,'xlimmode','manual',...
                                   'ylimmode','manual',...
                                   'zlimmode','manual',...
                                   'climmode','manual',...
                                   'alimmode','manual',...
                                   'xlim',xl,'ylim',yl);
                axis(obj.imageView,'equal');
                    
            else
                if(~isnan(img))
                    set(obj.imageObjs{imgIdx},'CData',img,'XData',X,'YData',Y,'AlphaData',obj.ImageAlphas{imgIdx});
                else
                    set(obj.imageObjs{imgIdx},'AlphaData',0);
                end
            end
            hold(obj.imageView,'off');
            obj.updateCursor();
            obj.updateElectrodeLocations();
            
        end
        
        function [xl, yl]=getLims(obj)
            xd=[];
            yd=[];
            for i=1:length(obj.imageObjs)
                xd=[xd obj.imageObjs{i}.XData];
                yd=[yd obj.imageObjs{i}.YData];
            end
            xl=[min(xd) max(xd)];
            yl=[min(yd) max(yd)];
        end
        
        function updateElectrodeLocations(obj)
            if(~isempty(obj.ElectrodeLocation))
                if(~isempty(obj.currElectrodes))
                    delete([obj.currElectrodes{:}]);

                    obj.currElectrodes={};
                end
                for iel=1:size(obj.ElectrodeLocation.Location,1)
                    eloc=obj.ElectrodeLocation.Location(iel,:);
                    if(abs(round(eloc(obj.ViewAxis(3)))-round(obj.Slice)) < 0.5)
                        hold(obj.imageView,'on')
                        obj.currElectrodes{end+1}=scatter(obj.imageView,eloc(obj.ViewAxis(1)),eloc(obj.ViewAxis(2)),10,'or','fill','LineWidth',0.5);
                    end
                end
            end
        end
        
        function updateCursor(obj)
            if(~isempty(obj.CursorPosition))
                if(~isempty(obj.currCursor))
                    delete(obj.currCursor);

                    obj.currCursor=[];
                end
                if(~isempty(obj.posText))
                    delete(obj.posText)
                    obj.posText=[];
                end

                if(abs(obj.CursorPosition(obj.ViewAxis(3)) - obj.Slice) < 0.5 )
                    hold(obj.imageView,'on')
                    obj.currCursor=scatter(obj.imageView,obj.CursorPosition(obj.ViewAxis(1)),obj.CursorPosition(obj.ViewAxis(2)),200,'+g','LineWidth',1.5);
                    obj.posText=text(obj.imageView,0,...
                        0.05,...
                        ['  X: ' num2str(obj.CursorPosition(1),'%4.1f') '     Y: '...
                        num2str(obj.CursorPosition(2),'%4.1f') '      Z: '...
                        num2str(obj.CursorPosition(3),'%4.1f')],...
                        'Color','white','Units','normalized','FontSize',12);
                     hold(obj.imageView,'off');
                end
            else
                if(~isempty(obj.currCursor))
                    delete(obj.currCursor);

                    obj.currCursor=[];
                end
                if(~isempty(obj.posText))
                    delete(obj.posText)
                    obj.posText=[];
                end
            end
        end
        
        function SliceChanged(obj,~,~)
            if(~isempty(obj.SliceChangedFcn) && ~obj.silentChange)
                obj.SliceChangedFcn(obj,obj.Slice);
            end
            if(obj.slider.Value ~=obj.Slice)
                if(obj.Slice > obj.slider.Max)
                obj.slider.Value=obj.slider.Max;  
                elseif(obj.Slice < obj.slider.Min)
                    obj.slider.Value=obj.slider.Min;  
                else
                    obj.slider.Value=obj.Slice;  
                end
            end
            if(~obj.silentChange)
                obj.redrawImages();
            end
        end
        
        function cursorPosChanged(obj,~,~)
            obj.silentChange=true;
            if(~isempty(obj.CursorPosition))
                obj.Slice=obj.CursorPosition(obj.ViewAxis(3));
            end
            obj.silentChange=false;
            obj.updateCursor();
            obj.redrawImages();

        end
        
        function redrawImages(obj)
            for i=1:length(obj.Images)
                obj.drawImage(i); 
            end
        end
        
        
        function click(obj,src,eventdata)
            cp=([(eventdata.IntersectionPoint([1 2])) obj.Slice]);
            [~,o_order]=sort(obj.ViewAxis);
            obj.CursorPosition=cp(o_order);
            %disp(obj.CursorPosition);
            if(~isempty(obj.CursorChangedFcn))
                obj.CursorChangedFcn(obj, obj.CursorPosition);
            end

        end
        
        function sliderChanged(obj,~,~)
            
            if(~obj.silentChange)
                obj.Slice=obj.slider.Value;
            end
        end
        
        function imagePreChanged(obj,src,event)
           % obj.oldImages=obj.Images;
        end
        
        function imageChanged(obj,src,event)
            %check if handles have changed
            obj.silentChange=true;
            delete([obj.imageObjs{:}]);
            obj.imageObjs={};
            obj.ImageAlphas={};
            z_min=zeros(length(obj.Images),1);
            z_max=zeros(length(obj.Images),1);
            c_min=zeros(length(obj.Images),1);
            c_max=zeros(length(obj.Images),1);
            
            if(~isempty(obj.Images))
                for i=1:length(obj.Images)
                   XYZ=cell(3,1);
                   [XYZ{:}]=obj.Images{i}.GetRasAxis();
                   z_min(i)=min(XYZ{obj.ViewAxis(3)});
                   z_max(i)=max(XYZ{obj.ViewAxis(3)});
                   c_min(i)=min(min(min(obj.Images{i}.Image.img)));
                   c_max(i)=max(max(max(obj.Images{i}.Image.img)));
                end
                obj.slider.Min=min(z_min);
                obj.slider.Max=max(z_max);
                obj.slider.Value=mean([obj.slider.Max obj.slider.Min]);
                obj.Slice=mean([obj.slider.Max obj.slider.Min]);
            end
            
          
            for i=1:length(obj.Images)
                %if(any(isequal(obj.Images{i},[obj.oldImages{:}])))
                %    obj.imageObjs{i}=oldImageObjs{isequal(obj.Images{i},[obj.oldImages{:}])};
                %    obj.ImageAlphas{i}=oldAlpha{isequal(obj.Images{i},[obj.oldImages{:}])};
                %    remainderIdx(end+1)=find(isequal(obj.Images{i},[obj.oldImages{:}]));
                %else
                    obj.ImageAlphas{i}=1;
                    obj.drawImage(i);
                %end

            end
            obj.SetColorLimits([min(c_min) max(c_max)]);
            
            %delete([oldImageObjs{setdiff(1:length(oldImageObjs),remainderIdx)}]);
            obj.silentChange=false;
           % obj.oldImages={}; %remove handles 

            
            
        end
        
        function sliderVisibilityChanged(obj,~,~)
            obj.slider.Visible=obj.SliderVisible;
        end
        
        function SliderOrientationChanged(obj,~,~)
            
            switch(validatestring(obj.SliderOrientation,{'north','west','south','east','hide'}))
                
                case {'north'}
                    if(obj.Children == [obj.imageView; obj.slider])
                        obj.reorder([2 1]);
                    end
                    obj.Widths=[-1];
                    obj.Heights=[20 -1];
                case {'east'}
                    if(obj.Children == [obj.slider; obj.imageView])
                        obj.reorder([2 1]);
                    end
                    obj.Widths=[-1 20];
                    obj.Heights=[-1];
                case {'south'}
                    if(obj.Children == [obj.slider; obj.imageView])
                        obj.reorder([2 1]);
                    end
                    obj.Widths=[-1];
                    obj.Heights=[-1 20];
                case {'west'}
                    if(obj.Children == [obj.imageView; obj.slider])
                        obj.reorder([2 1]);
                    end
                    obj.Widths=[20 -1];
                    obj.Heights=[-1];
                case {'hide'}
                    set(obj.slider,'Visible','off');                 
                otherwise
                    error('Unknown orientation');
                
            end

        end

    end
    
end