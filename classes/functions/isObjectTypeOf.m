function res = isObjectTypeOf(obj,type)
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here
res=any(strcmp(superclasses(obj),type)) || strcmp(class(obj),type);
end

