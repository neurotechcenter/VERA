classdef Project < handle
    %PROJECT Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (SetAccess = protected, GetAccess = public)
        Pipeline Pipeline
        Path char
        ProjectName char
    end
    
    methods
        
        function savePath=SaveComponent(obj,compName)
                foldern=obj.GetComponentPath(compName);
                cobj=obj.Pipeline.GetComponent(compName);
                savePath=fullfile(obj.Path,foldern,'componentInformation.xml');
                docNode = com.mathworks.xml.XMLUtils.createDocument('ComponentInformation');
                c=cobj.Serialize(docNode);
                doc = docNode.getDocumentElement;
                doc.appendChild(c);
                xmlwrite(savePath,docNode);
        end
        
        function res=ComponentDataAvailable(obj,compName)
            [~,results]=obj.Pipeline.InterfaceInformation(compName);
            foldern=obj.GetComponentPath(compName);
            loadPath=fullfile(obj.Path,foldern,'Data');
            res=true;
            for k=results
                res =res & (exist(fullfile(loadPath,[k{1} '.xml']),'file') ~= 0);
            end
        end
        
        function [data,path]=LoadComponentData(obj,compName,results)
            if(~exist('results','var'))
                [~,results]=obj.Pipeline.InterfaceInformation(compName);
            end
            foldern=obj.GetComponentPath(compName);
            loadPath=fullfile(obj.Path,foldern,'Data');
            path=loadPath;
            data=containers.Map();
            for k=results
                data(k{1})=ObjectFactory.CreateData([],fullfile(loadPath,[k{1} '.xml']));
            end
            
            
        end
        function foldern=GetComponentPath(obj,compName) %componentpaths are relative
            obj.checkCompName(compName);
            cobj=obj.Pipeline.GetComponent(compName);
            foldern=regexprep(cobj.Name, ' +', '_');
        end
        
        
        function paths=SaveComponentData(obj,compName,varargin)
            foldern=obj.GetComponentPath(compName);
            cobj=obj.Pipeline.GetComponent(compName);
            savePath=fullfile(obj.Path,foldern,'Data');
            %check if componentData matches components
            outp=cobj.Outputs;
            if(numel(varargin) ~= numel(outp))
                error(['Number of Data objects supplied is not equal to expected Outputs from Component ' compName]);
            end
            paths=containers.Map;
            i=1;
            for k=outp% check if components match (name + type)
                res=strcmp(cellfun(@(x) x.Name,varargin','UniformOutput',false),k{1});
                if(~any(res))
                    error('Supplied Data does not fit expected component output');
                end
                dobj=varargin{res};
                if(strcmp(cobj.GetOutputType(k{1}),class(dobj))) %check if type is as expected
                    paths(k{1})=dobj.Save(savePath);
                    
                else
                    error([k{1} ' was expected to be of type ' outp(k{1}) ' but input type was ' class(dobj)]);
                end
                i=i+1;
            end
        end
    end
    
    methods (Access = protected)
        function obj = Project()
            obj.Pipeline = [];
            obj.Path = '';
        end
        
        function createProjectFolderStructure(obj)
            warning('off', 'MATLAB:MKDIR:DirectoryExists'); % turn of warning that dir already exists
            for k=obj.Pipeline.Components
                
                foldern=obj.GetComponentPath(k{1});
                cobj=obj.Pipeline.GetComponent(k{1});
                mkdir(fullfile(obj.Path,foldern)); %create a folder for each component
                mkdir(fullfile(obj.Path,foldern,'Data')); %each folder contains the Output Data produced
                cobj.ComponentPath=fullfile(obj.Path,foldern);
            end
            obj.Path
            warning('on', 'MATLAB:MKDIR:DirectoryExists');
        end
        
        function checkCompName(obj,name)
            if(~any(strcmp(obj.Pipeline.Components,name)))
                error([name 'is not a valid Component in this Pipeline']);
            end
        end
    end
    
    methods (Static)
        function prj=CreateProjectOnPath(projPath,pipelinePath)
            [esc,projName] = fileparts(projPath);
            
            if(isempty(projName))
                [~,projName] = fileparts(esc);
                if(isempty(projName))
                    error('Couldnt determine Project Name');
                end
            end
            ppline=Pipeline.CreateFromPipelineDefinition(pipelinePath);
            prj=Project();
            prj.Path=projPath;
            prj.ProjectName=projName;
            prj.Pipeline=ppline;
            prj.createProjectFolderStructure();
            
        end
        
        function [prj,pplineFile]=OpenProjectFromPath(projPath)
            pplineFile=fullfile(projPath,'pipeline.pwf');
            [esc,projName] = fileparts(projPath);
            ppline=Pipeline.CreateFromPipelineDefinition(pplineFile);
            prj=Project();
            prj.Path=projPath;
            prj.ProjectName=projName;
            prj.Pipeline=ppline;
            prj.createProjectFolderStructure();
            for c=ppline.Components
                cobj=ppline.GetComponent(c{1});
                cpath=prj.GetComponentPath(c{1});
                cpath=fullfile(projPath,cpath,'componentInformation.xml');
                if(exist(cpath,'file'))
                    xmlstrct=xml2struct(cpath);
                    if(isfield(xmlstrct,'ComponentInformation') && ...
                        numel(xmlstrct.ComponentInformation{1}) ==1 && ...
                        isfield(xmlstrct.ComponentInformation{1},'Component'))

                        cobj.Deserialize(xmlstrct.ComponentInformation{1}.Component{1});
                    end
                end
            end

            
            end
        end
      
        
   
    
end

