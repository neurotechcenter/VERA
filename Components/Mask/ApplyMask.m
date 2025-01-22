classdef ApplyMask < AComponent
    %ApplyMask Apply a predefined Mask to an image - requires reslicing of
    %the mask
    % Often combined with the BuildSkullMask component
    properties
        InputIdentifier
        MaskIdentifier
        OutputIdentifier
    end
    
    methods
        function obj = ApplyMask()
           obj.InputIdentifier='CT';
           obj.MaskIdentifier='Skullmask';
           obj.OutputIdentifier='CT';
        end
        function Publish(obj)
            obj.AddInput(obj.InputIdentifier,'Volume');
            obj.AddInput(obj.MaskIdentifier,'Volume');
            obj.AddOutput(obj.OutputIdentifier,'Volume');
        end
        
        function Initialize(obj)


        end
         function out=Process(obj,vol,mask)
             %reslice mask to fit the input volume
             resl_mask=fullfile(obj.GetDependency('TempPath'),'resliced_mask.nii');
             reslice_nii(mask.Path,resl_mask,vol.Image.hdr.dime.pixdim(2));
             vol_mask=fullfile(obj.GetDependency('TempPath'),'vol_resliced_mask.nii');
             reslice_nii(vol.Path,vol_mask,vol.Image.hdr.dime.pixdim(2));
             vol.LoadFromFile(vol_mask);
             out=obj.CreateOutput(obj.OutputIdentifier);
             out.LoadFromFile(resl_mask);
             vol.Image.img=vol.Image.img-min(min(min(vol.Image.img)));
             
             mask_orig=([1 1 1]-out.Image.hdr.hist.originator(1:3)).*out.Image.hdr.dime.pixdim(2:4);
             vol_orig=([1 1 1]-vol.Image.hdr.hist.originator(1:3)).*vol.Image.hdr.dime.pixdim(2:4);
             cpy_orig=min(mask_orig-vol_orig,mask_orig);
             
             vol_pxl_orig=round((cpy_orig./vol.Image.hdr.dime.pixdim(2:4))+vol.Image.hdr.hist.originator(1:3));
             vol_pxl_begin=round(max(vol_pxl_orig,[1 1 1]));
             vol_pxl_offset=min(vol_pxl_orig,[0 0 0]);
             out_pxl_begin=abs(vol_pxl_offset)+1;
             vol_pxl_end=min(size(out.Image.img),size(vol.Image.img)-vol_pxl_begin);
             
             imgX=out_pxl_begin(1):vol_pxl_end(1);
             imgY=out_pxl_begin(2):vol_pxl_end(2);
             imgZ=out_pxl_begin(3):vol_pxl_end(3);
             maskX=vol_pxl_begin(1):vol_pxl_begin(1)+length(imgX)-1;
             maskY=vol_pxl_begin(2):vol_pxl_begin(2)+length(imgY)-1;
             maskZ=vol_pxl_begin(3):vol_pxl_begin(3)+length(imgZ)-1;
             out.Image.img(imgX,imgY,imgZ)=out.Image.img(imgX,imgY,imgZ).*vol.Image.img(maskX,maskY,maskZ);
             
         end
    end
end

