classdef (Abstract)  AData < Serializable & matlab.mixin.Copyable
    %AData Abstract base class for data shared between Components
    %   Data is shared between Components via Data objects
    %   Data objects will be serialized as xml objects
    %   
    %See also Serializable
    properties
        Name %Identifier of the Data 
    end
    
    methods
        function obj = AData()
            % AData - Constructor
            obj.nodeName='Data';
        end
        
        function Load(obj,path)
            % Load - Load Data from path
            % path - Path to the serialization xml
            %See also Serializable
            xmlstrct=xml2struct(obj.normalizeSlashes(path));
            if(isfield(xmlstrct,'DataInformation'))
                obj.Deserialize(xmlstrct.DataInformation{1}.(obj.nodeName){1});
            else
                error('Data could not be loaded from malformed xml');
            end
            
        end
         
         
        function xmlPath=Save(obj,path)
            %Save - serialize and save to xml 
            % path - path to save to, file name is determined by Identifier
            %See also Serializable
            xmlPath=obj.buildXmlPath(obj.normalizeSlashes(path));
            docNode = com.mathworks.xml.XMLUtils.createDocument('DataInformation');
            c=obj.Serialize(docNode);
            doc = docNode.getDocumentElement;
            doc.appendChild(c);
            xmlwrite(xmlPath,docNode);
        end
    end
    
    methods(Access = protected)
        function path=buildXmlPath(obj,path)
            %buildXmlPath - creates a valid path to save with correct name
            %path - folder path
                path=fullfile(obj.normalizeSlashes(path),[obj.Name '.xml']);
        end
        
        
        function d=GetDependency(~,name)
            %GetDependency - Retrieve Dependency from Handler
            %name - name of Dependency 
            %See also DependencyHandler
            d=DependencyHandler.Instance.GetDependency(name);
        end
        
        function b=IsDependency(~,name)
            %IsDependency - Check if dependency exists
            %name - name of dependency
            %See also DependencyHandler
            b=DependencyHandler.Instance.IsDependency(name);
        end
        
        function pathOut=makeRelativePath(obj,pathIn,isFile)
            %makeRelativePath - converts full path to relative path
            %pathIn - absolute path
            %isFile - is the input a file or a path?
            %pathOut - Path relative to either ProjectPath (if dependency
            %is available) or relative to m file
            if(isFile)
                [a,b,c]=fileparts(obj.normalizeSlashes(pathIn));
            else
                a=obj.normalizeSlashes(pathIn);
            end
            if(obj.IsDependency('ProjectPath'))
                pathOut=relativepath(a,obj.normalizeSlashes(obj.GetDependency('ProjectPath')));
            else
                pathOut=relativepath(a);
            end
            if(isFile)
                pathOut=fullfile(pathOut,[b c]);
            end
            pathOut=obj.normalizeSlashes(pathOut);
        end
        
        function pathout=makeFullPath(obj,pathIn)
            %makeFullPath - convert relative path to full path
            %pathIn - relative path to be resolved
            %pathout - full path
            pathIn=obj.normalizeSlashes(pathIn);
            if(~startsWith(strtrim(pathIn),{'..\','.\','../','./'})) %path is already absolute
                pathout=pathIn;
                return;
            end
            if(obj.IsDependency('ProjectPath'))
                pathout=fullfile(obj.GetDependency('ProjectPath'),strrep(pathIn,'\','/'));
            else
                pathout=fullfile(cd,pathIn);
            end
        end

        function path=normalizeSlashes(~,path)
            path=strrep(path,'\','/');
        end
            
    end
    
end

