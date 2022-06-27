function res = compareStrings(s1,s2)
%compare for strings that handles cell strings correctly
if(iscell(s1) && iscell(s2))
    res=all(cellfun(@(x) all(strcmp(x,s2)),s1));
elseif(~iscell(s1) && ~iscell(s2))
    res=strcmp(s1,s2);
else
    res = false; %cant be identical if they are not the same type 
end

end

