function obj_write_color(FV, filename, color_vector, colorMap, cmin, cmax, RGB_bins, transparency, vertexNormals)
% % writes wavefront OBJ file with user defined face colors.
% % face colors are defined as individual materials in the obj and
% % corresponding .mtl files
% %
% % FV: input struct defines faces and vertices of triangulated mesh 
% %       (for example output of isosurface function)
% % filename: string specifying names of .obj and .mtl file 
% %       (do not includefile ending)
% % colormap: Nx1 or 1xN array of colorvalues to be mapped onto the object
% %       N can be equal to the number of vertices in FV (each face color 
% %       will be defined as the average of all 3 face vertices)
% %       or N can be equal to the number of faces in FV
% %
% % optional inputs
% % colorMap: string defining, which colormap is to be used ('jet', 'cool',
% %       'autumn', 'colorcube', etc)
% %       default='jet'
% % cmin: scalar, specifies min of caxis (colorscale), every value below will be
% %       satureated at the low end of the colormap
% %       default= min(color_vector)
% % cmax: scalar, specifies max of caxis (colorscale), every value below will be
% %       satureated
% %       default= max(color_vector)
% % RGB_bins: scalar (>1) specifies number of bins for the color_vector, limiting the
% %       number of spereate materials created
% %       default= 512
% % transparency: scalar (>0, <=1), sets transparency of exported .obj object
% %       default= 1 (solid object)
% %
% % vertexNormals: 3xN array specifying vertex normals N=number of vertices


% check color_vector size
n = length(color_vector);
switch n
    case size(FV.vertices, 1)
            CData(1, :)=color_vector(FV.faces(:, 1));
            CData(2, :)=color_vector(FV.faces(:, 2));
            CData(3, :)=color_vector(FV.faces(:, 3));
            fc=squeeze(mean(CData, 1));
            fprintf('using vertex color average as face colors\n');
    case size(FV.faces, 1)
            fc=color_vector;
    otherwise
           	fprintf('unexpected color_vector size\n');
            fprintf('expected Nx1 array\n');
            fprintf('N should be equal to the number of vertices OR faces in FV\n');
            fprintf('terminating script\n');
            return
end

% set optional statements
if nargin<8; transparency=1; end
if nargin<7; RGB_bins=512; end
if nargin<6; cmax=max(fc); end
if nargin<5; cmin=min(fc); end
if nargin<4; colorMap='jet'; end


% % bin colors and create discrete colormap
% % in order to keep the number of materials to a set limit
cMap=colormap(strcat(colorMap, '(', num2str(RGB_bins), ')'));

cbin_edges=linspace(cmin, cmax, RGB_bins+1);
if min(fc)<cbin_edges(1)
    cbin_edges(1)=min(fc);  
end
if max(fc)>cbin_edges(end)
    cbin_edges(end)=max(fc);
end
[cVector_discreet, ~]=discretize(fc, cbin_edges);
f_cats=unique(cVector_discreet);

% % write .obj file
obj_filename=strcat(filename, '.obj');
fileID = fopen(obj_filename,'w');
fprintf(fileID,'mtllib %s.mtl\n', filename);
fprintf(fileID, 'g %s\n', filename);
fprintf(fileID,'v %f %f %f\n', FV.vertices');
if nargin==9
    fprintf(fileID,'vn %f %f %f\n', vertexNormals);
end
% % add different color faces
for i=1:length(f_cats)
    fprintf(fileID,'usemtl mat_%d\n', i);
    fprintf(fileID,'s 1\n');
    f_temp=FV.faces(cVector_discreet==f_cats(i), :)';
    fprintf(fileID,'f %d %d %d\n', f_temp);
end
fclose(fileID);

% % write corresponding .mtl file
mtl_filename=strcat(filename, '.mtl');
fileID = fopen(mtl_filename,'w');
for i=1:length(f_cats)
    fprintf(fileID,'newmtl mat_%d\n', i);
    fprintf(fileID,'Ka %f %f %f \n', cMap(f_cats(i),:));
    fprintf(fileID,'Kd %f %f %f \n', cMap(f_cats(i),:));
    fprintf(fileID,'Ks %f %f %f \n', cMap(f_cats(i),:));
    fprintf(fileID,'Ni 1.0 \n');
    fprintf(fileID,'illum 2 \n');
    fprintf(fileID,'d %f \n', transparency);
    fprintf(fileID,'Ns 100 \n \n');
end
fclose(fileID);
