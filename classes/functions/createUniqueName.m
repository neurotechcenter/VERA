function [name_t] = createUniqueName(name,nameList)
                name_t=name;
                i=1;
                while(any(strcmp(nameList,name_t)))
                    name_t=[name '_' num2str(i)];
                    i=i+1;
                end

end

