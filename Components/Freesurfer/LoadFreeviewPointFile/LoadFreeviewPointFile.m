classdef LoadFreeviewPointFile < AComponent
    %LOADFREEVIEWPOINTFILE Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        ElectrodeLocationIdentifier
        ElectrodeDefinitionIdentifier
        LocationDefinitionDataType
        LocationDataType
    end
    
    methods
        function obj = LoadFreeviewPointFile()
            obj.ElectrodeLocationIdentifier='ElectrodeLocation';
            obj.LocationDataType='ElectrodeLocation';
            
            obj.ElectrodeDefinitionIdentifier='ElectrodeDefinition';
            obj.LocationDefinitionDataType='ElectrodeDefinition';
        end
        
        function Publish(obj)
            obj.AddOptionalInput(obj.ElectrodeDefinitionIdentifier,obj.LocationDefinitionDataType);
            obj.AddOutput(obj.ElectrodeLocationIdentifier,obj.LocationDataType);
        end
        
        function Initialize(obj)
            if(any(strcmp(superclasses(obj.LocationDefinitionDataType),'ElectrodeDefinition')) || ~strcmp(obj.LocationDefinitionDataType,'ElectrodeDefinition'))
                error('LocationDefinitionDataType has to be a subtype of ElectrodeDefinition');
            end
            if(any(strcmp(superclasses(obj.LocationDefinitionDataType),'ElectrodeLocation'))|| ~strcmp(obj.LocationDataType,'ElectrodeLocation'))
                error('LocationIdentifierDataType has to be a subtype of ElectrodeLocation');
            end
        end
        
        function elData=Process(obj,varargin)
            elDef=[];
            elData=obj.CreateOutput(obj.ElectrodeLocationIdentifier);
            if(length(varargin) > 1 && strcmp(varargin{1},obj.ElectrodeDefinitionIdentifier))
                elDef=varargin{2};
            end
            [files,path]=uigetfile('*.dat','Select Data Files','','MultiSelect','on');
            if(~iscell(files))
                files={files};
            end
            for i_f=1:length(files)
                %check if name corresponds to any electrode definitions if
                %they are available
                identifier=i_f;
                el=importelectrodes(fullfile(path,files{i_f}));
                if(~isempty(elDef))
                    identifier=find(strcmp(elDef.Definition.Name,files{i_f}),1);
                end
                elData.Location=[elData.Location; el];
                elData.DefinitionIdentifier=[elData.DefinitionIdentifier; identifier*ones(length(el),1)];
            end
            
            
        end
    end
end

