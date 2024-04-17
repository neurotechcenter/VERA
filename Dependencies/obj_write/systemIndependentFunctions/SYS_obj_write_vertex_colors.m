function SYS_obj_write_vertex_colors(FV, filename, colors, varargin)
% obj_write_vertexColors - writes wavefront OBJ file with user-defined face/vertex
% colors.
% Colors are defined as individual materials in the obj and corresponding .mtl files
% colors can be defined as a continuous variable vector for each
% face/vertex or as RGB triplets
% REQUIRES grep.m (see below) but should run on all systems
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
% Syntax:  
%     obj_write_vertexColors(FV, filename, colors);
%     obj_write_vertexColors(FV, filename, colors, ..., 'Name', value);
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
%    'object' - string; optional statement defines the object group; 
%          this statemeent is not processed by any OBJ program but only
%          serves to help keep the file organized. By default the filename
%          and a running index are used. 
%    'Kd' - 1x3 veector (RGB triplet); defines diffuse light; default=[];
%         if not specified Ka values will be used for Kd
%    'Ks' -  1x3 veector (RGB triplet); defines diffuse light; default=[];
%
% Additional optional OBJ material definition inputs:
%    'd' - scalar; defining dissolve factor/transparency
%         (values from 0 (completely dissolved) to 1 (fully opaque))
%    'Ns' - scalar; defining specular exponent 
%         (values from 0 to 1000)
%         default=100; 
%    'Ni' - scalar; defining optical density/index of refraction 
%         (values from 0.001 to 10) 
%         default=1; 
%    'illum' - scalar; illumination model 
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
% Created: 13-Jun-2020 ; Last revision: 13-Jun-2020 

% ------------- BEGIN CODE --------------

p=inputParser; 
dScal=@(x) isnumeric(x)&&(length(x)==size(FV.vertices, 1)||length(x)==size(FV.faces, 1));
numScal=@(x) isnumeric(x)&&isscalar(x); 
kScal=@(x) isnumeric(x)&&numel(x)==3;

addRequired(p, 'FV', @isstruct);
addRequired(p, 'filename', @isstr);
addRequired(p, 'colors', dScal);
addParameter(p, 'Kd', [], kScal); 
addParameter(p, 'Ks', [], kScal); 
addParameter(p, 'colorMap', 'jet', @isstr); 
addParameter(p, 'cmin', min(colors(:)), numScal); 
addParameter(p, 'cmax', max(colors(:)), numScal); 
addParameter(p, 'RGB_bins', [], numScal); 
addParameter(p, 'd', 1, numScal); 
addParameter(p, 'Ns', 100, @(x) numScal(x)&&x<=1000); 
addParameter(p, 'Ni', 1, @(x) numScal(x)&&x<=10); 
addParameter(p, 'illum', 2, @(x) isscalar(x)&&x<=10&&mod(x, 1)==0); 
addParameter(p, 'object', filename, @isstr);

colors=colOrient(colors); 

parse(p, FV, filename, colors, varargin{:});

colorMap=p.Results.colorMap;
d=p.Results.d;
cmin=p.Results.cmin;
cmax=p.Results.cmax;
RGB_bins=p.Results.RGB_bins;
object=p.Results.object;
Ns=p.Results.Ns; 
Ni=p.Results.Ni;
Kd=p.Results.Kd;
Ks=p.Results.Ks;
illum=p.Results.illum; 

    if isvector(colors)    
        % % bin colors and create discrete colormap
        % % in order to keep the number of materials to a set limit
        
        if isempty(RGB_bins)
            RGB_bins=length(unique(colors(colors>cmin&colors<cmax)));
        end
        
        cMap=colormap(strcat(colorMap, '(', num2str(RGB_bins), ')'));
       
        cbin_edges=linspace(cmin, cmax, RGB_bins+1);
            if min(colors)<cbin_edges(1)
                cbin_edges(1)=min(colors);  
            end
            if max(colors)>cbin_edges(end)
                cbin_edges(end)=max(colors);
            end
            
        [cVector_discreet, ~]=discretize(colors, cbin_edges);
        RGB=cMap(cVector_discreet, :); 
        
        writeFun(FV, filename, RGB, d, Ns, Ni, illum, object, Kd, Ks);
        
    elseif size(colors, 2)==3
               
        writeFun(FV, filename, colors, d, Ns, Ni, illum, object, Kd, Ks);
    else
        fprintf('unexpected size "colors" input\nexpected 1xN or Nx3 but found %d %d', size(colors));
    end
end

function writeFun(FV, filename, RGB, d, Ns, Ni, illum, object, Kd, Ks)

% % write .obj file
obj_filename=strcat(filename, '.obj');

    if ~isfile(obj_filename) % new file if no previous file with the same name exists in the current folder
        fileID = fopen(obj_filename, 'w');
        fprintf(fileID,'mtllib %s.mtl\n', filename);
        fprintf(fileID, 'g %s\n', filename);
        Vcount=0;
        Mcount=0;

    else  % if filename already exists in current folder skip header (FV will be appended to current file) and update Vertex, mtl, object indexing
        % update object if object name has been used previously 
        [~, Ocount]=grep('-c', sprintf('o %s', object), obj_filename);
        Ocount=Ocount.result;
        Ocount=str2double(Ocount)+1; 
        object=[object, '_', num2str(Ocount)]; 

        % update vertex and mtl indexing
        fileID = fopen(obj_filename,'a+');
        [~, Vcount]=grep('-c', 'v ', obj_filename);
        Vcount=Vcount.result;
        Vcount=str2double(Vcount);  % find how many vertices had already been assigned
        [~, Mcount]=grep('-c', 'newmtl ', strcat(filename, '.mtl'));
        Mcount=Mcount.result;
        Mcount=str2double(Mcount);  % find how many materials had already been assigned
    end
    
    f_new=FV.faces+Vcount;
    fprintf(fileID, 'o %s\n', object);
    fprintf(fileID,'v %.4f %.4f %.4f %.4f %.4f %.4f \n', [FV.vertices'; RGB']);

    fprintf(fileID,'usemtl mat_%s_singleColor_%d\n', object, Mcount+1);
    fprintf(fileID,'s 1\n');
    fprintf(fileID,'f %d %d %d\n', (f_new)');     %update v indexing
    fclose(fileID);

    % % write corresponding .mtl file 
    % since we are using vertex colors Ka and Tf are not specified
    % in the mtl. Only one mtl is written for the object (specifying,
    % illumination, dissolve and specular properties)
    % Kd and Ks can optionally be specified (but only for the entire
    % object) 
    mtl_filename=strcat(filename, '.mtl');
    fileID = fopen(mtl_filename,'a+');
    fprintf(fileID,'newmtl mat_%s_singleColor_%d\n', object, Mcount+1);
    if ~isempty(Kd)
        fprintf(fileID,'Kd %.4f %.4f %.4f \n', Kd);
    end
    
    if ~isempty(Ks)
        fprintf(fileID,'Ks %.4f %.4f %.4f \n', Ks);
    end
    fprintf(fileID,'Ni %.4f \n', Ni);
    fprintf(fileID,'illum %d \n', illum);
    fprintf(fileID,'d %.4f \n', d);
    fprintf(fileID,'Ns %.4f \n \n', Ns);
    fclose(fileID);

end

function x=colOrient(x)
        if size(x, 1)<size(x, 2)
            x=x';
        end
end

% ------------- END OF CODE --------------
