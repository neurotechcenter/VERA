classdef SliceViewerView < SliceViewerXYZ & AView
    %SliceViewerView VERA View of Volume Data
    % See also AView, Volume, SliceViewer, SliceViewerXYZ
    
    properties (SetObservable = true)
        ImageIdentifiers %Data Identifier 
        ElectrodeLocationIdentifier
    end
    properties (Access = protected)
        settingsGrid
        slMin
        slMax
    end
    
    methods
        function obj = SliceViewerView(varargin)
            vGrid=uix.VBox('Parent',obj);
            obj.ElectrodeLocationIdentifier='ElectrodeLocation';
            obj.ImageIdentifiers = {};
            %obj.cbxImage=uicontrol('style','checkbox','Parent',obj.settingsGrid,'String',['Show ' obj.ImageIdentifier],'Value',1,'Callback',@obj.cbxChanged);
            %obj.cbxImage2=uicontrol('style','checkbox','Parent',obj.settingsGrid,'String',['Show ' obj.Image2Identifier],'Value',1,'Callback',@obj.cbxChanged);
            addlistener(obj,'ImageIdentifiers','PostSet',@obj.imageDefinitionChanged);
            %vGrid=uix.VBox('Parent',scrollP);
            boxp=uix.Panel('Parent',vGrid,'Title','Contrast');
            vGridC=uix.VBox('Parent',boxp);
            obj.slMin=uicontrol('Parent',vGridC,'Style','slider','Min',0,'Max',1,'Value',1);
            obj.slMax=uicontrol('Parent',vGridC,'Style','slider','Min',0,'Max',1,'Value',1);
            
            addlistener(obj.slMin, 'Value', 'PostSet',@obj.changecMin);
            addlistener( obj.slMax, 'Value', 'PostSet',@obj.changecMax);
            
            vGridC.Heights=[20,20];
            obj.settingsGrid=uix.VBox('Parent',vGrid);
            vGrid.Heights=[60,-1];
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
                        %add electrode locations
            if(isKey(obj.AvailableData,obj.ElectrodeLocationIdentifier))
                elLocs=obj.AvailableData(obj.ElectrodeLocationIdentifier);
                if(isObjectTypeOf(elLocs,'ElectrodeLocation'))
                    obj.ElectrodeLocation=elLocs;
                end
            else
                obj.ElectrodeLocation=[];
            end
            images={};
            alphas={};
            delete(obj.settingsGrid.Children);
            imgIdentifiers={};
            if(isempty(obj.ImageIdentifiers))
                for k=keys(obj.AvailableData)
                    if(isObjectTypeOf(obj.AvailableData(k{1}),'Volume'))
                        imgIdentifiers{end+1}=k{1};
                    end
                end
            else
                imgIdentifiers=obj.ImageIdentifiers;
            end
            obj.supressUpdate=false;
            for i = 1:length(imgIdentifiers)
                if(obj.AvailableData.isKey(imgIdentifiers{i}))
                    images{end+1}=obj.AvailableData(imgIdentifiers{i}).GetRasSlicedVolume();
                    alphas{end+1}=1;
                    createViewPanel(obj,obj.settingsGrid,imgIdentifiers{i},i);
                end
            end
            obj.settingsGrid.Children=flip(obj.settingsGrid.Children); %flip to match Z order
            uix.Empty('Parent',obj.settingsGrid);
            obj.Images=images;
            obj.ImageAlphas=alphas;
            clims=obj.GetColorLimits();
            obj.supressUpdate=true;
            obj.slMin.Min=min(clims);
            obj.slMin.Max=max(clims);
            obj.slMin.Value=min(clims);
            obj.slMax.Min=min(clims);
            obj.slMax.Max=max(clims);
            obj.slMax.Value=max(clims);
            obj.supressUpdate=false;


        end
        
        function panel=createViewPanel(obj,parent,name,idx)
            vb=uix.VBox('Parent',parent);
            boxp=uix.Panel('Parent',vb,'Title',name);
            panel=uix.VBox('Parent',boxp);
            hpanel=uix.HBox('Parent',panel);

            uicontrol('Parent',hpanel,'Style','text','String','Opacity');
            opSlider=uicontrol('Parent',hpanel,'Style','slider','Min',0,'Max',1,'Value',1,'UserData',idx);
            addlistener(opSlider, 'Value', 'PostSet',@(a,b)obj.sliderChanged(a,b,idx));
            hpanel.Widths=[80,-80];
            %panel.Heights=[40];
            
            panel.Heights=[20];
            vb.Heights=[40];
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

