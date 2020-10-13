function [brain,projectedElectrodes,alignment_coords] = projectToStandard(brain,electrodes,alignment_coords,projectionTarget)
%PROJECTTOSTANDARD Summary of this function goes here
%   Detailed explanation goes here
%  alignment_coords (x,y,z,ac,pc,mid_sag)

% talairach alignment: AC to PC = 23 mm 
% PC to most posterior: 79mm
% AC to most superior: 74mm
% AC to left or right: 68mm
% AC to most anterior: 70mm
%AC to most inferior:42mm

if(isempty(alignment_coords))
    warning('only ')
end
validateattributes(brain.vert,{'numeric'},{'size',[NaN,3]})
validateattributes(electrodes,{'numeric'},{'size',[NaN,3]})


validatestring(projectionTarget,{'talairach','mni','none'});

% http://brainmap.org/pubs/LancasterHBM07.pdf ... 1988 Atlas .. ish ... S-I
dist_ac_pc=23;
dist_ac_sup=74;
dist_ac_lr=68;
dist_ac_ant=70;
dist_pc_post=79;
dist_ac_inf=42;

% figure,viewBrain(brain),title('Original');buffbrain=brain; %%%%%%%%%%%plot
% transform to affine coordinates
alignment_coords=[alignment_coords ones(3,1)];
toProject=[brain.vert ones(size(brain.vert,1),1)];
projectedElectrodes=[electrodes ones(size(electrodes,1),1)];

ac_dat=alignment_coords(1,:);
pc_dat=alignment_coords(2,:);
mid_sag_dat=alignment_coords(3,:);


% first rotate to correct coordinates

% translation of AC to origin
[translate_xyz]                = affine_translation(-ac_dat(1), -ac_dat(2), -ac_dat(3));
delta_ac_pc   = pc_dat - ac_dat;
ac_dat   = (translate_xyz * ac_dat')';
pc_dat   = (translate_xyz * pc_dat')';
mid_sag_dat = (translate_xyz * mid_sag_dat')';



% rotation around x-axis to set PC z-coordinate to 0
rot_x = atan(delta_ac_pc(3)  / delta_ac_pc(2));
[rotate_x, ~, ~] = affine_rotation(-rot_x, 0, 0);
ac_dat = (rotate_x * ac_dat')';
pc_dat   = (rotate_x * pc_dat')';
mid_sag_dat = (rotate_x * mid_sag_dat')';

% rotation around z-axis to set PC x-coordinate to 0
delta_ac_pc   = pc_dat -ac_dat;
rot_z = atan(delta_ac_pc(1)  / delta_ac_pc(2));
[~, ~, rotate_z] = affine_rotation(0, 0, rot_z);
ac_dat = (rotate_z * ac_dat')';
pc_dat   = (rotate_z * pc_dat')';
mid_sag_dat = (rotate_z * mid_sag_dat')';

if(pc_dat(2) > 0) %pc has to be negative y direction, if not we need to rotate the whole thing by 180 on the z axis
[~, ~, rotate_z_1] = affine_rotation(0, 0, deg2rad(180));
ac_dat = (rotate_z_1 * ac_dat')';
pc_dat   = (rotate_z_1 * pc_dat')';
mid_sag_dat = (rotate_z_1 * mid_sag_dat')';
rotate_z=rotate_z* rotate_z_1;
end

% rotation around y-axis to set MID-SAG x-coordinate to 0
delta_mid_sag = pc_dat - mid_sag_dat;  
rot_y = atan(delta_mid_sag(1)/ delta_mid_sag(3));
[~, rotate_y, ~] = affine_rotation(0, -rot_y, 0);
ac_dat = (rotate_y * ac_dat')';
pc_dat = (rotate_y * pc_dat')';
mid_sag_dat = (rotate_y * mid_sag_dat')';



% perform rotation and translation
trans_ACPC = rotate_y * rotate_z * rotate_x * translate_xyz;
projected=(trans_ACPC * toProject')';
projectedElectrodes=(trans_ACPC * projectedElectrodes')';

% 
% buffbrain.vert=projected;
% figure,viewBrain(buffbrain),title('After rotation'); %%%%%%%%%plot

if(~strcmp(projectionTarget,'none'))
    %scale by ac pc distance .. we scale everything so that pc is correct
    y_scaler_ac_pc=dist_ac_pc/abs(pc_dat(2)-ac_dat(2));
    scaleM=affine_scaling(1,y_scaler_ac_pc,1);
    slice_start=[-inf -inf -inf];
    slice_end=[inf ac_dat(2) inf];
    projected=affine_transform_slice(projected,scaleM,slice_start,slice_end);
    %mid_sag_dat=affine_transform_slice(mid_sag_dat,scaleM,slice_start,slice_end);
    ac_dat=affine_transform_slice(ac_dat,scaleM,slice_start,slice_end);
    pc_dat=affine_transform_slice(pc_dat,scaleM,slice_start,slice_end);
    projectedElectrodes=affine_transform_slice(projectedElectrodes,scaleM,slice_start,slice_end);

    % buffbrain.vert=projected;
    % figure,viewBrain(buffbrain),title('Scaling of AC PC');

    % % scale posterior to pc
    % translate pc to origin ... do scaling... translate back
    [translate_xyz]                = affine_translation(-pc_dat(1), -pc_dat(2), -pc_dat(3));
    ac_dat   = (translate_xyz * ac_dat')';
    pc_dat   = (translate_xyz * pc_dat')';
    mid_sag_dat = (translate_xyz * mid_sag_dat')';
    projected = (translate_xyz * projected')';
    projectedElectrodes = (translate_xyz * projectedElectrodes')';

    % buffbrain.vert=projected;
    % figure,viewBrain(buffbrain),title('Translation for PC scaling');

    %do scaling
    y_scaler_posterior_pc=dist_pc_post/(abs(min(projected(:,2)))-abs(pc_dat(2)));
    scaleM=affine_scaling(1,y_scaler_posterior_pc,1);
    slice_start=[-inf -inf -inf];
    slice_end=[inf pc_dat(2) inf];
    projected=affine_transform_slice(projected,scaleM,slice_start,slice_end);
    mid_sag_dat=affine_transform_slice(mid_sag_dat,scaleM,slice_start,slice_end);
    ac_dat=affine_transform_slice(ac_dat,scaleM,slice_start,slice_end);
    projectedElectrodes=affine_transform_slice(projectedElectrodes,scaleM,slice_start,slice_end);
    pc_dat=affine_transform_slice(pc_dat,scaleM,slice_start,slice_end);


    % buffbrain.vert=projected;
    % figure,viewBrain(buffbrain),title(['PC to posterior scaler: ' num2str(y_scaler_posterior_pc)]);

    %translate back
    [translate_xyz]                = affine_translation(-ac_dat(1), -ac_dat(2), -ac_dat(3));
    ac_dat   = (translate_xyz * ac_dat')';
    pc_dat   = (translate_xyz * pc_dat')';
    mid_sag_dat = (translate_xyz * mid_sag_dat')';
    projected = (translate_xyz * projected')';
    projectedElectrodes = (translate_xyz * projectedElectrodes')';

    % buffbrain.vert=projected;
    % figure,viewBrain(buffbrain),title('translate back to AC');


    %scale ac to anterior

     y_dist=max(projected(:,2));
     y_scaler_anterior_ac=dist_ac_ant/abs(y_dist-ac_dat(2));

    scaleM=affine_scaling(1,y_scaler_anterior_ac,1);
    slice_start=[-inf ac_dat(2) -inf];
    slice_end=[inf inf inf];
    projected=affine_transform_slice(projected,scaleM,slice_start,slice_end,1);
    mid_sag_dat=affine_transform_slice(mid_sag_dat,scaleM,slice_start,slice_end,1);
    ac_dat=affine_transform_slice(ac_dat,scaleM,slice_start,slice_end,1);
    pc_dat=affine_transform_slice(pc_dat,scaleM,slice_start,slice_end,1);
    projectedElectrodes=affine_transform_slice(projectedElectrodes,scaleM,slice_start,slice_end,1);
    % 
    % buffbrain.vert=projected;
    % figure,viewBrain(buffbrain),title(['AC to anterior scaler: ' num2str(y_scaler_anterior_ac)]);

    % z scaler ac to sup 

    z_scaler_ac_to_sup=dist_ac_sup/(max(projected(:,3))- ac_dat(3)); %AC to most superior

    scaleM=affine_scaling(1,1,z_scaler_ac_to_sup);
    slice_start=[-inf -inf ac_dat(3)];
    slice_end=[inf inf inf];
    projected=affine_transform_slice(projected,scaleM,slice_start,slice_end,1);
    mid_sag_dat=affine_transform_slice(mid_sag_dat,scaleM,slice_start,slice_end,1);
    ac_dat=affine_transform_slice(ac_dat,scaleM,slice_start,slice_end,1);
    projectedElectrodes=affine_transform_slice(projectedElectrodes,scaleM,slice_start,slice_end,1);
    pc_dat=affine_transform_slice(pc_dat,scaleM,slice_start,slice_end,1);

    % buffbrain.vert=projected;
    % figure,viewBrain(buffbrain),title(['AC to superior scaler: ' num2str(z_scaler_ac_to_sup)]);

    % z scaler ac to inf

    z_scaler_ac_to_inf=dist_ac_inf/(ac_dat(3) - min(projected(:,3)));

    scaleM=affine_scaling(1,1,z_scaler_ac_to_inf);
    slice_start=[-inf -inf -inf];
    slice_end=[inf inf ac_dat(2)];
    projected=affine_transform_slice(projected,scaleM,slice_start,slice_end);
    mid_sag_dat=affine_transform_slice(mid_sag_dat,scaleM,slice_start,slice_end);
    ac_dat=affine_transform_slice(ac_dat,scaleM,slice_start,slice_end);
    projectedElectrodes=affine_transform_slice(projectedElectrodes,scaleM,slice_start,slice_end);
    pc_dat=affine_transform_slice(pc_dat,scaleM,slice_start,slice_end);

    % buffbrain.vert=projected;
    % figure,viewBrain(buffbrain),title(['AC to inferior scaler: ' num2str(z_scaler_ac_to_inf)]);

    % x scaler pos
    x_AC_lr=max(projected(:,1))- ac_dat(1);
    x_scaler=dist_ac_lr/x_AC_lr;
    scaleM=affine_scaling(x_scaler,1,1);
    slice_start=[ac_dat(1) -inf -inf];
    slice_end=[inf inf inf];
    projected=affine_transform_slice(projected,scaleM,slice_start,slice_end,1);
    projectedElectrodes=affine_transform_slice(projectedElectrodes,scaleM,slice_start,slice_end,1);

    % buffbrain.vert=projected;
    % figure,viewBrain(buffbrain),title(['x-pos hemisphere scaler: ' num2str(x_AC_lr)]);

    % x scaler neg
    x_AC_lr=abs(min(projected(:,1)))- ac_dat(1);
    x_scaler=dist_ac_lr/x_AC_lr;
    scaleM=affine_scaling(x_scaler,1,1);
    slice_start=[-inf -inf -inf];
    slice_end=[ac_dat(1) inf inf];
    projected=affine_transform_slice(projected,scaleM,slice_start,slice_end);
    projectedElectrodes=affine_transform_slice(projectedElectrodes,scaleM,slice_start,slice_end);
    
end
% 
% buffbrain.vert=projected;
% figure,viewBrain(buffbrain),title(['x-neg hemisphere scaler: ' num2str(x_AC_lr)]);



%remove affine coordinates
projectedBrain=projected(:,1:3);
projectedElectrodes=projectedElectrodes(:,1:3);
alignment_coords=[ac_dat(1:3);pc_dat(1:3);mid_sag_dat(1:3)];

if(strcmp(projectionTarget,'mni'))
     
       projectedBrain=tal2mni_2(projectedBrain')';
       projectedElectrodes=tal2mni_2(projectedElectrodes')';
       alignment_coords=tal2mni_2(alignment_coords')';
end

brain.vert=projectedBrain;


%http://imaging.mrc-cbu.cam.ac.uk/imaging/MniTalairach#Converting_MNI_coordinates_to_Talairach_coordinates



end

