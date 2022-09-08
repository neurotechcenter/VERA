function [surf,lsphere,rsphere] = loadFSModelFromSubjectDir(freesurferPath,segmentationPath,fileoutPath,annotation)

xfrm_matrix_path=[fileparts(fileparts(mfilename('fullpath'))) '/scripts/get_xfrm_matrices.sh'];
xfrm_matrix_out_path=fileoutPath;
mri_path=fullfile(segmentationPath,'mri/orig.mgz');
if(~exist(mri_path,"file"))
    error('Could not find orig.mgz in the Freesurfer segmentation folder! Segmentation invalid!');
end
if(ismac || isunix)
    system(['chmod +x ''' xfrm_matrix_path ''''],'-echo');
    system([xfrm_matrix_path ' ''' freesurferPath ''' ''' ...
        mri_path ''' ''' ...
        xfrm_matrix_out_path ''''],'-echo');
elseif(ispc)
    subsyspath=DependencyHandler.Instance.GetDependency('UbuntuSubsystemPath');
    w_xfrm_matrix_path=convertToUbuntuSubsystemPath(xfrm_matrix_path,subsyspath);
    w_freesurferPath=convertToUbuntuSubsystemPath(freesurferPath,subsyspath);
    w_mri_path=convertToUbuntuSubsystemPath(mri_path,subsyspath);
    w_xfrm_matrix_out_path=convertToUbuntuSubsystemPath(xfrm_matrix_out_path,subsyspath);
    systemWSL(['chmod +x ''' w_xfrm_matrix_path ''''],'-echo');
    systemWSL(['''' w_xfrm_matrix_path ''' ''' w_freesurferPath ''' ''' ...
        w_mri_path ''' ''' ...
        w_xfrm_matrix_out_path ''''],'-echo');
else
    error('Couldnt determine operating system');
end

xfrm_matrices=importdata(fullfile(xfrm_matrix_out_path,'xfrm_matrices'));
vox2ras = xfrm_matrices(1:4, :);
vox2rastkr = xfrm_matrices(5:8, :);

%freesurfer 7 works with symlinks which cannot be resolved
%under windows so we need to get the correct target
fallbackSuffix='';
fd=dir(fullfile(segmentationPath,'surf/lh.pial'));
if(isempty(fd) || fd.bytes == 0) %something went wrong with the symlink
    fallbackSuffix='.T1';
    warning('lh.pial is 0 byte -- will fallback to lh.pial.T1 and rh.pial.T1');
end

if(ispc)
    pathToLhPial=resolveWSLSymlink(fullfile(segmentationPath,['surf/lh.pial' fallbackSuffix]),subsyspath);
    pathToRhPial=resolveWSLSymlink(fullfile(segmentationPath,['surf/rh.pial' fallbackSuffix]),subsyspath);
    pathToLhSphere=resolveWSLSymlink(fullfile(segmentationPath,'surf/lh.sphere.reg'),subsyspath);
    pathToRhSphere=resolveWSLSymlink(fullfile(segmentationPath,'surf/rh.sphere.reg'),subsyspath);
else
    pathToLhPial=resolveSymlink(fullfile(segmentationPath,['surf/lh.pial' fallbackSuffix]));
    pathToRhPial=resolveSymlink(fullfile(segmentationPath,['surf/rh.pial' fallbackSuffix]));
    pathToLhSphere=resolveSymlink(fullfile(segmentationPath,'surf/lh.sphere.reg'));
    pathToRhSphere=resolveSymlink(fullfile(segmentationPath,'surf/rh.sphere.reg'));
end
% [~,vox2ras]=system(['mri_info --vox2ras ' fullfile(segmentationFolder,'SUBJECT','')] );
% [~,vox2rastkr]=system(['mri_info --vox2ras-tkr ' fullfile(segmentationFolder,'SUBJECT','')] );%3d model is in ras-tkr format, we want RAS coordinates

tkr2ras=vox2ras*inv(vox2rastkr);
cortex=getCortexFromPath(pathToLhPial,pathToRhPial,tkr2ras);

surf.Model=cortex;
[~,llabel,lct]=read_annotation(fullfile(segmentationPath,['label/lh.' annotation '.annot']));
[~,rlabel,rct]=read_annotation(fullfile(segmentationPath,['label/rh.' annotation '.annot']));
%lhtri=lhtri+1;
%rhtri=rhtri+1+size(lhtri,1);
names={lct.struct_names{:} rct.struct_names{:}};
u_identifiers=[lct.table(:,5); rct.table(:,5)];
u_colortable=[lct.table(:,1:3); rct.table(:,1:3)]/255;
[u_identifiers,ia]=unique(u_identifiers);

names=names(ia);
u_colortable=u_colortable(ia,:);

surf.Annotation=[llabel; rlabel];
surf.AnnotationLabel=struct('Name',names','Identifier',num2cell(u_identifiers),'PreferredColor',num2cell(u_colortable,2));

[LHtempvert, LHtemptri] = read_surf(pathToLhSphere);
[RHtempvert, RHtemptri] = read_surf(pathToRhSphere);
lsph.vert=LHtempvert;
lsph.tri=LHtemptri+1;
lsph.vertId=ones(size(LHtempvert,1),1);
lsph.triId=ones(size(LHtemptri,1),1);

rsph.vert=RHtempvert;
rsph.tri=RHtemptri+1;
rsph.triId=2*ones(size(RHtemptri,1),1);
rsph.vertId=2*ones(size(RHtempvert,1),1);

lsphere.Annotation=llabel;
lsphere.AnnotationLabel=surf.AnnotationLabel;
lsphere.Model=lsph;



rsphere.Annotation=rlabel;
rsphere.AnnotationLabel=surf.AnnotationLabel;
rsphere.Model=rsph;
end

