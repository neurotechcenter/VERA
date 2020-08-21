function [electrodes,depthlst] = TraverseTree(tree,fieldNames,curr_depth)
%TraverseTree - Traverses through location connectivity tree to determine
%the electrode locations 
if(~exist('curr_depth','var'))
    curr_depth=1;
end
electrodes=[];
depthInfo.Depth=curr_depth;
depthInfo.Me=tree.Me;
depthlst={};
for ief=1:length(fieldNames)
    if(isfield(tree,fieldNames(ief)))
        [elecs,depthlist]=TraverseTree(tree.(fieldNames(ief)),fieldNames,curr_depth+1);
        depthlst={depthlist{:} depthlst{:}};
        electrodes=[electrodes elecs];
    else
        
    end
    
end
depthlst={depthlst{:} depthInfo};
electrodes=[electrodes tree.Me];

electrodes=unique(electrodes);
end

