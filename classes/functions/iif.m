function iif(res,eval1,eval2)
if(res)
    if(exist('eval1','var'))
        eval1();
    end
else
    if(exist('eval2','var'))
        eval2();
    end

end

