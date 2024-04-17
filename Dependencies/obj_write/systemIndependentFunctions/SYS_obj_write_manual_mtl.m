function SYS_obj_write_manual_mtl(FV, filename, Ka, varargin)
% obj_write_manual_mtl - writes triangulated mesh objects to wavefront obj 
% with manually defined materials 
% material light qualities can be defined manually for the entire object or
% for each vertex/face. 
% REQUIRES grep.m (see below) but should run on all systems
%
% gives more direct control and flexibility than obj_write_color.m
%
% materials components (Ka, Ks, Kd, d, Ns, Ni, illum) can be defined:
%   - for the entire object (single value)
%   - for each face (will be accepted and written as is) 
%   - for each vertex (will be converted to face values by using the median
%        value of adjacent vertices; analogous to 'facecolor', 'flat' in patch) 
%
% APPENDABLE. If "filename" already exists in the current folder. FV will
% be added as a new additional object to "filename" (can be used to write
% multiple objects to the same file). 
% 
% Syntax:  
%     obj_write_manual_mtl(FV, filename, Ka)
%     obj_write_manual_mtl(FV, filename, Ka, ..., 'Name', value)
% 
% Required Inputs:
%    FV - struct with two fields (FV.faces and FV.vertices) defining
%         triangulated mesh
%    filename - string. Name of files to be saved without file extension
%         (automatically added)
%    Ka - 1x3 vector/RGB triplet defining ambinent light for the entire
%         object
%         OR Nx3 matrix where each row defines the RGB triplet
%         corresponding to one vertex or one face
%
% Optional Inputs as Name-Value pairs
%    'object' - string; optional statement defines the object group; 
%          this statemeent is not processed by any OBJ program but only
%          serves to help keep the file organized. By default the filename
%          and a running index are used. 
%    'Kd' - defines diffuse light; same format as Ka
%         if not specified Ka values will be used for Kd
%    'Ks' - defines specular light; same format as Ka
%         if not specified Ka values will be used for Kd
%    'Tf' - Transmission filter; same format as Ka
%         default 0
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
%    see demo.m
% 
% Other m-files required: grep.m
% us (2020). grep: a pedestrian, very fast grep utility (https://www.mathworks.com/matlabcentral/fileexchange/9647-grep-a-pedestrian-very-fast-grep-utility), MATLAB Central File Exchange. Retrieved June 11, 2020.
% 

% Author: J. Benjamin Kacerovsky
% Centre for Research in Neuroscience, McGill University
% email: johannes.kacerovsky@mail.mcgill.ca
% Created: 11-Jun-2020 ; Last revision: 11-Jun-2020 

% ------------- BEGIN CODE --------------

% parse inputs
p=inputParser; 
kScal=@(x) isnumeric(x)&&((size(x, 1)==1)||(size(x, 1)==size(FV.vertices, 1)||size(x, 1)==size(FV.faces, 1)));
dScal=@(x) isnumeric(x)&&((length(x)==1)||(length(x)==size(FV.vertices, 1)||length(x)==size(FV.faces, 1)));

addRequired(p, 'Ka', kScal);
addParameter(p, 'd', 1, dScal); 
addParameter(p, 'Kd', Ka, kScal); 
addParameter(p, 'Ks', Ka, kScal); 
addParameter(p, 'Ns', repmat(100, 1, size(Ka, 1)), dScal); 
addParameter(p, 'Ni', ones(1, size(Ka, 1)), dScal); 
addParameter(p, 'Tf', zeros(size(Ka)), kScal); 
addParameter(p, 'illum', repmat(2, 1, size(Ka, 1)), dScal); 
addParameter(p, 'object', filename, @isstr); 

parse(p, Ka, varargin{:});

Ka=p.Results.Ka;
d=colOrient(p.Results.d);
Kd=p.Results.Kd;
Ks=p.Results.Ks;
Tf=p.Results.Tf;
Ns=colOrient(p.Results.Ns); 
Ni=colOrient(p.Results.Ni);
illum=colOrient(p.Results.illum); 
object=p.Results.object;

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
fprintf(fileID,'v %f %f %f\n', FV.vertices');
    
n = max([size(Ka, 1), size(Kd, 1), size(Ks, 1), length(d), length(illum), length(Ns), length(Ni)]);

switch n
    case 1  % same material is assigned for all faces (all input variable havee exactly one value)
        fprintf('single input material -> used for all faces\n'); 
        fprintf(fileID,'usemtl mat_%s_singleColor_%d\n', object, Mcount+1);
        fprintf(fileID,'s 1\n');
        fprintf(fileID,'f %d %d %d\n', (f_new)');     %update v indexing
        fclose(fileID);
        
        % % write corresponding .mtl file
            mtl_filename=strcat(filename, '.mtl');
            fileID = fopen(mtl_filename,'a+');
            fprintf(fileID,'newmtl mat_%s_singleColor_%d\n', object, Mcount+1);
            fprintf(fileID,'Ka %f %f %f \n', Ka);
            fprintf(fileID,'Kd %f %f %f \n', Kd);
            fprintf(fileID,'Ks %f %f %f \n', Ks);
            fprintf(fileID,'Tf %f %f %f \n', Tf);
            fprintf(fileID,'Ni %f \n', Ni);
            fprintf(fileID,'illum %d \n', illum);
            fprintf(fileID,'d %f \n', d);
            fprintf(fileID,'Ns %f \n \n', Ns);
            fclose(fileID);
        
    case {size(FV.vertices, 1); size(FV.faces, 1)}   % color is specified for each individual vertex (if any of thee inputs have more than one value)
        fprintf('check size: Ka '); 
            Ka=sizeFix(Ka, FV); 
        fprintf('check size: Kd '); 
            Kd=sizeFix(Kd, FV); 
        fprintf('check size: Ks '); 
            Ks=sizeFix(Ks, FV); 
        fprintf('check size: Ni '); 
            Tf=sizeFix(Tf, FV);             
        fprintf('check size: d '); 
            d=sizeFix(d, FV); 
        fprintf('check size: Ns '); 
            Ns=sizeFix(Ns, FV); 
        fprintf('check size: Ni '); 
            Ni=sizeFix(Ni, FV); 
        fprintf('check size: illum '); 
            illum=sizeFix(illum, FV); 
            
        MTL_list=[Ka, Kd, Ks, d, Ns, Ni, illum, Tf];
        [mtl_unique, ~, ic]=unique(MTL_list, 'rows');
                
        for i=1:size(mtl_unique, 1)
            fprintf(fileID,'usemtl manualMat_%s_%d\n', object, i+Mcount);
            fprintf(fileID,'s 1\n');
            f_temp=f_new(ic==i, :)';
            fprintf(fileID,'f %d %d %d\n', f_temp);
        end
        fclose(fileID);
        for i=1:size(mtl_unique, 1)
        % % write corresponding .mtl file
            
            mtl_filename=strcat(filename, '.mtl');
            fileID = fopen(mtl_filename,'a+');
            fprintf(fileID,'newmtl manualMat_%s_%d\n', object, i+Mcount);
            fprintf(fileID,'Ka %f %f %f \n', mtl_unique(i, 1:3));
            fprintf(fileID,'Kd %f %f %f \n', mtl_unique(i, 4:6));
            fprintf(fileID,'Ks %f %f %f \n', mtl_unique(i, 7:9));
            fprintf(fileID,'Tf %f %f %f \n', mtl_unique(i, 14));
            fprintf(fileID,'Ni %f \n', mtl_unique(i, 12));
            fprintf(fileID,'illum %d \n', mtl_unique(i, 13));
            fprintf(fileID,'d %f \n', mtl_unique(i, 10));
            fprintf(fileID,'Ns %f \n \n', mtl_unique(i, 11));
            fclose(fileID);
        end
        
    otherwise % input sizes should already be checked by the input parser, so there is really no way this should ever be called
        fprintf('unexpected size for one of the material deefinition variables\n');
        fprintf('Ka, Kd, and Ks should be 1x3 or Nx3 arrays\n');
        fprintf('d, Ni, Ns, and illum should be Nx1 vectors or scalars \n');
        fprintf('N is equal to the number of vertices OR faces in FV\n');
        fprintf('terminating script\n');
    return

end % end case
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
