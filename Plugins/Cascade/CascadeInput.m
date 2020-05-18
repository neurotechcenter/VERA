classdef CascadeInput < AComponent
    %CASCADEINPUT Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        OutputIdentifiers
        OutputIdentifierTypes
    end
    
    methods
        function obj = CascadeInput()
            obj.OutputIdentifiers={'Surface','ElectrodeDefinition','ElectrodeLocation'};
            obj.OutputIdentifierTypes={'Surface','ElectrodeDefinition','ElectrodeLocation'};
        end
        
        function Publish(obj)
            if(length(obj.OutputIdentifiers) ~= length(obj.OutputIdentifierTypes))
                error('Identifiers and IdentifierTypes must be of the same length')
            end
            for iO=1:length(obj.InputIdentifiers)
                obj.AddOutput(obj.OutputIdentifiers{iO},obj.OutputIdentifierTypes{iO});
            end
        end
        
        function Initialize(obj)
        end
        
        function varargout=Process(obj)
            path=uigetdir([],'Please select VERA Project');
            prj=Project.OpenProjectFromPath(path);
            runner=Runner.CreateFromProject(prj);
            varargout=cell(1,length(obj.InputIdentifier));
            for iO=1:length(obj.InputIdentifier)
                if(runner.CurrentPipelineData.isKey(obj.InputIdentifier{iO}) && ...
                        isObjectTypeOf(runner.CurrentPipelineData(obj.InputIdentifier{iO}),obj.OutputIdentifierTypes{iO}))
                     varargout{iO}=runner.CurrentPipelineData(obj.InputIdentifier{iO});
                else
                    error(['Selected project does not have the Required Input' obj.InputIdentifier{iO}]);
                end
            end
            
        end

    end
end

