classdef Serializable < handle
    %Serializeable - Handles serialization of objects
    %Inherit from this class to enable easy serialization
    %
    properties(Access = protected)
        ignoreList ={} % List of properties to be ignored during serialization
        acStorage ={} %List of non-public properties that should be stored
        nodeName % Name of the xml tag for serialization
    end
    
    methods(Access = protected)
        function deSerializationDone(obj,docNode)
            %deSerializationDone is called after deserialization for
            %initial initialization
        end
    end

    methods
        function obj=Serializable()
            % Constructor
            obj.nodeName=class(obj);
            obj.ignoreList= {};
        end
        
        function c = Serialize(obj,docNode)
            % Serialize - Adds a the object to the docNode of an xml object
            % docNode - xml node under which you would like to serialize the object 
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
                    if(~isa(obj.(p{i}),'char') && isObjectTypeOf(obj.(p{i}),'Serializable'))
                        settingel=obj.(p{i}).Serialize(docNode);
                    else
                        settingel=docNode.createElement(p{i});
                        settingel.appendChild(docNode.createTextNode(jsonencode(obj.(p{i}))));
                    end
                    %changed to be saved as mat file for each component
                    c.appendChild(settingel);
                end
            end
            
        end
        
        function Deserialize(obj,docNode)
            % Deserialize - Sets all properties defined by the xml node
            % docNode - xml node
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
                    if(isfield(par{1},'Attributes') && isfield(par{1}.Attributes,'Type'))
                        data=feval(par{1}.Attributes.Type);
                        data.Deserialize(par{1});
                        obj.(fileprops{i})=data;
                    else
                        obj.(fileprops{i})=jsondecode(par{1}.Text);
                    end
%                 elseif(obj.allowDynamicProps)
%                     addprop(obj,fileprops{i});
%                     obj.(fileprops{i})=jsondecode(par{1}.Text);
                else
                    warning(['Property ' fileprops{i} ' cannot be set! Property is not defined in object of type ' class(obj)]);
                end
            end
            obj.deSerializationDone(docNode);
        end
    end
end

