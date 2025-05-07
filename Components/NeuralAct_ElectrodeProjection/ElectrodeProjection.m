classdef ElectrodeProjection < AComponent
    %ElectrodeProjection Projects electrodes onto the hull of the cortex
    %using the NeuralAct package
    
   properties
        SurfaceIdentifier
        ElectrodeLocationIdentifier
        ElectrodeDefinitionIdentifier
        ProjectToHemisphere
    end
    
    methods
        function obj = ElectrodeProjection()
            obj.SurfaceIdentifier='Surface';
            obj.ElectrodeLocationIdentifier='ElectrodeLocation';
            obj.ElectrodeDefinitionIdentifier='ElectrodeDefinition';
            obj.ProjectToHemisphere='False';
        end
        function Publish(obj)
            obj.AddInput(obj.SurfaceIdentifier,'Surface');
            obj.AddInput(obj.ElectrodeLocationIdentifier,'ElectrodeLocation');
            obj.AddOptionalInput(obj.ElectrodeDefinitionIdentifier,'ElectrodeDefinition');
            obj.AddOutput(obj.ElectrodeLocationIdentifier,'ElectrodeLocation');
            obj.RequestDependency('NeuralAct','folder');
        end
        function Initialize(obj)
            path=obj.GetDependency('NeuralAct');
            addpath(genpath(path));
            if(~any(strcmp(obj.ProjectToHemisphere,{'True', 'False'})))
                error('rojectToHemisphere has to be set to either True or False!');
            end
            
        end
        
        function [electrodes] = Process(obj,surface,electrodes,varargin)
            definitions=[];
            if(length(varargin) == 2)
                definitions=varargin{2};
            end

            substr=obj.prepElDefinitions(electrodes,definitions);
            if(strcmp(obj.ProjectToHemisphere,'True'))
                %first, estimate which electrode belongs to which
                %hemisphere by determining the closest vertex
                el_hemi=zeros(size(electrodes.Location,1),1);
                for ie = 1:length(el_hemi)
                    p=electrodes.Location(ie,:);
                    [~,vId]=min((surface.Model.vert(:,1)-p(1)).^2 + (surface.Model.vert(:,2)-p(2)).^2 + (surface.Model.vert(:,3)-p(3)).^2);
                    el_hemi(ie)=surface.VertId(vId); %store hemisphere identifier;
                end
                lModel.vert=surface.Model.vert(surface.VertId == 1,:);
                lModel.tri=surface.Model.tri(surface.TriId == 1,:);
                rModel.vert=surface.Model.vert(surface.VertId == 2,:);
                rModel.tri=surface.Model.tri(surface.TriId == 2,:);
                substrL=substr;
                substrL.electrodes(setdiff(substrL.origIdx,find(el_hemi==1)),:)=[]; %remove right hemisphere electrodes
                substrL.origIdx(setdiff(substrL.origIdx,find(el_hemi==1)))=[];
                substrR=substr;
                substrR.electrodes(setdiff(substrR.origIdx,find(el_hemi==2)),:)=[]; %only keep left hemisphere electrodes
                substrR.origIdx(setdiff(substrR.origIdx,find(el_hemi==2)))=[];
                
                hullL=hullModel(lModel);
                hullR=hullModel(rModel);
                substr_outL=projectElectrodes(hullL,substrL,40);
                substr_outR=projectElectrodes(hullR,substrR,40);
                electrodes.Location(substr_outL.origIdx,:)=substr_outL.trielectrodes;
                electrodes.Location(substr_outR.origIdx,:)=substr_outR.trielectrodes;
            else
                hull=hullModel(surface.Model);

                substr_out=projectElectrodes(hull,substr,80);
                electrodes.Location(substr_out.origIdx,:)=substr_out.trielectrodes;
            end
            
            
        end
        
        function substr=prepElDefinitions(obj,electrodes,definitions)
                substr.electrodes=[];
                substr.origIdx=[];
                if(isempty(definitions))
                    substr.electrodes=electrodes.Location;
                    substr.origIdx=1:size(electrodes.Location,1);
                else
                    for i=1:size(electrodes.Location,1)
                        idx=electrodes.DefinitionIdentifier(i);
                        if(any(strcmp(definitions.Definition(idx).Type,{'Grid','Strip (Projectable)'})))
                            substr.electrodes(end+1,:)=electrodes.Location(i,:);
                            substr.origIdx(end+1)=i;
                        end

                    end
                end
        end
    end
end

