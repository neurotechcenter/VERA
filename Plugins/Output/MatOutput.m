classdef MatOutput < AComponent
    %MATOUTPUT Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        ElectrodeLocationIdentifier
        SurfaceIdentifier
    end
    
    methods
        function obj = MatOutput()
            obj.ElectrodeLocationIdentifier='ElectrodeLocation';
            obj.SurfaceIdentifier='Surface';
        end
        
        function Publish(obj)
            obj.AddInput(obj.ElectrodeLocationIdentifier,'ElectrodeLocation');
            obj.AddInput(obj.SurfaceIdentifier,'Surface');
            
        end
        
        
        function Initialize(obj)
        end
        
        function []= Process(obj, eLocs,surf)
            
            cortex=surf.Model;
            ix=1;
            cmapstruct=struct('basecol',[0.7 0.7 0.7],'fading',1,'enablecolormap',1,'enablecolorbar',1,'color_bar_ticks',4,'cmap',jet(64),...
               'ixg2',9,'ixg1',-9,'cmin',0,'cmax',0);

            viewstruct.what2view={'brain' 'electrodes'};
            viewstruct.viewvect=[270 0];
            viewstruct.lightpos=[-150 0 0];
            viewstruct.material='dull';
            viewstruct.enablelight=1;
            viewstruct.enableaxis=0;
            viewstruct.lightingtype='gouraud';
            
            tala=struct('electrodes',eLocs.Location,'activations',zeros(size(eLocs.Location,1),1),'trielectrodes',eLocs.Location);
            vcontribs = [];
            [file,path]=uiputfile('*.mat');
            save(fullfile(path,file),'cortex','ix','tala','viewstruct','cmapstruct','vcontribs');
        end
        

    end
end

