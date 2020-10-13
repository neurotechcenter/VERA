function [intersection] = recursiveIntersect(varargin)
%recursiveIntersect - recursive intersection for more than 2 input arrays
% usage recursiveIntersect(arr1,arr2,arr3);
%returns values that exist in all arrays
    if(length(varargin)==1)
        intersection = varargin{1};
    elseif(length(varargin)==2)
        intersection=intersect(varargin{1},varargin{2});
    else
        intersection=recursiveIntersect(varargin{1:end-2},intersect(varargin{end-1},varargin{end}));
    end
        

end

