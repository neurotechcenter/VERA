classdef CalculateDistanceToVolumeLabel < AComponent
    %CALCULATECLOSESTSURFACELABEL Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        VolumeIdentifier
        ElectrodeLocationIdentifier
        LabelIds
        LabelNames
    end
    properties (Access = protected)
        internalIds
        internalLabels
    end
    
    methods
        function obj = CalculateDistanceToVolumeLabel()
            %CALCULATECLOSESTSURFACELABEL Construct an instance of this class
            %   Detailed explanation goes here
            obj.VolumeIdentifier ='ASEG';
            obj.ElectrodeLocationIdentifier='ElectrodeLocation';
            obj.ignoreList{end+1}='internalIds';
            obj.ignoreList{end+1}='LabelNames';
        end
        
        function  Publish(obj)
            obj.AddInput(obj.VolumeIdentifier,'Volume');
            obj.AddInput(obj.ElectrodeLocationIdentifier,'ElectrodeLocation');
            obj.AddOutput(obj.ElectrodeLocationIdentifier,'ElectrodeLocation');
           
        end

        function Initialize(obj)
            if(isempty(obj.LabelIds) || (length(obj.LabelIds) ~= length(obj.LabelNames)))
                try
                    path=obj.GetDependency('Freesurfer');
                    addpath(genpath(fullfile(path,'matlab')));
                    warning('Label configuration configuration incorrect, trying Freesurfer LUT');
                    lut_path=fullfile(path,'FreeSurferColorLUT.txt');
                    [code,lut]=read_fscolorlut(lut_path);
                   if(isempty(obj.LabelIds))
                       obj.internalIds=code;
                   else
                      obj.internalIds= obj.LabelIds;
                   end
                    obj.internalLabels={};
                     for i=1:length(obj.internalIds)
                         if(any(code == obj.internalIds(i)))
                            obj.internalLabels{i}=strtrim(lut(code == obj.internalIds(i),:));
                         else
                             obj.internalLabels{i}='unknown';
                         end
                     end
                    
                catch
                    error("Each label needs a Name! - make sure LabelNames is set correctly");
                end
                
            else
                obj.internalIds= obj.LabelIds;
                obj.internalLabels=obj.LabelNames;
            end            
        end

        function out=Process(obj,vol,elLocs)
            out=obj.CreateOutput(obj.ElectrodeLocationIdentifier,elLocs);
            for i=1:length(obj.internalIds)
                binaryVol=zeros(size(vol.Image.img));
                binaryVol(vol.Image.img == obj.internalIds(i))=true;
                if(any(any(any(binaryVol)))) %only check if exists
                     [x,y,z]=meshgrid(1:size(binaryVol,2),1:size(binaryVol,1),1:size(binaryVol,3));
                     [~,vert]=isosurface(x,y,z,binaryVol); 
                     vert=[vert(:,2) vert(:,1) vert(:,3)]; %reorient from matlabs normal view...
                     vert=vol.Vox2Ras(vert);
                     for i_loc=1:size(out.Location,1)
                        [~,dist]=findNearestNeighbors(pointCloud(vert),out.Location(i_loc,:),1);
                        old_data=out.GetAnnotation(i_loc,'Distance');
                        old_data_label=out.GetAnnotation(i_loc,'Label');


                        voxLoc=round(vol.Ras2Vox(out.Location(i_loc,:)));
                        if((voxLoc(1) <= size(binaryVol,1)) && (voxLoc(2) <= size(binaryVol,2)) && (voxLoc(3) <= size(binaryVol,3)) && all(voxLoc >= 1))
                            if(binaryVol(voxLoc(1),voxLoc(2),voxLoc(3)))
                                out.AddLabel(i_loc,obj.internalLabels{i});
                                dist=0; %distance set to 0 if inside
                            end
                        end
                        old_data(end+1)=dist;
                        old_data_label{end+1}=obj.internalLabels{i};
                        out.SetAnnotation(i_loc,'Distance',old_data);
                        out.SetAnnotation(i_loc,'Label',old_data_label);                      
                     end
                end
            end

        end
    end
end

