classdef SliceViewerView < SliceViewerXYZ & AView
    %SLICEVIEWERVIEW Summary of this class goes here
    %   Detailed explanation goes here
    properties (SetObservable = true)
        ImageIdentifiers
    end
    properties (Access = protected)
        settingsGrid
        slMin
        slMax
    end
    
    methods
        function obj = SliceViewerView(varargin)
            scrollP=uix.ScrollingPanel('Parent',obj);
            
            obj.ImageIdentifiers = {'CT', 'MRI'};
            %obj.cbxImage=uicontrol('style','checkbox','Parent',obj.settingsGrid,'String',['Show ' obj.ImageIdentifier],'Value',1,'Callback',@obj.cbxChanged);
            %obj.cbxImage2=uicontrol('style','checkbox','Parent',obj.settingsGrid,'String',['Show ' obj.Image2Identifier],'Value',1,'Callback',@obj.cbxChanged);
            addlistener(obj,'ImageIdentifiers','PostSet',@obj.imageDefinitionChanged);
            vGrid=uix.VBox('Parent',scrollP);
            boxp=uix.Panel('Parent',vGrid,'Title','Contrast');
            vGridC=uix.VBox('Parent',boxp);
            obj.slMin=uicontrol('Parent',vGridC,'Style','slider','Min',0,'Max',1,'Value',1);
            obj.slMax=uicontrol('Parent',vGridC,'Style','slider','Min',0,'Max',1,'Value',1);
            
            addlistener(obj.slMin, 'Value', 'PostSet',@obj.changecMin);
            addlistener( obj.slMax, 'Value', 'PostSet',@obj.changecMax);
            
            vGridC.Heights=[20,20];
            obj.settingsGrid=uix.VBox('Parent',vGrid);
            vGrid.Heights=[80,-1];
            %addlistener(evtobj,'Component','PostSet',@PropListener.handlePropEvents);
             try
                uix.set( obj, varargin{:} )
             catch e
                delete( obj )
                e.throwAsCaller()
            end
        end
    end
    
    methods(Access = protected)
        
        function imageDefinitionChanged(obj,~,~)
            obj.updateView();
        end
        
        function dataUpdate(obj)
            obj.updateView();
        end
        
        
        function updateView(obj)
            images={};
            alphas={};
            delete(obj.settingsGrid.Children);
            for i = 1:length(obj.ImageIdentifiers)
                if(obj.AvailableData.isKey(obj.ImageIdentifiers{i}))
                    images{end+1}=obj.AvailableData(obj.ImageIdentifiers{i});
                    alphas{end+1}=1;
                    createViewPanel(obj,obj.settingsGrid,obj.ImageIdentifiers{i},i);
                end
            end
            uix.Empty('Parent',obj.settingsGrid);
            obj.Images=images;
            obj.ImageAlphas=alphas;
            clims=obj.GetColorLimits();
            obj.supressUpdate=true;
            obj.slMin.Min=clims(1);
            obj.slMin.Value=clims(1);
            obj.slMin.Max=clims(2);
            obj.slMax.Min=clims(1);
            obj.slMax.Max=clims(2);
            obj.slMax.Value=clims(2);
            obj.supressUpdate=false;

        end
        
        function panel=createViewPanel(obj,parent,name,idx)
            boxp=uix.Panel('Parent',parent,'Title',name);
            panel=uix.VBox('Parent',boxp);

            uicontrol('Parent',panel,'Style','text','String','Opacity');
            opSlider=uicontrol('Parent',panel,'Style','slider','Min',0,'Max',1,'Value',1,'UserData',idx);
            addlistener(opSlider, 'Value', 'PostSet',@(a,b)obj.sliderChanged(a,b,idx));
            panel.Heights=[20,20];
        end
        
        function sliderChanged(obj,source,b,idx)
            obj.ImageAlphas{idx}=b.AffectedObject.Value;
        end
        
        function changecMin(obj,~,~)
            if(obj.supressUpdate)
                return;
            end
            if(obj.slMin.Value >= obj.slMax.Value)
                obj.supressUpdate=true;
                set(obj.slMin,'Value',obj.slMax.Value-1);
                obj.supressUpdate=false;
            end
            obj.SetColorLimits([obj.slMin.Value obj.slMax.Value]);
            
        end
        function changecMax(obj,~,~)
           if(obj.supressUpdate)
                return;
           end
           if(obj.slMax.Value <= obj.slMin.Value)
                obj.supressUpdate=true;
                obj.slMax.Value=obj.slMin.Value+1;
                obj.supressUpdate=false;
           end
            obj.SetColorLimits([obj.slMin.Value obj.slMax.Value]);
        end
        
        
        
    end
end

