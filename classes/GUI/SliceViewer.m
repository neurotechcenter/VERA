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
    end
    properties (Access = protected)
        slider
        imageView
        currCursor = []
        posText=[]
        silentChange = false
        imageObjs = {}
        oldImages={};
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
                    alpha(obj.imageObjs{i},obj.ImageAlphas{i});
               end
           end
        end
        
        function drawImage(obj,imgIdx)
            slice=zeros(3,1);
            slice(obj.ViewAxis(3))=obj.Slice;
            sliderSlice=obj.Images{imgIdx}.Ras2Vox(slice);
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
            img=obj.Images{imgIdx}.Image.img(x,y,z,:);
            
            img=squeeze(permute(img,obj.ViewAxis))';
            hold(obj.imageView,'on');
            if(imgIdx > length(obj.imageObjs))
                obj.imageObjs{imgIdx}=imagesc(obj.imageView,'XData',X,'YData',Y,'CDATA',img,'ButtonDownFcn',@obj.click,'Clipping','off','AlphaData',obj.ImageAlphas{imgIdx});
                set(obj.imageView,'YDir','normal');
                 if(obj.ViewAxis(1) == 1)
                    set(obj.imageView,'XDir','reverse');
                 end
                 set(obj.imageView,'xtick',[])
                  set(obj.imageView,'ytick',[])
                 axis(obj.imageView,'square');
                 xlim(obj.imageView,'auto')
                 ylim(obj.imageView,'auto')
                 set(obj.imageView,'Color','k')
                colormap(obj.imageView,'gray');
                set(obj.imageView,'xlimmode','manual',...
                                   'ylimmode','manual',...
                                   'zlimmode','manual',...
                                   'climmode','manual',...
                                   'alimmode','manual',...
                                   'xlim',[min(X) max(X)],'ylim',[min(Y) max(Y)]);
                    
            else
                    set(obj.imageObjs{imgIdx},'CData',img,'XData',X,'YData',Y,'AlphaData',obj.ImageAlphas{imgIdx});
            end
            hold(obj.imageView,'off');
            obj.updateCursor();

            
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

                if(obj.CursorPosition(obj.ViewAxis(3)) == obj.Slice)
                    hold(obj.imageView,'on')
                    obj.currCursor=scatter(obj.imageView,obj.CursorPosition(obj.ViewAxis(1)),obj.CursorPosition(obj.ViewAxis(2)),200,'+r','LineWidth',1.5);
                    obj.posText=text(obj.imageView,0,...
                        0.05,...
                        ['  X: ' num2str(obj.CursorPosition(1),'%4.1f') '     Y: '...
                        num2str(obj.CursorPosition(2),'%4.1f') '      Z: '...
                        num2str(obj.CursorPosition(3),'%4.1f')],...
                        'Color','white','Units','normalized','FontSize',12);
                     hold(obj.imageView,'off');
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
            for i=1:length(obj.Images)
                obj.drawImage(i); 
            end
        end
        
        function cursorPosChanged(obj,~,~)
            obj.silentChange=true;
            obj.Slice=obj.CursorPosition(obj.ViewAxis(3));
            obj.silentChange=false;
            obj.updateCursor();
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
            obj.oldImages=obj.Images;
        end
        
        function imageChanged(obj,src,event)
            %check if handles have changed
            obj.silentChange=true;
            oldImageObjs=obj.imageObjs;
            obj.imageObjs={};
            oldAlpha=obj.ImageAlphas;
            obj.ImageAlphas={};
            z_min=zeros(length(obj.Images),1);
            z_max=zeros(length(obj.Images),1);
            remainderIdx=[];
            c_min=zeros(length(obj.Images),1);
            c_max=zeros(length(obj.Images),1);
        
            for i=1:length(obj.Images)
                XYZ=cell(3,1);
                [XYZ{:}]=obj.Images{i}.GetRasAxis();
               z_min(i)=min(XYZ{obj.ViewAxis(3)});
               z_max(i)=max(XYZ{obj.ViewAxis(3)});
                if(any(isequal(obj.Images{i},[obj.oldImages{:}])))
                    obj.imageObjs{i}=oldImageObjs{isequal(obj.Images{i},[obj.oldImages{:}])};
                    obj.ImageAlphas{i}=oldAlpha{isequal(obj.Images{i},[obj.oldImages{:}])};
                    remainderIdx(end+1)=find(isequal(obj.Images{i},[obj.oldImages{:}]));
                else
                    obj.ImageAlphas{i}=1;
                    obj.drawImage(i);
                end
               c_min(i)=min(min(min(obj.Images{i}.Image.img)));
               c_max(i)=max(max(max(obj.Images{i}.Image.img)));
            end
            delete([oldImageObjs{setdiff(1:length(oldImageObjs),remainderIdx)}]);
            obj.silentChange=false;
            obj.oldImages={}; %remove handles 
            if(~isempty(obj.Images))
                obj.slider.Min=min(z_min);
                obj.slider.Max=max(z_max);
            end
            obj.SetColorLimits([min(c_min) max(c_max)]);
            
            
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

