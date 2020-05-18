classdef Surface < AData
    %SURFACE Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        Model
        Path
        Annotation
        AnnotationLabel
    end
    
    properties (Dependent)
        TriId
        VertId
    end
    
    methods
        function obj = Surface()
            obj.ignoreList{end+1}='Model';
            obj.ignoreList{end+1}='Annotation';

        end
        function Load(obj,path)
            Load@AData(obj,path);
            obj.Path=obj.makeFullPath(obj.Path);
            if(~isempty(obj.Path))
                buffG=gifti(obj.Path);
                obj.Model.vert=double(buffG.vertices);
                obj.Model.tri=buffG.faces;
                obj.Annotation=buffG.cdata;
            end
            
        end
        function savepath=Save(obj,path)
            if(~isempty(obj.Model))
                obj.Path=fullfile(path,[obj.Name '.surf.gii']);
                buffM.vert=obj.Model.vert;
                buffM.tri=obj.Model.tri;
                buffM.cdata=obj.Annotation;
                g=gifti(buffM);
                save(g,obj.Path,'Base64Binary');
            end
            buffPath=obj.Path;
           
            obj.Path=obj.makeRelativePath(buffPath,true); %create a relative path for storing
            savepath=Save@AData(obj,path);
            obj.Path=buffPath;
        end
        
         function value=get.TriId(obj)
             if(~isempty(obj.Model) && isfield(obj.Model,'triId'))
                value=obj.Model.triId;
             else
                 value=[];
             end
         end
        
         function set.TriId(obj,value)
             obj.Model.triId=value;
         end
         
         function value=get.VertId(obj)
             if(~isempty(obj.Model) && isfield(obj.Model,'vertId'))
                value=obj.Model.vertId;
             else
                 value=[];
             end
         end
        
         function set.VertId(obj,value)
             obj.Model.vertId=value;
         end
        
    end
    


end