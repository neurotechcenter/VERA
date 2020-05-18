classdef Serializable < handle
    
    properties(Access = protected)
        ignoreList ={}
        acStorage ={}
        nodeName
    end

    methods
        function obj=Serializable()
            obj.nodeName=class(obj);
            obj.ignoreList= {};
        end
        
        function c = Serialize(obj,docNode)
            c=docNode.createElement(obj.nodeName);
            c.setAttribute('Type',class(obj))
            
            m=metaclass(obj);
            p={m.PropertyList.Name};
            removeIdx=[];
            for i=1:numel(m.PropertyList) %remove all items which do not have public set/get accessors and are not in the acStorage list
             if(~any(strcmp(obj.acStorage,m.PropertyList(i).Name)) && (iscell(m.PropertyList(i).GetAccess) ||...
                iscell(m.PropertyList(i).SetAccess)||...
                ~strcmp(m.PropertyList(i).GetAccess,'public') ||...
                ~strcmp(m.PropertyList(i).SetAccess,'public')))
                removeIdx(end+1)=i;
             end
            end
            p(removeIdx)=[];
            p=setdiff(p,obj.ignoreList);
            for i=1:numel(p)
                if(~isempty(obj.(p{i})))
                    settingel=docNode.createElement(p{i});
                    settingel.appendChild(docNode.createTextNode(jsonencode(obj.(p{i}))));
                    %changed to be saved as mat file for each component
                    c.appendChild(settingel);
                end
            end
            
        end
        
        function Deserialize(obj,docNode)
            if(~strcmp(docNode.Attributes.Type,class(obj)))
                error(['Cannot deserialize xml defined Type ' docNode.Attributes.Type ' to object of Type ' class(obj)]);
            end
            p=properties(obj);
            fileprops=fieldnames(docNode);
            remI=strcmp(fileprops,'Attributes') | strcmp(fileprops,'Text');
            fileprops(remI)=[];

            for i=1:numel(fileprops)
                par=docNode.(fileprops{i});
                if(any(strcmp(fileprops{i},p)))
                    par=docNode.(fileprops{i});
                    obj.(fileprops{i})=jsondecode(par{1}.Text);
%                 elseif(obj.allowDynamicProps)
%                     addprop(obj,fileprops{i});
%                     obj.(fileprops{i})=jsondecode(par{1}.Text);
                else
                    warning(['Property ' fileprops{i} ' cannot be set! Property is not defined in object of type ' class(obj)]);
                end
            end
        end
    end
end

