function [intersection] = recursiveIntersect(varargin)
    if(length(varargin)==1)
        intersection = varargin{1};
    elseif(length(varargin)==2)
        intersection=intersect(varargin{1},varargin{2});
    else
        intersection=recursiveIntersect(varargin{1:end-2},intersect(varargin{end-1},varargin{end}));
    end
        

end

