function obj_write(FV, filename, object)
% obj_write - saves a triangulated mesh struct (FV) as a wavefront obj
% file. 
%
% APPENDABLE. If "filename" already exists in the current folder. FV will
% be added as a new additional object to "filename" (can be used to wirte
% multiple objects to the same file). 
%
% only the obj file will be written. No material library will be generated
% or referenced. BUT, if appending to a file that is referencing a material
% library, the OBJ processing file will apply the last preceeding material
% to objects appended using obj_write (materials are always applied to all
% following faces until a new material is defined). This can be useful for
% combining multiple objects with the same material, without duplicating
% the material definitions (define for one object using obj_write_color or
% obj_write_manual_mtl and append additional objects using obj_write). 
% 
% Makes unix-specific system calls, which work on Unix or Mac Os but will
% cause issues on Windows or other systems. For a system independent
% version please see SYS_obj_write.m
% 
% Syntax:  
%     obj_write(FV, filename)
%     obj_write(FV, filename, object)
% 
% Inputs:
%    FV - struct with two fields (FV.faces and FV.vertices) defining
%         triangulated mesh
%    filename - string. Name of files to be saved without file extension
%         (automatically added)
%    object - OPTIONAL; string; optional statement defines the object group; 
%          this statemeent is not processed by any OBJ program but only
%          serves to help keep the file organized. By default the filename
%          and a running index number are used. 
% 
% Outputs:
%    .obj and .mtl files are written directly in the working directory 
%    no output into the workspace
%    a message in the console reports progress details
%  
% Example: 
%    see demo_obj.m
% 
% Other m-files required: none
% Subfunctions: none
% MAT-files required: none
% 

% Author: J. Benjamin Kacerovsky
% Centre for Research in Neuroscience, McGill University
% email: johannes.kacerovsky@mail.mcgill.ca
% Created: 30-Apr-2020 ; Last revision: 9-Jun-2020 

% ------------- BEGIN CODE --------------

if nargin<4
    object=filename;
end

% % write .obj file
obj_filename=strcat(filename, '.obj');

if ~isfile(obj_filename)
    fileID = fopen(obj_filename,'w'); % write new file
    fprintf(fileID,'g %s\n', filename);
    fprintf(fileID,'o %s\n', object);
    fprintf(fileID,'v %.4f %.4f %.4f\n', FV.vertices');
    fprintf(fileID,'usemtl mat_%d\n', 1);
    fprintf(fileID,'s 1\n');
    fprintf(fileID,'f %d %d %d\n', FV.faces');
    
else
    % update object if object name has been used previously 
    [~, Ocount]=system(sprintf('grep -c ''o %s'' %s', object, obj_filename)); 
    Ocount=str2double(Ocount)+1; 
    object=[object, '_', num2str(Ocount)]; 
    
    fileID = fopen(obj_filename,'a+'); %open and append existing file
    [~, Vcount]=system(['grep -c ''v '' ', obj_filename]);
    Vcount=str2double(Vcount);  % find how many vertices had already been assigned
    
    temp=FV.faces+Vcount;
    % % write .obj file
    fprintf(fileID,'o %s\n', object);
    fprintf(fileID,'v %.4f %.4f %.4f\n', FV.vertices');
    fprintf(fileID,'s 1\n');
    fprintf(fileID,'f %d %d %d\n', temp');
    
end

fclose(fileID);




% ------------- END OF CODE --------------
