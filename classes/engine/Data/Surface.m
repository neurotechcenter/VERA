classdef Surface < AData & IFileLoader
    %Surface - Data to store Surface 
    % Data structure for surfaces
    % Surfaces will bit stored in the gifti format (https://www.nitrc.org/projects/gifti/)
    % Additional information like annotations will be stored in an xml
    % See also gifti
    
    properties
        Model % 3D Surface Model, a struct containing vert and tri  
        Path %Path to the gifti file
        Annotation %Annotation for each vertex
        AnnotationLabel 
    end
    
    properties (Dependent)
        TriId %Identification of hemisphere 
        VertId %Identification of hemisphere 
    end
    
    methods
        function obj = Surface()
            obj.ignoreList{end+1}='Model';
            obj.ignoreList{end+1}='Annotation';

        end

        function LoadFromFile(obj,path)
                buffG=gifti(path);
                obj.Model.vert=double(buffG.vertices);
                obj.Model.tri=buffG.faces;
                if(isfield(buffG,'cdata'))
                    obj.Annotation=buffG.cdata;
                else
                    obj.Annotation=zeros(size(obj.Model.vert,1),1);

                end
        end
        function Load(obj,path)
            % Load - override of load for Surface
            % The surface will be stored as a gifti accompanied by an xml
            % containing hemisphere and annotation information
            % See also AData, gifti
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
            %Save - override of Save for Surface
            %Surface will be loaded from the gifti file together with the
            %information contained in the xml
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

        function surfaceOut=GetSubSurfaceById(obj,id,searchComplex)
            surfaceOut=copy(obj);
            surfaceOut.Path='';
            surfaceOut.Model.vert=surfaceOut.Model.vert(surfaceOut.VertId == id,:);
            CCold=find(surfaceOut.VertId == id);
            CCnew=1:size(CCold,1);


            newtri=surfaceOut.Model.tri(surfaceOut.TriId == id,:);
            if(searchComplex)
                surfaceOut.Model.tri=newtri;
               
                to_replace=unique(newtri);
                for i=1:size(to_replace,1)
                    surfaceOut.Model.tri(to_replace(i) == surfaceOut.Model.tri)=CCnew(CCold == to_replace(i));
                end
            else
                newtri=newtri-(min(newtri(:))-1);
                surfaceOut.Model.tri=newtri;
            end
           % indices = ismember(to_replace, CCold);

            surfaceOut.Annotation=surfaceOut.Annotation(surfaceOut.VertId == id);
            surfaceOut.VertId=surfaceOut.VertId(surfaceOut.VertId == id);
            surfaceOut.TriId=surfaceOut.TriId(surfaceOut.TriId == id);
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