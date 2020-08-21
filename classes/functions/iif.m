function varargout=iif(res,eval1,eval2)
%iif - inline if, similar to conditional operator
%Usage
% iif(a > 3,@fun1,@fun2)
% if a is bigger than 3, fun1 will be called, otherwise fun2 will be called
% returns the output of eval function
if(res)
    if(exist('eval1','var'))
        [varargout{:}]=eval1();
    end
else
    if(exist('eval2','var'))
        [varargout{:}]=eval2();
    end

end

