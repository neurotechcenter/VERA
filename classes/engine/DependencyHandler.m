classdef DependencyHandler < handle
    %DEPENDENCYHANDLER Summary of this class goes here
    %   Detailed explanation goes here
    properties (Constant, Access = private)
        DependencyTypes = {'file','folder','internal'}
    end
    properties
        RequestLibrary = containers.Map();
        ResolvedLibrary = containers.Map();
    end
    
    properties(Access = private)
        DependencyRequestFcn={};
        DependencyRequestObj={};
    end
    
    methods (Access = private)
        function obj = DependencyHandler()
            %DEPENDENCYHANDLER Construct an instance of this class
            %   Detailed explanation goes here
            
                obj.RequestLibrary = containers.Map();
                obj.ResolvedLibrary = containers.Map();
                obj.DependencyRequestFcn={};
                obj.DependencyRequestObj={};
        end
    end
    
    methods (Static, Access = public)
        
        function obj = Instance()
            persistent instance;
            if(isempty(instance))
                instance=DependencyHandler();
            end
            
            obj=instance;
            
        end
        
        function Purge()

            dep=DependencyHandler.Instance();
            dep.RequestLibrary=containers.Map();
            dep.ResolvedLibrary=containers.Map();
            dep.postRequest([],[]);
  
        end
        

    end
    
    methods
        
        
        function PostDepencenyRequest(obj,name,type)
            validated=validatestring(type,DependencyHandler.DependencyTypes);
            obj.RequestLibrary(name)=validated;
            obj.postRequest(name,type);
        end
        
        function b=IsDependency(obj, name)
            b=false;
            if(obj.ResolvedLibrary.isKey(name))
                b=true;
            end
        end
        
        function dependency=GetDependency(obj, name)
            if(obj.ResolvedLibrary.isKey(name))
                dependency=obj.ResolvedLibrary(name);
            else
                error(['Dependency ' name ' is not set!']);
            end
        end
        
        function RemoveDependency(obj,name)
            remove(obj.ResolvedLibrary,name);
        end
        
       
        

        function SetDependency(obj,name,resolvedDep)
            %% test if resolving variable fits type
            validated=validatestring(name,keys(obj.RequestLibrary));
            obj.ResolvedLibrary(validated)=resolvedDep;
        end

        function CreateAndSetDependency(obj,name,resolvedDep,type)
            %%
            validated_t=validatestring(type,DependencyHandler.DependencyTypes);
            obj.RequestLibrary(name)=validated_t;
            obj.ResolvedLibrary(name)=resolvedDep;
        end
        
        
        
        function RegisterDependencyChange(obj,depO,func)
            if(~any(cellfun(@(x) (x == depO),obj.DependencyRequestObj,'UniformOutput',true)))
                obj.DependencyRequestObj{end+1}=depO;
                obj.DependencyRequestFcn{end+1}=func;
            end
        end
        
        function UnRegisterDependencyChange(obj,depO)
            pos=find((cellfun(@(x) (x == depO),obj.DependencyRequestObj,'UniformOutput',true)));
            obj.DependencyRequestObj(pos)=[];
            obj.DependencyRequestFcn(pos)=[];
        end
        
        function LoadDependencyFile(obj,path)
            
            doc=xml2struct(path);
            if(~isfield(doc.Dependencies{1},'Dependency'))
                return;
            end
            deps=doc.Dependencies{1}.Dependency;
            for i=1:length(deps)
                name=deps{i}.Attributes.Name;
                type=deps{i}.Attributes.Type;
                obj.PostDepencenyRequest(name,type);
                if(~isempty(deps{i}.Text))
                    obj.SetDependency(name,jsondecode(deps{i}.Text));
                end
            end
        end
        
        function SaveDependencyFile(obj,path)
            docNode = com.mathworks.xml.XMLUtils.createDocument('Dependencies');
            doc = docNode.getDocumentElement;
            %<Dependencies>
            %<Dependency name='aaa' type='path'>
            %\Test\bla\bla
            %</Dependency>
            %</Dependencies>
            %
           
            deps=keys(obj.RequestLibrary);
            for i=1:length(deps)
                type=obj.RequestLibrary(deps{i});
                if(strcmp(type,'internal')) % do not serialize interal components
                    continue;
                end
                    
                c=docNode.createElement('Dependency');
                c.setAttribute('Name',deps{i})
                
                c.setAttribute('Type',type);
                if(any(strcmp(keys(obj.ResolvedLibrary),deps{i})))
                    c.appendChild(docNode.createTextNode(jsonencode(obj.ResolvedLibrary(deps{i}))));
                end
                doc.appendChild(c);
            end
            xmlwrite(path,docNode);
        end
        
    end
    
    methods (Access = private)
        
        function postRequest(obj,name,type)
           if(~isempty(obj.DependencyRequestFcn))
                for i=1:length(obj.DependencyRequestFcn)
                    func=obj.DependencyRequestFcn{i};
                    func(name,type);
                end
           end
        end
    end
    
    
        
        
        
        

end

