classdef FlipVolume < AComponent
    % FlipVolume flips the volume across a specified axis
   properties
        Identifier
        FlipAxis char
    end
    
    methods
        function obj = FlipVolume()
            obj.Identifier = 'CT';
            obj.FlipAxis   = 'x';
        end
        function Publish(obj)
            obj.AddInput(obj.Identifier,  'Volume');
            obj.AddOutput(obj.Identifier, 'Volume');
        end
        function Initialize(~)
            
        end
        
        function [vol] = Process(obj,vol)
            
            % Sagittal plane
            if strcmp(obj.FlipAxis,'x')
                T = [-1 0 0 0;
                     0  1 0 0;
                     0  0 1 0;
                     0  0 0 1];
            % Coronal plane
            elseif strcmp(obj.FlipAxis,'y')
                T = [1 0  0 0;
                     0 -1 0 0;
                     0 0  1 0;
                     0 0  0 1];
            % Transverse plane
            elseif strcmp(obj.FlipAxis,'z')
                T = [1 0 0  0;
                     0 1 0  0;
                     0 0 -1 0;
                     0 0 0  1];
            end
  
            vol.AddTransformation(T);
        end
    end
end