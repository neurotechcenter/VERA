classdef AData < Serializable
    %ASOURCE Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        Name
    end
    
    methods
        function obj = AData()
            obj.nodeName='Data';
        end
        
        function Load(obj,path)
            %xmlPath=obj.buildXmlPath(path);
            xmlstrct=xml2struct(path);
            if(isfield(xmlstrct,'DataInformation'))
                obj.Deserialize(xmlstrct.DataInformation{1}.(obj.nodeName){1});
            else
                error('Data could not be loaded from malformed xml');
            end
            
        end
         
        function xmlPath=Save(obj,path)
            xmlPath=obj.buildXmlPath(path);
            docNode = com.mathworks.xml.XMLUtils.createDocument('DataInformation');
            c=obj.Serialize(docNode);
            doc = docNode.getDocumentElement;
            doc.appendChild(c);
            xmlwrite(xmlPath,docNode);
        end
    end
    
    methods(Access = protected)
        function path=buildXmlPath(obj,path)
                path=fullfile(path,[obj.Name '.xml']);
        end
        
        function d=GetDependency(~,name)
            d=DependencyHandler.Instance.GetDependency(name);
        end
        
        function b=IsDependency(~,name)
            b=DependencyHandler.Instance.IsDependency(name);
        end
        
        function pathOut=makeRelativePath(obj,pathIn,isFile)
            if(isFile)
                [a,b,c]=fileparts(pathIn);
            else
                a=pathIn;
            end
            if(obj.IsDependency('ProjectPath'))
                pathOut=relativepath(a,obj.GetDependency('ProjectPath'));
            else
                pathOut=relativepath(a);
            end
            if(isFile)
                pathOut=fullfile(pathOut,[b c]);
            end
        end
        
        function pathout=makeFullPath(obj,pathIn)
            if(~startsWith(strtrim(pathIn),{'..\','.\'})) %path is already absolute
                pathout=pathIn;
                return;
            end
            if(obj.IsDependency('ProjectPath'))
                pathout=fullfile(obj.GetDependency('ProjectPath'),pathIn);
            else
                pathout=fullfile(cd,pathIn);
            end
        end
            
    end
    
end

