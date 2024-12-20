classdef FindBrodmanLabels < AComponent
    %FindBrodmanLabels Uses TalairachDemon to find the associated
    %Brodman area for an electrode. Requires the electrodes to be projected
    %into talairach space
    % Requires java installed
    
    properties
        TalairachLocationIdentifier
        LocationTypeIdentifier
    end
    
    methods
        function obj = FindBrodmanLabels()
            obj.TalairachLocationIdentifier='TalairachElectrodeLocation';
            obj.LocationTypeIdentifier='ElectrodeLocation';
        end
        
        function Publish(obj)
            if(~any(strcmp(obj.LocationTypeIdentifier,{'ElectrodeLocation','Surface'})))
                error('FindBrodmanLabels only allows ElectrodeLocation or Surface as LocationTypeIdentifier');
            end
            obj.AddInput(obj.TalairachLocationIdentifier,obj.LocationTypeIdentifier);
            obj.AddOutput(obj.TalairachLocationIdentifier,obj.LocationTypeIdentifier);
        end
        
        function Initialize(obj)
        end
        
        function [dataOut]=Process(obj,dataIn)
            dataOut=obj.CreateOutput(obj.TalairachLocationIdentifier,dataIn);
            jarFile=[fileparts(mfilename('fullpath')) '/talairach.jar'];
            if(strcmp(obj.LocationTypeIdentifier,'Surface'))
                BA=findBrodmanLabel(dataOut.Model.vert,jarFile,obj.GetDependency('TempPath'));
                BAs_tot=cellfun(@(x)brodmanLabelToNumber(x),BA);
                
                dataOut.Annotation=BAs_tot;
                [label,~,identifier]=unique(BA);
                %resort
                indices=cellfun(@(x)brodmanLabelToNumber(x),label);
                [B,I]=sort(indices);
                
                
                dataOut.AnnotationLabel=struct('Name',[],'Identifier',[],'PreferredColor',[]);
                cols=distinguishable_colors(length(indices));
                for i=1:length(indices)
                    dataOut.AnnotationLabel(i).Name=label{I(i)};
                    dataOut.AnnotationLabel(i).Identifier=B(i);
                    dataOut.AnnotationLabel(i).PreferredColor=cols(i,:);
                end
                %[dataOut.AnnotationLabel,~,dataOut.Annotation]=unique(BA);

            else %assume its ElectrodeLocation
                
                BA=findBrodmanLabel(dataIn.Location,jarFile,obj.GetDependency('TempPath'));
                for i=1:length(BA)
                    dataOut.SetAnnotation(i,'BrodmanArea',BA{i});
                    dataOut.AddLabel(i,BA{i});
                end
                
            end
        end
        

    end
end

