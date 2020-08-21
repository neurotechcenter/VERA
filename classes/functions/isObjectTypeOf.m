function res = isObjectTypeOf(obj,type)
%isObjectTypeOf Checks if the object is type or subtype 
% obj: object to be tested
% type name of the type to be tested against
res=any(strcmp(superclasses(obj),type)) || strcmp(class(obj),type);
end

