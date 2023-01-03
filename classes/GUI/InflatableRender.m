classdef InflatableRender < handle & uix.Grid
    %INFLATABLERENDER Summary of this class goes here
    %   Detailed explanation goes here

    properties
        ElectrodeLocations
        InclusionRadius
        ShowColorBars
    end
    properties(Dependent)
        Inflation
    end
    properties(Access = protected)
        axModel
        vSurf
        cInflationSlider
        cAlphaSlider
        vElectrodeSurface
        ElectrodeNames
        tElectrodeNames
    end
    
    methods
        function obj = InflatableRender(varargin)
            tmp_Grid=uix.Grid('Parent',obj);
            obj.InclusionRadius=4;
            obj.axModel=axes('Parent',uicontainer('Parent',tmp_Grid),'Units','normalized','Color','k','ActivePositionProperty', 'Position');

            obj.axModel.Toolbar.Visible = 'off';
            %axtoolbar( obj.axModel,{'zoomin','zoomout','restoreview'});
            %obj.axModel.Interactions=dataTipInteraction;

            sliderGrid=uix.Grid('Parent',obj);
            uicontrol('Parent',sliderGrid,'Style','text','String','Inflation');
            uicontrol('Parent',sliderGrid,'Style','text','String','Opacity');
            obj.cInflationSlider=uicontrol('Parent',sliderGrid,'Style','slider','Min',0,'Max',1,'Value',1);
            
            obj.cAlphaSlider=uicontrol('Parent',sliderGrid,'Style','slider','Min',0,'Max',1,'Value',1);
            sliderGrid.Widths=[60,-1];
            sliderGrid.Heights=[15,-1];
            addlistener(obj.cInflationSlider, 'Value', 'PostSet',@obj.updateInflation);
            addlistener(obj.cAlphaSlider, 'Value', 'PostSet',@obj.updateAlpha);
            obj.ShowColorBars=true;
            obj.Widths=[-1];
            obj.Heights=[-1, 30];
             try
                uix.set( obj, varargin{:} )
             catch e
                delete( obj )
                e.throwAsCaller()
             end 
        end


        function AddElectrodeLocations(obj,val,names)

            if(~isempty(obj.vSurf))
                hold(obj.axModel,'on');
                d=minDistance(val,obj.vSurf.xyz1);
                val=val(d < obj.InclusionRadius,:);
                if(isempty(val))
                    return;
                end
                names=names(d < obj.InclusionRadius);
                obj.vElectrodeSurface=inflatablescatter3(obj.vSurf, ...
                val(:,1),val(:,2), val(:,3), ...
                80,'filled','Parent',obj.axModel,'MarkerEdgeColor','k');%,'ButtonDownFcn',@obj.showDataTip);
                for i=1:length(names)
                    inflatabletext(obj.vElectrodeSurface,...
                    val(i,1),val(i,2), val(i,3),...
                    names{i},'Interpreter','none','Parent',obj.axModel,'FontSize',14,'Color','w');
                end
                hold(obj.axModel,'off');
                obj.vElectrodeSurface.DataTipTemplate.DataTipRows(2:end)=[]; % TODO - fix bug causing datatip to not work before 3D model was rotated
                obj.vElectrodeSurface.DataTipTemplate.DataTipRows(1) = dataTipTextRow('',names);
                obj.vElectrodeSurface.DataTipTemplate.Interpreter='none';
            else
                error('Requires Surface to be set first');
            end

        end
        
        function set.Inflation(obj,val)
            obj.vSurf.Inflation=val;
        end

        function val= get.Inflation(obj)
            val=obj.vSurf.Inflation;
        end


        function SetSurfaces(obj,surface, inflated_surface)
            hold(obj.axModel,'off');
            [annotation_remap,cmap,name] = createColormapFromAnnotations(surface);
            obj.vSurf=inflatablesurf(surface.Model.tri,surface.Model.vert,inflated_surface.Model.vert,annotation_remap, ...
                            'CDataMapping', 'direct',...
                            'linestyle', 'none',...
                            'FaceLighting','gouraud',...
                            'BackFaceLighting','unlit','AmbientStrength',1,'Parent',obj.axModel);
            colormap(obj.axModel,cmap);
            obj.updateInflation();


        end
    end

    methods (Access = protected)

        function updateInflation(obj,~,~)
            obj.Inflation=obj.cInflationSlider.Value;
        end


        function updateAlpha(obj,~,~)
            obj.vSurf.FaceAlpha= obj.cAlphaSlider.Value;
 
        end


        function showDataTip(obj,a,b)
            dt = findobj(a,'Type','datatip'); %delete old datatip
            delete(dt);

            datatip(a,b.IntersectionPoint(1),b.IntersectionPoint(2),b.IntersectionPoint(3));
        end

    end
end

