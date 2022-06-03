classdef ManualVolumeAlignment < AComponent
    %TalairachProjection Projects a Surface into Talairach Coordinates,
    %requires manual selection of AC, PC and mid-sag
    
    properties
        VolumeIdentifier
        TIdentifier
        AC
        PC
        MidSag
    end
    
    methods
        function obj = ManualVolumeAlignment()
            %UNTITLED Construct an instance of this class
            %   Detailed explanation goes here
            obj.AC=[];
            obj.PC=[];
            obj.MidSag=[];
            obj.MidSag=[];
            obj.VolumeIdentifier='CT';
            obj.TIdentifier='T';
            
        end
        
        function Publish(obj)
            obj.AddInput(obj.VolumeIdentifier,'Volume');
            obj.AddOutput(obj.VolumeIdentifier,'Volume');
            obj.AddOutput(obj.TIdentifier,'TransformationMatrix');
        end
        
        function Initialize(obj)
        end
        
        function [mriOut,Tout]=Process(obj,mri)
            
            f=figure;
            AlignmentGUI('Parent',f,'Images',{mri.GetRasSlicedVolume()},'AlignmentParent',obj);
            uiwait(f);

            model.vert=zeros(0,3);
            Tout=obj.CreateOutput(obj.TIdentifier);
            mriOut=obj.CreateOutput(obj.VolumeIdentifier,mri);
            [~,~,~,Tout.T]=projectToStandard(model,zeros(0,3),[obj.AC(:)'; obj.PC(:)'; obj.MidSag(:)'],'none');
            mriOut.AddTransformation(Tout.T);
            
            
        end
    end
end

