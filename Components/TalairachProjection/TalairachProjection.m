classdef TalairachProjection < AComponent
    %TalairachProjection Projects a Surface into Talairach Coordinates
    
    properties
        MRIIdentifier
        SurfaceIdentifier
        SurfaceOutIdentifier
        ElectrodeLocationOutIdentifier
        ElectrodeLocationIdentifier
        AC
        PC
        MidSag
    end
    
    methods
        function obj = TalairachProjection()
            %UNTITLED Construct an instance of this class
            %   Detailed explanation goes here
            obj.AC=[];
            obj.PC=[];
            obj.MidSag=[];
            obj.MidSag=[];
            obj.MRIIdentifier='MRI';
            obj.SurfaceIdentifier='Surface';
            obj.SurfaceOutIdentifier='TalairachSurface';
            obj.ElectrodeLocationIdentifier='ElectrodeLocation';
            obj.ElectrodeLocationOutIdentifier='TailairachElectrodeLocation';
            
        end
        
        function Publish(obj)
            obj.AddInput(obj.MRIIdentifier,'Volume');
            obj.AddInput(obj.SurfaceIdentifier,'Surface');
            obj.AddInput(obj.ElectrodeLocationIdentifier,'ElectrodeLocation')
            obj.AddOutput(obj.SurfaceOutIdentifier,'Surface');
            obj.AddOutput(obj.ElectrodeLocationOutIdentifier,'ElectrodeLocation')
        end
        
        function Initialize(obj)
        end
        
        function [surfOut,eLocsOut]=Process(obj,mri,surf,eLocs)
            
            f=figure;
            AlignmentGUI('Parent',f,'Images',{mri.GetRasSlicedVolume()},'AlignmentParent',obj);
            uiwait(f);
            surfOut=obj.CreateOutput(obj.SurfaceOutIdentifier);
            surfOut.Annotation=surf.Annotation;
            surfOut.AnnotationLabel=surf.AnnotationLabel;
            surfOut.TriId=surf.TriId;
            surfOut.VertId=surf.VertId;
            
            eLocsOut=obj.CreateOutput(obj.ElectrodeLocationOutIdentifier);
            eLocsOut.DefinitionIdentifier=eLocs.DefinitionIdentifier;
            [surfOut.Model,eLocsOut.Location]=projectToStandard(surf.Model,eLocs.Location,[obj.AC(:)'; obj.PC(:)'; obj.MidSag(:)'],'talairach');
        end
    end
end

