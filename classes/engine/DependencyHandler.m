classdef DependencyHandler < handle
    %DependencyHandler - Sharing Dependencies like external folders or
    %files
    %   The DependencyHandler allows to share assets like paths between
    %   Components or views. These dependencies can be configured in the
    %   GUI.
    %   The Dependencyhandler also contains the Temp folder which will be
    %   automatically cleaned up at the end of a project. 
    %   At the moment the Dependency handles three different dependency
    %   types which will decided how they can be altered in the GUI.
    %   The internal dependency type is not visualized in the GUI, it is reserved for things like the Temp folder location.
    %   The DependencyHandler should not be used to pass informations from
    %   one Component to another
    %   Content of the Dependency handler will be kept across Projects
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
            % Instance - Receive the Dependency handler Singleton
            persistent instance;
            if(isempty(instance))
                instance=DependencyHandler();
            end
            
            obj=instance;
            
        end
        
        function Purge()
            % Purge - Clean all dependencies
            dep=DependencyHandler.Instance();
            dep.RequestLibrary=containers.Map();
            dep.ResolvedLibrary=containers.Map();
            dep.postRequest([],[]);
  
        end
        

    end
    
    methods
        
        
        function PostDepencenyRequest(obj,name,type)
            % PostDependencyRequest - This will add a dependency without
            % having a value for it. Use this if you want to add an entry
            % to the Settings GUI
            validated=validatestring(type,DependencyHandler.DependencyTypes);
            obj.RequestLibrary(name)=validated;
            obj.postRequest(name,type);
        end
        
        function b=IsDependency(obj, name)
            %IsDependency - Checks if a dependency exists and is resolved
            b=false;
            if(obj.ResolvedLibrary.isKey(name))
                b=true;
            end
        end
        
        function dependency=GetDependency(obj, name)
            % GetDependency - Returns the value of a resolved Dependency
            % will return an error if the dependency is not resolved
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
            % SetDependency - Resolve a Dependency
            validated=validatestring(name,keys(obj.RequestLibrary));
            obj.ResolvedLibrary(validated)=resolvedDep;
        end

        function CreateAndSetDependency(obj,name,resolvedDep,type)
            %Create a new dependency and set it at the same time
            validated_t=validatestring(type,DependencyHandler.DependencyTypes);
            obj.RequestLibrary(name)=validated_t;
            obj.ResolvedLibrary(name)=resolvedDep;
        end
        
        function type= GetDependencyType(obj,name)
            % Returns the dependenct type
            type=obj.RequestLibrary(name);
        end
        
        function RegisterDependencyChange(obj,depO,func)
            % RegisterDependencyChange - register the function of an object
            % to be called when Dependencies change
            if(~any(cellfun(@(x) (x == depO),obj.DependencyRequestObj,'UniformOutput',true)))
                obj.DependencyRequestObj{end+1}=depO;
                obj.DependencyRequestFcn{end+1}=func;
            end
        end
        
        function UnRegisterDependencyChange(obj,depO)
            % UnRegisterDependencyChange - Removes an object from the
            % notifications. Object will no longer be notified if a
            % Dependency changes.
            pos=find((cellfun(@(x) (x == depO),obj.DependencyRequestObj,'UniformOutput',true)));
            obj.DependencyRequestObj(pos)=[];
            obj.DependencyRequestFcn(pos)=[];
        end
        
        function LoadDependencyFile(obj,path)
            % LoadDependencyFile - load the serialized dependency file
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
            % SaveDependencyFile serialize the dependencies
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
            %Call all subscribed functions aster a Dependency has changed
           if(~isempty(obj.DependencyRequestFcn))
                for i=1:length(obj.DependencyRequestFcn)
                    func=obj.DependencyRequestFcn{i};
                    func(name,type);
                end
           end
        end
    end
    
    
        
        
        
        

end

