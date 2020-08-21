function [name_t] = createUniqueName(name,nameList)
    %createUniqueName - creates a unique name that is not in the list
    %name - input string
    %nameList - already existing name
    %returns: unique new name
    name_t=name;
    i=1;
    while(any(strcmp(nameList,name_t)))
        name_t=[name '_' num2str(i)];
        i=i+1;
    end

end

