classdef TalairachProjection < AComponent
    %TalairachProjection Projects a Surface into Talairach Coordinates,
    %requires manual selection of AC, PC and mid-sag
    
    properties
        MRIIdentifier
        SurfaceIdentifier
        SurfaceOutIdentifier
        ElectrodeLocationOutIdentifier
        ElectrodeLocationIdentifier
        AC
        PC
        MidSag
        ProjectionType
        AdditionalSurfaceIdentifiers
        AdditionalSurfaceOutIdentifiers
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
            obj.ProjectionType='Talairach';
            obj.AdditionalSurfaceIdentifiers={};
            
        end
        
        function Publish(obj)
            obj.AddInput(obj.MRIIdentifier,'Volume');
            obj.AddInput(obj.SurfaceIdentifier,'Surface');
            obj.AddInput(obj.ElectrodeLocationIdentifier,'ElectrodeLocation')
            obj.AddOutput(obj.SurfaceOutIdentifier,'Surface');
            obj.AddOutput(obj.ElectrodeLocationOutIdentifier,'ElectrodeLocation')
            for i=1:length(obj.AdditionalSurfaceIdentifiers)
                obj.AddInput(obj.AdditionalSurfaceIdentifiers{i},'Surface');
                obj.AddOutput(obj.AdditionalSurfaceOutIdentifiers{i},'Surface');
            end
        end
        
        function Initialize(obj)
            validatestring(obj.ProjectionType,{'talairach','mni','none'});
        end
        
        function varargout=Process(obj,mri,surf,eLocs,varargin)
            
            f=figure;
            AlignmentGUI('Parent',f,'Images',{mri.GetRasSlicedVolume()},'AlignmentParent',obj);
            uiwait(f);
            varargout{2}=obj.CreateOutput(obj.SurfaceOutIdentifier);
            varargout{2}.Annotation=surf.Annotation;
            varargout{2}.AnnotationLabel=surf.AnnotationLabel;
            varargout{2}.TriId=surf.TriId;
            varargout{2}.VertId=surf.VertId;
            
            varargout{1}=obj.CreateOutput(obj.ElectrodeLocationOutIdentifier);
            varargout{1}.DefinitionIdentifier=eLocs.DefinitionIdentifier;
            [varargout{2}.Model,varargout{1}.Location]=projectToStandard(surf.Model,eLocs.Location,[obj.AC(:)'; obj.PC(:)'; obj.MidSag(:)'],obj.ProjectionType);
            for i=1:length(obj.AdditionalSurfaceIdentifiers)
                varargout{2+i}=obj.CreateOutput(obj.AdditionalSurfaceIdentifiers{i},varargin{i});
                [~,varargout{2+i}.Model.vert]=projectToStandard(surf.Model,varargout{2+i}.Model.vert,[obj.AC(:)'; obj.PC(:)'; obj.MidSag(:)'],obj.ProjectionType);
            end
            
        end
    end
end

