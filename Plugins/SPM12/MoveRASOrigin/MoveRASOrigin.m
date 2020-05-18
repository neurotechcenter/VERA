classdef MoveRASOrigin < AComponent
    %ELECTRODEPROJECTION Summary of this class goes here
    %   Detailed explanation goes here
    
   properties
        Identifier
    end
    
    methods
        function obj = MoveRASOrigin()
            obj.Identifier='CT';
        end
        function Publish(obj)
            obj.AddInput(obj.Identifier,'Volume');
            obj.AddOutput(obj.Identifier,'Volume');
        end
        function Initialize(~)
            
        end
        
        function [vol] = Process(~,vol)
            vol.Image.hdr.hist.originator=round(size(vol.Image.img)/2);
            
        end
    end
end

