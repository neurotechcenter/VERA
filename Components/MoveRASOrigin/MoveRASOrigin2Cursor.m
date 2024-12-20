classdef MoveRASOrigin2Cursor < AComponent
    %MoveRASOrigin2Cursor Moves the origin of RAS to the cursor location
    %(not working)
   properties (Access = public,SetObservable)
        Identifier
        CursorPosition = []; %Cursor position for each image
    end
    
    methods
        function obj = MoveRASOrigin2Cursor()
            obj.Identifier='CT';

            % addlistener(obj,'CursorPosition','PostSet',@obj.cursorPosChanged);
        end
        function obj = Publish(obj)
            obj.AddInput(obj.Identifier,'Volume');
            obj.AddOutput(obj.Identifier,'Volume');

            addlistener(obj,'CursorPosition','PostSet',@obj.cursorPosChanged);
        end
        function Initialize(~)
            
        end
        
        function [vol] = Process(~,vol,obj)
            img_size=round(size(vol.Image.img)/2);

            
            

            obj.CursorPosition

            if(vol.Image.hdr.dime.pixdim(1) == 1)
                vol.Image.hdr.hist.srow_x(4)=-vol.Image.hdr.dime.pixdim(2)*img_size(1);
                vol.Image.hdr.hist.srow_y(4)=-vol.Image.hdr.dime.pixdim(3)*img_size(2);
                vol.Image.hdr.hist.srow_z(4)=-vol.Image.hdr.dime.pixdim(4)*img_size(3);
            else 
                vol.Image.hdr.hist.srow_x(4)=-vol.Image.hdr.dime.pixdim(2)*img_size(1);
                vol.Image.hdr.hist.srow_y(4)=vol.Image.hdr.dime.pixdim(3)*img_size(2);
                vol.Image.hdr.hist.srow_z(4)=-vol.Image.hdr.dime.pixdim(4)*img_size(3);

            end
        end
    end
end

