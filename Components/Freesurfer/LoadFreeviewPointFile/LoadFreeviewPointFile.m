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
            if(~any(strcmp(superclasses(obj.LocationDataType),'PointSet')))
                error('LocationDataType has to be a subtype of PointSet');
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
                    elDefNames = {elDef.Definition.Name};
                    identifier=find(strcmp(files{i_f}(1:end-4),elDefNames),1);
                end
                if(~isempty(identifier))
                    elData.AddWithIdentifier(identifier,el);
                else
                    [idx,tf]=listdlg('PromptString','Select Corresponding Definition','SelectionMode','single','ListString',{avail_pipelFiles.name});
                    if(~isempty(idx))
                        if(any(elData.DefinitionIdentifier == idx))
                            answ=questdlg('Do you want to override the existing electrode Locations?','Override?','yes','no');
                            if(strcmp(answ,'no'))
                                continue;
                            end
                            elData.RemoveWithIdentifier(idx);
                        end
                        elData.AddWithIdentifier(idx,el);
                    end
                end
            end
            
            
        end
    end
end

