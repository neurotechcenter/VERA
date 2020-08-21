classdef Model3DView < AView & uix.Grid
    %Model3DView - View of a Surface
    %   Shows a Surface and the Electrode Locations if available
    properties
        SurfaceIdentifier %Identifier for which surface to show
        ElectrodeLocationIdentifier %Identifier for the Electrode Location to be shown
    end
    properties (Access = private)
        axModel
        requiresUpdate = false
    end
    
    methods
        function obj = Model3DView(varargin)
            %MODEL3DVIEW Construct an instance of this class
            obj.SurfaceIdentifier='Surface';
            obj.ElectrodeLocationIdentifier='ElectrodeLocation';
            opengl hardware;
            obj.axModel=axes('Parent',obj,'Units','normalized','Color','k');
            set(obj,'BackgroundColor','k');
            obj.Widths=[-1];
            obj.Heights=[-1];
             try
                uix.set( obj, varargin{:} )
             catch e
                delete( obj )
                e.throwAsCaller()
            end
        end
        

    end
    
    methods(Access = protected)
        function dataUpdate(obj)
            obj.updateView();
        end
        
        function updateView(obj)
            if(~obj.AvailableData.isKey(obj.SurfaceIdentifier))
                cla(obj.axModel);
                return;
            end
            surface=obj.AvailableData(obj.SurfaceIdentifier);
            hold(obj.axModel,'off');
            
              if(~isempty(surface))
                    if(~isempty(surface.Model) && isempty(surface.Annotation))
                        plot3DModel(obj.axModel,surface.Model);
                       % trisurf(surface.Model.tri, surface.Model.vert(:, 1), surface.Model.vert(:, 2), surface.Model.vert(:, 3) ,'Parent',obj.axModel,settings{:});
                    elseif(~isempty(surface.Model) && ~isempty(surface.Annotation))
                        [annotation_remap,cmap]=createColormapFromAnnotations(surface);
                        plot3DModel(obj.axModel,surface.Model,annotation_remap);
                       % trisurf(surface.Model.tri, surface.Model.vert(:, 1), surface.Model.vert(:, 2), surface.Model.vert(:, 3),annotation_remap ,'Parent',obj.axModel,settings{:});
                        colormap(obj.axModel,cmap);
                        
                        %light(obj.axModel,'Position',[-1 0 0]);

                       % camlight(obj.axModel,'headlight');
                        material(obj.axModel,'dull');
                        if(obj.AvailableData.isKey(obj.ElectrodeLocationIdentifier))
                            elPos=obj.AvailableData(obj.ElectrodeLocationIdentifier);
                            if(~isempty(elPos))
                                for i=unique(elPos.DefinitionIdentifier)',
                                plotBallsOn3DImage(obj.axModel,elPos.Location(elPos.DefinitionIdentifier==i,:),[],2);
                                end
                            end
                        end
                        for i=1:size(elPos.Location,1)
                            text(obj.axModel,elPos.Location(i,1)+1,elPos.Location(i,2)+1,elPos.Location(i,3)+1,num2str(i),'FontSize',14,'Color','w');
                        end
                    end
                    %colorbar(obj.axModel);
                    set(obj.axModel,'AmbientLightColor',[1 1 1])
                    %zoom(obj.axModel,'on');
                   
                     set(obj.axModel,'xtick',[]);
                      set(obj.axModel,'ytick',[]);
                     axis(obj.axModel,'equal');
                     axis(obj.axModel,'off');
                     xlim(obj.axModel,'auto');
                     ylim(obj.axModel,'auto');
                     set(obj.axModel,'Color','k');
                     set(obj.axModel,'clipping','off');
                     set(obj.axModel,'XColor', 'none','YColor','none','ZColor','none')                    
             else
                 delete(obj.axModel.Children);
             end
        end
    end

end

