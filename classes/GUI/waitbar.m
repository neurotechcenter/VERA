function h = waitbar(x,whichbar, varargin)
%%override of standard waitbar function with fallback to default behavior -
%%call to waitbar will try to resolve towards an active UnifiedProgressbar
%%if available

try
        h_int=DependencyHandler.Instance.GetDependency('unifiedProgressbar');
        if(ishandle(whichbar))
            h=whichbar;
            nameid=find(strcmp(varargin,'Name'), 1);
            if(~isempty(nameid))
                h_int.ShowProgressBar(x,varargin{nameid+1});
            else
                
                h_int.ShowProgressBar(x,whichbar.UserData);
            end
        else
            nameid=find(strcmp(varargin,'Name'), 1);
            if(isempty(nameid))
                name=whichbar;
            else
                name=varargin{nameid+1};
            end
            h_int.ShowProgressBar(x,name);
            h=figure('Visible','off','DeleteFcn',@(x,y)figDelete(h_int,x,y)); %create fake handle...
            h.UserData=name;
        end
        
       
catch e
        disp(e.message);
        f=getoriginalFunHandle();
        h=f(x,whichbar, varargin{:});
end
end

function figDelete(h_int,~,~,~)
    if(isvalid(h_int) && h_int.supercede) h_int.resumeGUI(); end
end

function fun=getoriginalFunHandle()
    curdir = pwd;
    t = which('waitbar', '-all');
    fuzdir = fileparts(t{2});
    cd(fuzdir); 
    fun = @waitbar;
    cd(curdir); 
end

