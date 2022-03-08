classdef ObjectFactory
    %ObjectFactory - Creates new object and initializes them correctly
    %   ObjectFactory is used to Create Components, Views and Data based on
    %   information contained in XML format
    %   See also Serializer
    
    methods(Access = private)
        function obj = ObjectFactory(~)
        end
    end
    
    methods (Static)

        function vobj = CreateView(cname, xmlNode)
            %CreateView - Creates a View object from string
            %cname - Name of the View object
            %xmlNode - xml definition for data
            %See also AView, IComponentView
            cI=meta.class.fromName(cname);
            if(~isempty(cI) && any(strcmp(superclasses(cname),'AView')) && cI.Abstract == 0)
                vobj=feval(cname);
                if(isObjectTypeOf(vobj,'IComponentView'))
                  if(isfield(xmlNode.Attributes,'Component'))
                        vobj.Component=xmlNode.Attributes.Component;
                  end
                end
                if(nargin > 1 && ~isempty(xmlNode)) %deserialize
                    vobj.Deserialize(xmlNode);
                end
            else
                error(['Component ' cname ' doesnt exist']);
            end
        end
        
        function vobj = CreateComponent(cname,xmlNode)
            %CreateData - Creates a Component object from string
            %cname - Name of the Component object
            %xmlNode - xml definition for Component
            %See also AComponent
            cI=meta.class.fromName(cname);
            if(~isempty(cI) && any(strcmp(superclasses(cname),'AComponent')) && cI.Abstract == 0)
                vobj=feval(cname);
                if(nargin > 1 && ~isempty(xmlNode)) %deserialize
                    vobj.Deserialize(xmlNode);
                end
                
            else
                error(['Component ' cname ' doesnt exist']);
            end
        end
        
        function c = CreateData(cname,path)
            %CreateData - Creates a Data object from string
            %cname - Name of the Data object
            %path - Path to xml definition for data
            %If cname is empty, the xml definition provided by path will be
            %used to create the Data object
            %See also AData
            if(isempty(cname) && ~isempty(path))
                xstr=xml2struct(path);
                if(isfield(xstr,'DataInformation') && ...
                   isfield(xstr.DataInformation{1},'Data') && ...
                   isfield(xstr.DataInformation{1}.Data{1},'Attributes') && ...
                   isfield(xstr.DataInformation{1}.Data{1}.Attributes,'Type'))
                    cname=xstr.DataInformation{1}.Data{1}.Attributes.Type;
                else
                    error(['Malformed xml ' path]);
                end
            elseif(isempty(cname))
                error('Cannot create Data object without class type or serialization path');
            end
            if(isObjectTypeOf(cname,'AData'))
                c=feval(cname);
            else
                error('Data Object has to be of type AData');
            end
            if(nargin > 1 && ~isempty(path))
                c.Load(path);
            end
        end
    end
end

