function [surf,lsphere,rsphere] = loadFSModelFromSubjectDir(freesurferPath,segmentationPath,fileoutPath,annotation,pialfile)
    if(~exist('pialfile','var'))
        pialfile='pial';
    end
    if(ispc)
        subsyspath=DependencyHandler.Instance.GetDependency('UbuntuSubsystemPath');
    else
        subsyspath='';
    end
    
    xfrm_matrices=loadXFRMMatrix(freesurferPath,segmentationPath,fileoutPath,subsyspath);
    vox2ras = xfrm_matrices(1:4, :);
    vox2rastkr = xfrm_matrices(5:8, :);
    
    tkr2ras=vox2ras/(vox2rastkr);
    
    
    [lh_pial,rh_pial]=loadFSSurface(pialfile,segmentationPath,subsyspath);
    lh_pial.vertId=ones(size(lh_pial.vert,1),1);
    lh_pial.triId=ones(size(lh_pial.tri,1),1);
    
    
    rh_pial.triId=2*ones(size(rh_pial.tri,1),1);
    rh_pial.vertId=2*ones(size(rh_pial.vert,1),1);
    surf.Model=transformPial(mergePials(lh_pial,rh_pial),tkr2ras);
    [~,llabel,lct]=read_annotation(fullfile(segmentationPath,['label/lh.' annotation '.annot']));
    [~,rlabel,rct]=read_annotation(fullfile(segmentationPath,['label/rh.' annotation '.annot']));
    %lhtri=lhtri+1;
    %rhtri=rhtri+1+size(lhtri,1);
    names=[lct.struct_names(:)' rct.struct_names(:)'];
    u_identifiers=[lct.table(:,5); rct.table(:,5)];
    u_colortable=[lct.table(:,1:3); rct.table(:,1:3)]/255;
    [u_identifiers,ia]=unique(u_identifiers);
    
    names=names(ia);
    u_colortable=u_colortable(ia,:);
    
    surf.Annotation=[llabel; rlabel];
    surf.AnnotationLabel=struct('Name',names','Identifier',num2cell(u_identifiers),'PreferredColor',num2cell(u_colortable,2));
    if(nargout > 1) %only load spheres if we need them
        [lsph,rsph]=loadFSSurface('sphere',segmentationPath,subsyspath);
        lsph.vertId=ones(size(lsph.vert,1),1);
        lsph.triId=ones(size(lsph.tri,1),1);
        
        
        rsph.triId=2*ones(size(rsph.tri,1),1);
        rsph.vertId=2*ones(size(rsph.vert,1),1);
        
        lsphere.Annotation=llabel;
        lsphere.AnnotationLabel=surf.AnnotationLabel;
        lsphere.Model=lsph;
        
        
        
        rsphere.Annotation=rlabel;
        rsphere.AnnotationLabel=surf.AnnotationLabel;
        rsphere.Model=rsph;
    end
end

