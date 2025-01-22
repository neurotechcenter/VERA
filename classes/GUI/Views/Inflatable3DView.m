classdef Inflatable3DView < AView & uix.Grid
%The `Inflatable3DView` class is a component for visualizing 3D surface models
%(such as brain surfaces) along with electrode locations, in an inflatable or
%projected 3D view. It allows the user to visualize and interact with
%inflated brain surfaces, along with electrode locations that are mapped onto
%these surfaces. This component can display both left and right hemisphere
%surfaces, with corresponding electrode information, and supports customization
%through inclusion radius and electrode labeling options.
% See also AView
    properties
        SurfaceIdentifier
        SphereIdentifier
        ElectrodeLocationIdentifier
        ElectrodeDefinitionIdentifier
        InclusionRadius
        InclusionLabels
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
        function obj = Inflatable3DView(varargin)
            obj.SurfaceIdentifier='Surface';
            obj.SphereIdentifier='InflatedSurface';
            obj.ElectrodeLocationIdentifier='ElectrodeLocation';
            obj.ElectrodeDefinitionIdentifier='ElectrodeDefinition';
            obj.InclusionRadius=6;
            obj.InclusionLabels={'*'};
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
            if(~isKey(obj.AvailableData,obj.SurfaceIdentifier) || ~isKey(obj.AvailableData,obj.LeftSphereIdentifier))
                return;
            end
            surface=obj.AvailableData(obj.SurfaceIdentifier);
            %figure,plot3DModel(gca,surface.GetSubSurfaceById(1).Model);
            %figure,plot3DModel(gca,surface.GetSubSurfaceById(2).Model);
            obj.leftInflatableRender.SetSurfaces(surface.GetSubSurfaceById(1,false),obj.AvailableData(obj.LeftSphereIdentifier));
            obj.rightInflatableRender.SetSurfaces(surface.GetSubSurfaceById(2,false),obj.AvailableData(obj.RightSphereIdentifier));
            
            if(~isKey(obj.AvailableData,obj.ElectrodeLocationIdentifier))
                return;
            end

            eloc=obj.AvailableData(obj.ElectrodeLocationIdentifier);
%             if(isKey(obj.AvailableData,obj.ElectrodeDefinitionIdentifier))
%                 eDef=obj.AvailableData(obj.ElectrodeDefinitionIdentifier);
%                 elNames=eloc.GetElectrodeNames(eDef);
%             else
%                 elNames={};
%             end


            obj.leftInflatableRender.InclusionRadius=obj.InclusionRadius;
            obj.rightInflatableRender.InclusionRadius=obj.InclusionRadius;
            for idx=unique(eloc.DefinitionIdentifier)'
                elocs=eloc.Location(eloc.DefinitionIdentifier == idx,:);
                elocnames=num2cell(num2str((1:sum(eloc.DefinitionIdentifier == idx))'),2); % simple numbering
                labels=eloc.Label(eloc.DefinitionIdentifier == idx,:);
                obj.AddLabeledElectrodes(elocs,labels,elocnames);
            end
        end

        function AddLabeledElectrodes(obj,elocs,labels,elocnames)

                if(numel(obj.InclusionLabels)== 2 && iscell(obj.InclusionLabels{1})) %if Inclusion labels is Nx2, we have individual label restriction for each hemispheres 
                    [lelocs,lelocnames]=obj.filterElectrodes(elocs,elocnames,labels,obj.InclusionLabels{1});
                    [relocs,relocnames]=obj.filterElectrodes(elocs,elocnames,labels,obj.InclusionLabels{2});


                else
                    [lelocs,lelocnames]=obj.filterElectrodes(elocs,elocnames,labels,obj.InclusionLabels);
                    relocs=lelocs;
                    relocnames=lelocnames;

                end
                    obj.leftInflatableRender.AddElectrodeLocations(lelocs,lelocnames);
                    obj.rightInflatableRender.AddElectrodeLocations(relocs,relocnames);

        end

        function [elocs,elocnames]=filterElectrodes(~,elocs,elocnames,labels,inclusionlabels)
                    mask=ones(size(elocs,1),1,'logical');
                    for ich=1:size(elocs,1)
                        mask(ich)=any(~cellfun(@isempty,(regexp(labels{ich}, regexptranslate('wildcard', inclusionlabels),'match'))));
                    end
                    elocs=elocs(mask,:);
                    elocnames=elocnames(mask);
        end
    
    end


end

