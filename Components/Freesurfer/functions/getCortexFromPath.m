function cortex=getCortexFromPath(pathToLhPial,pathToRhPial,tkr2ras)
%getCortexFromPath create cortex struct from Freesurfer paths
%pathToLhPial - path to left hemisphere pial
%path to RhPial - path to right hemisphere pial
%tkr2ras - transformation matrix (usually tkr to RAS coordinate system)
        [LHtempvert, LHtemptri] = read_surf(pathToLhPial);
        [RHtempvert, RHtemptri] = read_surf(pathToRhPial);

        cortex.vert=[LHtempvert; RHtempvert];
        cortex.vertId=[ones(size(LHtempvert,1),1); 2*ones(size(RHtempvert,1),1)];
        cortex.vert=(tkr2ras*[cortex.vert(:,1), cortex.vert(:,2), cortex.vert(:,3), ones(size(cortex.vert, 1), 1)]')';
        cortex.vert=cortex.vert(:,1:3);
        LHtemptri = LHtemptri + 1;
        RHtemptri = RHtemptri + 1;

        adjustedRHtemptri = RHtemptri + size(LHtempvert, 1);
        cortex.tri = [LHtemptri; adjustedRHtemptri];
        cortex.triId=[ones(size(LHtemptri,1),1); 2*ones(size(adjustedRHtemptri,1),1)];
end