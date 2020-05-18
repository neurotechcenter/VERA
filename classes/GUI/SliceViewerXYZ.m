classdef SliceViewerXYZ < uix.Grid
    %SLICEVIEWER3D Summary of this class goes here
    %   Detailed explanation goes here
    
   properties (Access = public,SetObservable)
        Images ={}
        ImageAlphas = {}
        Cursor =[]
        SliderVisible= 'on'
    end
    
    properties (Access = protected)
        SliceViewX
        SliceViewY
        SliceViewZ
        ignoreSliceChange = false
        supressUpdate = false;
        
    end
    
    methods
        function obj = SliceViewerXYZ(varargin)
            %SLICEVIEWER3D Construct an instance of this class
            %   Detailed explanation goes here
            obj.SliceViewX=SliceViewer('Parent',obj,'SliderOrientation','south',...
                'CursorChangedFcn',@obj.setCursor,'SliceChangedFcn',@obj.sliceChanged,'ViewAxis',[2 3 1],'BackgroundColor','k'); %RAS system [left to right; posterior to anterior, inferior to sup] 

             obj.SliceViewZ=SliceViewer('Parent',obj,'SliderOrientation','south',...
                 'CursorChangedFcn',@obj.setCursor,'SliceChangedFcn',@obj.sliceChanged,'ViewAxis',[1 2 3],'BackgroundColor','k');
             obj.SliceViewY=SliceViewer('Parent',obj,'SliderOrientation','east',...
                 'CursorChangedFcn',@obj.setCursor,'SliceChangedFcn',@obj.sliceChanged,'ViewAxis',[1 3 2],'BackgroundColor','k');
            addlistener(obj,'Images','PostSet',@obj.imageChanged);
            addlistener(obj,'ImageAlphas','PostSet',@obj.alphasChanged);
            addlistener(obj,'Cursor','PostSet',@obj.setCursorOutside);
            addlistener(obj,'SliderVisible','PostSet',@obj.sliderVisibilityChanged);
            obj.Padding=0;
            obj.Widths=[-1 -1];
            obj.Heights=[-1 -1];
             try
              uix.set( obj, varargin{:} )
             catch e
              delete( obj )
              e.throwAsCaller()
            end
            
        end
        
        function SetColorLimits(obj,lims)
            obj.SliceViewX.SetColorLimits(lims);
            obj.SliceViewY.SetColorLimits(lims);
            obj.SliceViewZ.SetColorLimits(lims);
        end
        
        function lim=GetColorLimits(obj)
            lim=obj.SliceViewX.GetColorLimits();
        end

    end
    
    methods (Access = private)
        
        function sliceChanged(obj,src,~)
            if(obj.ignoreSliceChange)
                return
            end
%              switch(src)
%                 case obj.SliceViewZ
%                       if(~isempty(obj.SliceViewX.CursorPosition))
%                           obj.SliceViewX.CursorPosition=src.CursorPosition;
%                       end
%                       if(~isempty(obj.SliceViewY.CursorPosition))
%                           obj.SliceViewY.CursorPosition=src.CursorPosition;
%                       end
%                 case obj.SliceViewY
%                       if(~isempty(obj.SliceViewX.CursorPosition))
%                           obj.SliceViewX.CursorPosition=src.CursorPosition;
%                       end
%                        if(~isempty(obj.SliceViewZ.CursorPosition))
%                            obj.SliceViewZ.CursorPosition=src.CursorPosition;
%                       end
%                 case obj.SliceViewX
%                       if(~isempty(obj.SliceViewY.CursorPosition))
%                           obj.SliceViewY.CursorPosition=src.CursorPosition;
%                       end
%                       if(~isempty(obj.SliceViewZ.CursorPosition))
%                           obj.SliceViewZ.CursorPosition=src.CursorPosition;
%                       end
%              end
            
        end
        function setCursorOutside(obj,~,~)
            if(obj.ignoreSliceChange) %avoid multiple changes
                return
            end
            obj.ignoreSliceChange=true;
            obj.SliceViewX.CursorPosition=    obj.Cursor;
            obj.SliceViewY.CursorPosition=    obj.Cursor;
            obj.SliceViewZ.CursorPosition=    obj.Cursor;
            obj.ignoreSliceChange=false;
            
            
        end
        
        function setCursor(obj,src,cursordata)
            if(obj.ignoreSliceChange) %avoid multiple changes
                return
            end
            obj.ignoreSliceChange=true;
            obj.Cursor=cursordata;
            if(src ~= obj.SliceViewX)
                obj.SliceViewX.CursorPosition=cursordata;
            end
            if(src ~= obj.SliceViewY)
                obj.SliceViewY.CursorPosition=cursordata;
            end
            if(src ~= obj.SliceViewZ)
                obj.SliceViewZ.CursorPosition=cursordata;
            end
            obj.ignoreSliceChange=false;
            
            
        end
        
        function alphasChanged(obj,~,~)
            if(obj.supressUpdate)
                return;
            end
            obj.SliceViewX.ImageAlphas=obj.ImageAlphas;
            obj.SliceViewY.ImageAlphas=obj.ImageAlphas;
            obj.SliceViewZ.ImageAlphas=obj.ImageAlphas;
        end
        
        function imageChanged(obj,~,~)
            if(obj.supressUpdate)
                return;
            end
            obj.SliceViewX.Images=obj.Images;
            obj.SliceViewY.Images=obj.Images;
            obj.SliceViewZ.Images=obj.Images;
            obj.supressUpdate=true;
            obj.ImageAlphas=obj.SliceViewX.ImageAlphas;
            obj.supressUpdate=false;
        end
        
        function sliderVisibilityChanged(obj,~,~)
            obj.SliceViewX.SliderVisible=obj.SliderVisible;
            obj.SliceViewY.SliderVisible=obj.SliderVisible;
            obj.SliceViewZ.SliderVisible=obj.SliderVisible;
        end
    end
end

