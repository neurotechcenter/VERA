classdef AView < handle & Serializable
    %AVIEW Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (Access = public, SetObservable)
        Name
        AvailableData containers.Map
    end
    
    methods
        function obj = AView()
            
            obj.AvailableData = containers.Map();
            addlistener(obj,'AvailableData','PostSet',@obj.dataChanged);
            obj.Name = class(obj);
        end
        
        function Refresh(obj)
            obj.dataUpdate();
        end
        
    end
    
    methods (Access = protected)
        
        
        function dataChanged(obj,~,~)
            obj.dataUpdate();
        end
        
    end
    
    methods(Abstract, Access = protected)
       dataUpdate(obj);

    end
end

