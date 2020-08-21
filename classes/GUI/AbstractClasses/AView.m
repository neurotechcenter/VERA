classdef AView < handle & Serializable
    %AVIEW Abstract class for all Views displayed in the right part of the
    %GUI
    %See also Serializable, handle
    
    properties (Access = public, SetObservable)
        Name % Name of the View
        AvailableData containers.Map %Data available to the View
    end
    
    methods
        function obj = AView()
            
            obj.AvailableData = containers.Map();
            addlistener(obj,'AvailableData','PostSet',@obj.dataChanged);
            obj.Name = class(obj);
        end
        
        function Refresh(obj)
            %Refresh - call to abstract dataUpdate method
            obj.dataUpdate();
        end
        
    end
    
    methods (Access = protected)
        
        function dataChanged(obj,~,~)
            obj.dataUpdate();
        end
        
    end
    
    methods(Abstract, Access = protected)
        %dataUpdate - Method will be called each time AvailableData is
        %updated
       dataUpdate(obj);

    end
end

