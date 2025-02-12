classdef ManualVolumeAlignment < AComponent
    %ManualVolumeAlignment provides functionality for manually aligning a
    %volume (e.g., MRI or CT scan) into a standard coordinate system
    %(such as Talairach coordinates). This alignment requires the user to
    %manually select anatomical landmarks (Anterior Commissure (AC),
    %Posterior Commissure (PC), and Mid-Sagittal point) through a
    %graphical user interface (GUI).
    
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
            obj.TIdentifier='TManual';
            
        end
        
        function Publish(obj)
            obj.AddInput(obj.VolumeIdentifier,'Volume');
            obj.AddOptionalInput(obj.TIdentifier,'TransformationMatrix');
            obj.AddOutput(obj.VolumeIdentifier,'Volume');
            obj.AddOutput(obj.TIdentifier,'TransformationMatrix');
        end
        
        function Initialize(obj)
        end
        
        function [mriOut,Tout]=Process(obj,mri,varargin)

            Tout=obj.CreateOutput(obj.TIdentifier);
            mriOut=obj.CreateOutput(obj.VolumeIdentifier,mri);

            if nargin > 2
                Tout.T = varargin{2}.T;
            else
                f=figure;
                AlignmentGUI('Parent',f,'Images',{mri.GetRasSlicedVolume()},'AlignmentParent',obj);
                uiwait(f);
    
                model.vert=zeros(0,3);
                [~,~,~,Tout.T]=projectToStandard(model,zeros(0,3),[obj.AC(:)'; obj.PC(:)'; obj.MidSag(:)'],'none');

            end

            mriOut.AddTransformation(Tout.T);

            T = Tout.T;
            save(fullfile(obj.ComponentPath,'xfrm_matrix.txt'),'T','-ascii')
            
        end
    end
end

