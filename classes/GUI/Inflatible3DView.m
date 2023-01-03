classdef Inflatible3DView < AView & uix.Grid
    %UNTITLED Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        SurfaceIdentifier
        SphereIdentifier
        ElectrodeLocationIdentifier
        ElectrodeDefinitionIdentifier
        InclusionRadius
    end

    properties (Dependent, Access = protected)
        LeftSphereIdentifier
        RightSphereIdentifier
    end

    properties (Access = protected)
        leftInflatableRender
        rightInflatableRender
    end
    
    methods
        function obj = Inflatible3DView(varargin)
            obj.SurfaceIdentifier='Surface';
            obj.SphereIdentifier='Sphere';
            obj.ElectrodeLocationIdentifier='ElectrodeLocation';
            obj.ElectrodeDefinitionIdentifier='ElectrodeDefinition';
            obj.InclusionRadius=6;
           % obj.axModel=axes('Parent',obj,'Units','normalized','Color','k','ActivePositionProperty', 'Position');
            obj.leftInflatableRender=InflatableRender('Parent',uicontainer('Parent',obj),'ShowColorBars',false);
            obj.rightInflatableRender=InflatableRender('Parent',uicontainer('Parent',obj));
            
             try
                uix.set( obj, varargin{:} )
             catch e
                delete( obj )
                e.throwAsCaller()
            end
        end
        
        function value=get.LeftSphereIdentifier(obj)
            value=['L_' obj.SphereIdentifier];
        end
        function value=get.RightSphereIdentifier(obj)
            value=['R_' obj.SphereIdentifier];
        end


    end

    methods(Access = protected)
        function dataUpdate(obj)
            if(isKey(obj.AvailableData,obj.SurfaceIdentifier) && isKey(obj.AvailableData,obj.LeftSphereIdentifier))
                surface=obj.AvailableData(obj.SurfaceIdentifier);
                %figure,plot3DModel(gca,surface.GetSubSurfaceById(1).Model);
                %figure,plot3DModel(gca,surface.GetSubSurfaceById(2).Model);
                obj.leftInflatableRender.SetSurfaces(surface.GetSubSurfaceById(1,false),obj.AvailableData(obj.LeftSphereIdentifier));
                obj.rightInflatableRender.SetSurfaces(surface.GetSubSurfaceById(2,false),obj.AvailableData(obj.RightSphereIdentifier));
            
            if(isKey(obj.AvailableData,obj.ElectrodeLocationIdentifier))
                eloc=obj.AvailableData(obj.ElectrodeLocationIdentifier);
                if(isKey(obj.AvailableData,obj.ElectrodeDefinitionIdentifier))
                    eDef=obj.AvailableData(obj.ElectrodeDefinitionIdentifier);
                    elNames=eloc.GetElectrodeNames(eDef);
                else
                    elNames={};
                end
                
                obj.leftInflatableRender.InclusionRadius=obj.InclusionRadius;
                obj.rightInflatableRender.InclusionRadius=obj.InclusionRadius;
                for idx=unique(eloc.DefinitionIdentifier)'
                    obj.leftInflatableRender.AddElectrodeLocations(eloc.Location(eloc.DefinitionIdentifier == idx,:),num2cell(num2str((1:sum(eloc.DefinitionIdentifier == idx))'),2));
                    obj.rightInflatableRender.AddElectrodeLocations(eloc.Location(eloc.DefinitionIdentifier == idx,:),num2cell(num2str((1:sum(eloc.DefinitionIdentifier == idx))'),2));
                end
            end
            end
        end
    end


end

