classdef AlignmentGUI < SliceViewerXYZ
    %ALIGNMENTGUI Summary of this class goes here
    %   Detailed explanation goes here
    properties
        popupMenu
        AlignmentParent
    end
    
    properties (Access = protected)
        slMin
        slMax
        grid
    end
    
    
    methods
        function obj = AlignmentGUI(varargin)
            obj.supressUpdate=false;
            obj.grid=uix.Grid('Parent',obj);
            obj.popupMenu=uicontrol('Parent',obj.grid,'Style','popupmenu','String',{'AC','PC','Mid-Sag'},'Callback',@obj.AlignmentselectionChanged);
            addlistener(obj,'Cursor','PostSet',@obj.alignemntPosChanged);
            obj.slMin=uicontrol('Parent',obj.grid,'Style','slider','Min',0,'Max',1,'Value',1);
            obj.slMax=uicontrol('Parent',obj.grid,'Style','slider','Min',0,'Max',1,'Value',1);
            obj.grid.Widths=[-1];
            obj.grid.Heights=[-1 -1 -1];
             try
              uix.set( obj, varargin{:} )
             catch e
              delete( obj )
              e.throwAsCaller()
             end
            clims=obj.GetColorLimits();
            obj.supressUpdate=true;
            obj.slMin.Min=clims(1);
            obj.slMin.Max=clims(2);
            obj.slMin.Value=clims(1);
            obj.slMax.Min=clims(1);
            obj.slMax.Max=clims(2);
            obj.slMax.Value=clims(2);
            addlistener(obj.slMin, 'Value', 'PostSet',@obj.changecMin);
            addlistener( obj.slMax, 'Value', 'PostSet',@obj.changecMax);
            obj.supressUpdate=false;
        end
        
        function AlignmentselectionChanged(obj,~,~)
            if(isempty(obj.AlignmentParent))
                return;
            end
            if(obj.popupMenu.Value == 1)
                if(~isempty(obj.AlignmentParent.AC))
                    obj.Cursor=obj.AlignmentParent.AC;
                else
                    obj.Cursor=[];
                end
            elseif(obj.popupMenu.Value == 2)
                if(~isempty(obj.AlignmentParent.PC))
                    obj.Cursor=obj.AlignmentParent.PC;
                else
                    obj.Cursor=[];
                end
            elseif(obj.popupMenu.Value == 3)
                if(~isempty(obj.AlignmentParent.MidSag))
                    obj.Cursor=obj.AlignmentParent.MidSag;
                else
                    obj.Cursor=[];
                end
            end
        end
        
        function alignemntPosChanged(obj,~,~)
            if(isempty(obj.AlignmentParent))
                return;
            end
            if(obj.popupMenu.Value == 1)
               obj.AlignmentParent.AC=  obj.Cursor;  
            elseif(obj.popupMenu.Value == 2)
                obj.AlignmentParent.PC=  obj.Cursor;  
            elseif(obj.popupMenu.Value == 3)
                obj.AlignmentParent.MidSag=  obj.Cursor;  
            end 
        end
        
        function changecMin(obj,~,~)
            if(obj.supressUpdate)
                return;
            end
            if(obj.slMin.Value >= obj.slMax.Value)
                obj.supressUpdate=true;
                set(obj.slMin,'Value',obj.slMax.Value-1);
                obj.supressUpdate=false;
            end
            obj.SetColorLimits([obj.slMin.Value obj.slMax.Value]);
            
        end
        function changecMax(obj,~,~)
           if(obj.supressUpdate)
                return;
           end
           if(obj.slMax.Value <= obj.slMin.Value)
                obj.supressUpdate=true;
                obj.slMax.Value=obj.slMin.Value+1;
                obj.supressUpdate=false;
           end
            obj.SetColorLimits([obj.slMin.Value obj.slMax.Value]);
        end

    end
end

