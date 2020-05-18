classdef ObjectFactory
    %AFACTORY Summary of this class goes here
    %   Detailed explanation goes here
    
    
    methods(Access = private)
        function obj = ObjectFactory(~)
        end
    end
    
    methods (Static)

        function vobj = CreateView(cname, xmlNode)
            cI=meta.class.fromName(cname);
            if(~isempty(cI) && any(strcmp(superclasses(cname),'AView')) && cI.Abstract == 0)
                vobj=feval(cname);
                if(isObjectTypeOf(vobj,'IComponentView'))
                  if(isfield(xmlNode.Attributes,'Component'))
                        vobj.Component=xmlNode.Attributes.Component;
                  else
                        error('View is a ComponentView, it requires a Component attribute!');
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

