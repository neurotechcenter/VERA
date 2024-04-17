function obj_write_color(FV, filename, colors, varargin)
% obj_write_color - writes wavefront OBJ file with user-defined face/vertex
% colors.
% Colors are defined as individual materials in the obj and corresponding .mtl files
% colors can be defined as a continuous variable vector for each
% face/vertex or as RGB triplets
%
% APPENDABLE. If "filename" already exists in the current folder. FV will
% be added as a new additional object to "filename" (can be used to write
% multiple objects to the same file). 
%
% Makes unix-specific system calls, which work on Unix or Mac Os but will
% cause issues on Windows or other systems. For a system independent
% version please see SYS_obj_write_color.m
%
% colors can be defined:
%   - for each face 
%   - for each vertex (will be converted to face values by using the median
%        value of adjacent vertices; analogous to 'facecolor', 'flat' in patch)
% colors will be binned to reduce the number of individual materials (see
%      RGB_bins
% in the input is a vector it will be converted to RGB colors ussing the
%   specified colorMap
%
% colors will be used for ambient (Ka), diffuse (Kd), and specular (Ks)
% light; for manual control over these settings please use obj_write_manual_mtl.m
% 
% Syntax:  
%     obj_write_color(FV, filename, colors);
%     obj_write_color(FV, filename, colors, ..., 'Name', value);
% 
% Required Inputs:
%    FV - struct with two fields (FV.faces and FV.vertices) defining
%         triangulated mesh
%    filename - string. Name of files to be saved without file extension
%         (automatically added)
%         if filename.obj exists already. The existing file will be
%         appended 
%    colors - 1xN vector defining color values for each face or for each
%         vertex (as would be passed to patch as faceveertexcdata)
%         OR Nx3 matrix where each row defines the RGB triplet
%         corresponding to one vertex or one face
%         N=number of vertices or faces
%
% Optional Inputs as Name-Value pairs
%    'colorMap' - string; defines the matlab builtin colormap that should be used
%          to convert the color vector into RGBB colors; Default= 'jet'
%    'cmin' - scalar; defines low end of color scale (analogous to defining caxis
%          in a matlab figure)
%    'cmax' - scalar; defines low end of color scale (analogous to defining caxis
%          in a matlab figure)
%    'RGB_bins' - scalar (>1) specifies number of bins for the color_vector, limiting the
%           number of spereate materials created; Default= 512
%           works well for color vector; in color input is RGB triplets the
%           actual number of bins can differ significantly from the targeet
%           value; 
%    'object' - string; optional statement defines the object group; 
%          this statemeent is not processed by any OBJ program but only
%          serves to help keep the file organized. By default the filename
%          and a running index are used. 
%
% Additional optional OBJ material definition inputs:
%    'd' - scalar or Nx1 vector; defining dissolve factor/transparency
%         (values from 0 (completely dissolved) to 1 (fully opaque))
%    'Ns' - scalar or Nx1 vector; defining specular exponent 
%         (values from 0 to 1000)
%         default=100; 
%    'Ni' - scalar or Nx1 vector; defining optical density/index of refraction 
%         (values from 0.001 to 10) 
%         default=1; 
%    'illum' - scalar or Nx1 vector; illumination model 
%         (integer 0-10) 
%         default=2; 
%    for a guide to OBJ material definitions see for example: http://paulbourke.net/dataformats/mtl/
% 
% Outputs:
%    .obj and .mtl files are written directly in the working directory 
%    no output into the workspace
%    a message in the console reports progress details
% 
% Example: 
%    see demo_obj.m
% 
% 
% See also: obj_write_manual_mtl.m,  obj_write.m

% Author: J. Benjamin Kacerovsky
% Centre for Research in Neuroscience, McGill University
% email: johannes.kacerovsky@mail.mcgill.ca
% Created: 05-Jun-2020 ; Last revision: 15-Feb-2021 

% ------------- BEGIN CODE --------------

p=inputParser; 
dScal=@(x) isnumeric(x)&&(length(x)==size(FV.vertices, 1)||length(x)==size(FV.faces, 1));
dScal2=@(x) isnumeric(x)&&((length(x)==1)||(length(x)==size(FV.vertices, 1)||length(x)==size(FV.faces, 1)));
numScal=@(x) isnumeric(x)&&isscalar(x); 
addRequired(p, 'FV', @isstruct);
addRequired(p, 'filename', @isstr);
addRequired(p, 'colors', dScal);
addParameter(p, 'colorMap', 'jet', @isstr); 
addParameter(p, 'cmin', double(min(colors(:))), numScal); 
addParameter(p, 'cmax', double(max(colors(:))), numScal); 
addParameter(p, 'RGB_bins', 512, numScal); 
addParameter(p, 'd', 1, numScal); 
addParameter(p, 'object', filename, @isstr);
addParameter(p, 'Ns', repmat(100, 1, size(FV.faces, 1)), dScal2); 
addParameter(p, 'Ni', ones(1, size(FV.faces, 1)), dScal2); 
addParameter(p, 'illum', repmat(2, 1, size(FV.faces, 1), 1), dScal2); 

colors=colOrient(colors); 
colors=sizeFix(colors, FV); 

parse(p, FV, filename, colors, varargin{:});

colorMap=p.Results.colorMap;
d=p.Results.d;
cmin=p.Results.cmin;
cmax=p.Results.cmax;
RGB_bins=p.Results.RGB_bins;
object=p.Results.object;
Ns=p.Results.Ns; 
Ni=p.Results.Ni;
illum=p.Results.illum; 

    if isvector(colors)    
        % % bin colors and create discrete colormap
        % % in order to keep the number of materials to a set limit
        cMap=colormap(strcat(colorMap, '(', num2str(RGB_bins), ')'));
        cbin_edges=linspace(cmin, cmax, RGB_bins+1);
            if min(colors)<cbin_edges(1)
                cbin_edges(1)=min(colors);  
            end
            if max(colors)>cbin_edges(end)
                cbin_edges(end)=max(colors);
            end
        [cVector_discreet, ~]=discretize(colors, cbin_edges);
        c=cMap(cVector_discreet, :); 
        
        obj_write_manual_mtl(FV, filename, c, 'Kd', c, 'Ks', c, 'd', d, 'object', object, 'Ns', Ns, 'Ni', Ni, 'illum', illum); 
    
    elseif size(colors, 2)==3
        
        [r_discreet, rbin_edges]=discretize(colors(:, 1), floor(RGB_bins^(1/2)*2)); % I am not entirely sure why, but this resultss in roughly the right number of bins
        [g_discreet, gbin_edges]=discretize(colors(:, 2), floor(RGB_bins^(1/2)*2));
        [b_discreet, bbin_edges]=discretize(colors(:, 3), floor(RGB_bins^(1/2)*2));
        
        rbin_edges=(rbin_edges(1:end-1)+rbin_edges(2:end))./2;
        gbin_edges=(gbin_edges(1:end-1)+gbin_edges(2:end))./2;
        bbin_edges=(bbin_edges(1:end-1)+bbin_edges(2:end))./2;
                
        c=horzcat(rbin_edges(r_discreet)', gbin_edges(g_discreet)', bbin_edges(b_discreet)');
        obj_write_manual_mtl(FV, filename, c, 'Kd', c, 'Ks', c, 'd', d, 'object', object, 'Ns', Ns, 'Ni', Ni, 'illum', illum); 
    else
        fprintf('unexpected size "colors" input\nexpected 1xN or Nx3 but found %d %d', size(colors));
    end
end

function x=sizeFix(x, FV)
    switch size(x, 1)
        case size(FV.vertices, 1) % convert vertex materials to face materials (obj defines mtl for faces) 
            temp=[];
            temp(:, :, 1)=x(FV.faces(:, 1), :);
            temp(:, :, 2)=x(FV.faces(:, 2), :);
            temp(:, :, 3)=x(FV.faces(:, 3), :);
            x=median(temp, 3);   %% by using median instead of average we avoid introducing additional Ka values but should be restricted to only values that were defined manually
            
            fprintf('lenght matches n vertices -> using vertex color median as face mtl definition\n'); 
        case size(FV.faces, 1) % input defines face mtl. do nothing
            fprintf('lenght matches n faces -> using as face mtl definition  without modification\n');
        case 1
            x=repmat(x, size(FV.faces, 1), 1); % repeat the single input vale for all faces
            fprintf('single value -> repeat for all faces mtl definition\n');
    end
end

function x=colOrient(x)
        if size(x, 1)<size(x, 2)
            x=x';
        end
end

% ------------- END OF CODE --------------
