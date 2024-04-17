% first I will build some test objects and display them as a matlab figure.
% Then I will export the meshes as an obj file
% the result can be seen at https://poly.google.com/view/5N0rs0RgEQV
% and at https://poly.google.com/view/60c2exp4Riu

% the test objects in this file are built using functions in: 
% J. Benjamin Kacerovsky (2020). Build mesh or voxel spheres, ellipsoids, and test objects 
% (https://www.mathworks.com/matlabcentral/fileexchange/75241-build-mesh-or-voxel-spheres-ellipsoids-and-test-objects)
% MATLAB Central File Exchange. Retrieved June 10, 2020.

%% first group of objects which i will use to demo obj_write_manual_mtl, obj_write_color, and obj_write
clf
set(gca, 'Color', 'black'); 
axis equal; hold on;    
% build example mesh as a FV struct (see isosurface) 
object=starship(0); 
patch(object, 'facecolor', [0 0 1], 'edgecolor', 'none'); 

% create another transparent object with random colourmap around our test
% object(just eye-balling here. gptoolbox has a great tool for creating
% proper minimum enclosing ellipsoids, but for an example this should do
sp=meshSphereCreator(30, [30, 20, 21], 'Ysquash', 3, 'Zsquash', 2, 'step', 0.5); 
%
ff=fspecial('gaussian', [1, 25], 10); 
c=conv2(ff, ff, rand(1, size(sp.vertices, 1)), 'same')'; 
p=patch(sp, 'facevertexcdata', c, 'facecolor', 'interp', 'edgecolor', 'none', 'facealpha', 0.3); 
colormap jet

% create some background objects
sp2=meshSphereCreator(8, [40, 35, 40], 'Ysquash', 17, 'Zsquash', 17); 
patch(sp2, 'facecolor', [1 1 0], 'edgecolor', 'none');
%
% create more background objects at random distances from the previous
% centre (min displacement so they fall outside of sp); 
n=50; 
randDisplacement=(rand(n, 3)-0.5);
randDisplacement=randDisplacement./sqrt(sum(randDisplacement.^2, 2)).*(rand(n, 3)*30+[50, 10, 20]);
randCentres=repmat([30, 19, 21], n, 1)+randDisplacement; 

sp3=multiMeshElipsoidCreator(repmat(8, 1, n), randCentres, repmat([1, 17, 17], n, 1), zeros(size(randCentres)), 0.5);
patch(sp3, 'facecolor', [1 1 0], 'edgecolor', 'none'); 
% ylim([-20, 55]);
% xlim([-50, 110]);
camlight

%% another collection of objects to demo obj_write_vertexColors
figure
set(gca, 'Color', 'black'); 
axis equal; hold on;   
patch(object, 'facecolor', [0 0 1], 'edgecolor', 'none'); 

% create "planet" as sphere;  by stringing together a couple of
% trigfunctions I can create a complicated banding pattern to colour the
% surfacee
plan=meshSphereCreator(25); 
[X, Y, Z]=meshgrid(-25:25, -25:25, -25:25); 
C=sin(tan((X+10)*0.1).*2).*sin(tan((X+12).*-0.09).*2.1)+sin(X+Y.*-0.2).*sin(X.*0.2+Y.*0.2)*0.4;
C=C.*sin(X.*0.2); 
cPlan=isocolors(X, Y, Z, C, plan.vertices);
c=conv2(ff, ff, cPlan, 'same')';

rotMatZ=[cosd(-110), -sind(-110), 0;
        sind(-110), cosd(-110), 0;
        0, 0, 1];
    
plan.vertices=plan.vertices*rotMatZ;
plan.vertices=plan.vertices+[80, 0, -60];

patch(plan, 'facecolor', 'interp', 'facevertexcdata', cPlan, 'edgecolor', 'none'); 

[X, Y, Z]=meshgrid(-80:80, -80:80, -80:80); 

R=[46, 52, 59, 65, 70, 74];
r=[1.7, 1.5, 2, 1.5, 2, 2.5]; 
stepSize=0.5;

centres=zeros(length(R), 3); 
deform=repmat([1, 4, 1], length(R), 1);
rotation=repmat([0, 10, 20], length(R), 1);

% create concentric squasheed rings around the sphere with concentric
% colour pattern
rings=multiMeshToroidCreator(R, r, centres, deform, rotation, stepSize);

C=((X.^2.+Y.^2+Z.^2).*3).^(1/2);
C=sin(C)./C; 
cRings=isocolors(X, Y, Z, C, rings.vertices)*100;

rings.vertices=rings.vertices+[80, 0, -60];

hold on 
patch(rings, 'FaceColor', 'interp', 'facevertexcdata', cRings, 'edgecolor', 'none'); 


%%

% now lets see how we would export this
% first the "object" as a single color, opaque (default d=1) but very reflective; 
% with obj_write_manual_mtl I can directly specify the culor for the object

obj_write_manual_mtl(object, 'demo', [0 0 1], 'Ns', 800, 'illum', 3, 'object', 'object'); 

% then add the sp as a "bubble" around "object"
% color is definded as a vector. obj_write color converts the colorvector
% to suitable RGB values and passes it into obj_write_manual_mtl
% using the same "filename" tell the function to append the file written
% above
% (the same would work if c were a Nx3 matrix defining RGB triplets for
% every vertex or for every face); 

obj_write_color(sp, 'demo', c, 'colorMap', 'jet', 'RGB_bins', 512, 'd', 0.02, 'Ns', 200, 'Ni', 1, 'illum', 5, 'object', 'bubble');

% add the first background object
% since they are supposed to be reminiscnet of stars I chose materials that
% are indepeendent of lightsources

obj_write_manual_mtl(sp2, 'demo', [1 1 0], 'Ns', 0, 'illum', 0, 'object', 'background'); 

% finally, since the additional background objects are supposed to use the 
% same material, I can add them additional using obj_write, which does not
% add or reference any materials. This avoids creating duplicate materials
% (in obj all faces use the last material that was referenced, until a new 
% material is assigned). 

obj_write(sp3, 'demo', 'more_bachground'); 


%% exporting using vertex colors
% for the "ship" same as above"
obj_write_manual_mtl(object, 'demo2', [0 0 1], 'Ns', 800, 'illum', 3, 'object', 'object'); 

% syntax is similar to obj_write_color but colour values are saved as
% vertex colours
obj_write_vertex_colors(plan, 'demo2', cPlan, 'colorMap', 'copper', 'Ns', 10, 'Ks', [1, 0, 0], 'illum', 4, 'object', 'planet'); 
obj_write_vertex_colors(rings, 'demo2', cRings, 'colorMap', 'winter', 'Ns', 1, 'illum', 3, 'object', 'rings'); 


