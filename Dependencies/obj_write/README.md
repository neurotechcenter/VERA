# .obj export functions for Matlab
## saves Wavefront .obj files from matlab

**Saves triangulated meshes (FV struct, such as the output from the built-in isosurface function) as .obj files, together with the corresponding .mtl files in the current working directory.**

[![View Save Wavefront .OBJ files (simple or colour) on File Exchange](https://www.mathworks.com/matlabcentral/images/matlab-file-exchange.svg)](https://www.mathworks.com/matlabcentral/fileexchange/72906-save-wavefront-obj-files-simple-or-colour)

Examples for how these functions can be used and combined to save multiple different mesh objects (with different types of material/colour definitions) into a single obj file are shown in demo_obj.m 
The resulting .obj and .mtl files have been uploaded as **examples** to poly.google.com: 
- [googlePoly Example1](https://poly.google.com/view/5N0rs0RgEQV)
- [googlePoly Example2](https://poly.google.com/view/60c2exp4Riu)

The functions obj_write* make unix-specific system calls to use grep. This works for MacOS and all unix based OS, but will not run in Ms or some other OS. For systems that do not have command line "grep" available please use the functions starting with SYS_* in the folder systemIndependentFunnctions which use: 
us (2020). grep: a pedestrian, very fast grep utility ([fileexchange/9647-grep-a-pedestrian-very-fast-grep-utility](https://www.mathworks.com/matlabcentral/fileexchange/9647-grep-a-pedestrian-very-fast-grep-utility)), MATLAB Central File Exchange. Retrieved June 12, 2020. 
These should work on all systems. Syntax and usage is identical to obj_write*

- obj_write: 
Saves the triangulated input mesh as a simple wavefront .obj files. No additional inputs or settings are required, only the FV struct and filename to be saved. 
If "filename" already exists in the current folder. FV will be added as a new additional object to "filename" (can be used to write multiple objects to the same file). 
If the previous file already has mtl definitions programs reading the .obj file will apply the last material to following objects (allows multiple additional objects to be added without duplicate mtl definitions).

- obj_write_vertex_colors: 
Saves the triangulated input mesh as a wavefront .obj files with vertex colours. Additional material properties can be defined (one material for the entire mesh, colour information saved with vertex definitions). Colours can be defined by a vector and colormap 8analogous to patch) or as a Nx3 matrix of RGB values.

- obj_write_manual_mtl: 
Saves the triangulated input mesh as a wavefront .obj files with manually defined materials. Materials can be defined manually for the entire object or for each vertex/face, giving more direct control and flexibility than obj_write_color.m. 
OBJ materials components (Ka, Ks, Kd, d, Ns, Ni, illum) can be defined: 
	- for the entire object (single value) 
	- for each face (will be accepted and written as is) 
	- for each vertex (will be converted to face values by using the median 
value of adjacent vertices; analogous to 'facecolor', 'flat' in patch) 
If "filename" already exists in the current folder. FV will be added as a new additional object to "filename".

- obj_write_color: 
Writes wavefront OBJ file with user-defined face/vertex colours. 
Colours are defined as individual materials in the obj and corresponding .mtl files. colours can be defined as a continuous variable vector for each 
face/vertex or as RGB triplets. obj takes a color_vector as input (similar to the input to patch) and passes the reformatted colour data to obj_write_manual_mtl (after performing appropriate binning, resizing, and conversion to RGB colours). 
If "filename" already exists in the current folder. FV will be added as a new additional object to "filename". 
colours can be defined: 
	- for each face 
	- for each vertex (will be converted to face values by using the median value of adjacent vertices; analogous to 'facecolor', 'flat' in patch) 
colours will be binned to reduce the number of individual materials (see RGB_bins in the input is a vector it will be converted to RGB colours using the specified colorMap.

- Previous versions on obj_write_color and obj_write_RGB are saved in a subfolder "old"
