function obj_write_RGB(FV, filename, rgbVector, RGB_bins, transparency, vertexNormals)
% % writes wavefront OBJ file with user defined face colors.
% % face colors are defined as individual materials in the obj and
% % corresponding .mtl files
% %
% % FV: input struct defines faces and vertices of triangulated mesh 
% %       (for example output of isosurface function)
% % filename: string specifying names of .obj and .mtl file 
% %       (do not includefile ending)
% % rgbVector: Nx3 array of RGB triplet colorvalues
% %       N can be equal to the number of vertices in FV (each face color 
% %       will be defined as the average of all 3 face vertices)
% %       or N can be equal to the number of faces in FV
% % optional inputs
% % RGB_bins: scalar (>1) specifies number of bins for each row in rgbVector, limiting the
% %       number of spereate materials created
% %       default= 32
% % transparency: scalar (>0, >=1), sets transparency of exported .obj object
% %       default= 1 (solid object)
% %
% % vertexNormals: 3xN array specifying vertex normals N=number of vertices

if nargin<5; transparency=1; end
if nargin<4; RGB_bins=32; end

n = size(rgbVector, 1);
switch n
    case size(FV.vertices, 1)
            CData(1, :, :)=rgbVector(FV.faces(:, 1), :);
            CData(2, :, :)=rgbVector(FV.faces(:, 2), :);
            CData(3, :, :)=rgbVector(FV.faces(:, 3), :);
            fc=squeeze(mean(CData, 1));
            fprintf('using vertex color average as face colors\n');
    case size(FV.faces, 1)
            fc=rgbVector;
    otherwise
           	fprintf('unexpected color_vector size\n');
            fprintf('expected Nx3 array\n');
            fprintf('N should be equal to the number of vertices OR faces in FV\n');
            fprintf('terminating script\n');
            return
end


[r_discreet, cbin_edges]=discretize(fc(:, 1), RGB_bins);
[g_discreet, ~]=discretize(fc(:, 2), RGB_bins);
[b_discreet, ~]=discretize(fc(:, 3), RGB_bins);

h2=horzcat(r_discreet, g_discreet, b_discreet);

f_cats=unique(h2, "rows");

cvals=(cbin_edges(1:end-1)+cbin_edges(2:end))./2;


obj_filename=strcat(filename, '.obj');
fileID = fopen(obj_filename,'w');
fprintf(fileID,'mtllib %s.mtl\n', filename);
fprintf(fileID, 'g %s\n', filename);
fprintf(fileID,'v %f %f %f\n', FV.vertices');
% % add vertex nomals if specified
if nargin==6
    fprintf(fileID,'vn %f %f %f\n', vertexNormals);
end
% % add different color faces
for i=1:length(f_cats)
    fprintf(fileID,'usemtl mat_%d\n', i);
    fprintf(fileID,'s 1\n');
    sel=h2(:,1)==f_cats(i, 1)&h2(:, 2)==f_cats(i, 2)&h2(:, 3)==f_cats(i, 3);
    f_temp=FV.faces(sel, :)';
    fprintf(fileID,'f %d %d %d\n', f_temp);
end
fclose(fileID);

mtl_filename=strcat(filename, '.mtl');
fileID = fopen(mtl_filename,'w');
for i=1:length(f_cats)
    fprintf(fileID,'newmtl mat_%d\n', i);
    fprintf(fileID,'Ka %f %f %f \n', cvals(f_cats(i,:)));
    fprintf(fileID,'Kd %f %f %f \n', cvals(f_cats(i,:)));
    fprintf(fileID,'Ks %f %f %f \n', cvals(f_cats(i,:)));
    fprintf(fileID,'Ni 1.0 \n');
    fprintf(fileID,'illum 2 \n');
    fprintf(fileID,'d %f \n', transparency);
    fprintf(fileID,'Ns 100 \n \n');
end
fclose(fileID);
