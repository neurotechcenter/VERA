classdef Copy < AComponent

    
    properties
        CopyFromIdentifier char % Data identifier
        CopyToIdentifier char % Data identifier
        IdentifierType char % Data type, See also AData
    end
    
    methods
        function obj = Copy()
            %FileLoader - Constructor
            obj.CopyFromIdentifier='';
            obj.CopyToIdentifier='';
            obj.IdentifierType='';
        end
        function Publish(obj)
            % Publish - Define Output for Component
            % See also AComponent.Publish
            if(isempty(obj.CopyFromIdentifier))
                error('No Copy Target (CopyFromIdentifier) specified');
            end
            if(isempty(obj.CopyToIdentifier))
                error('No output name (CopyToIdentifier) specified');
            end
            if(isempty(obj.IdentifierType))
                error('Datatype (IdentifierType) not specified');
            end
            obj.AddInput(obj.CopyFromIdentifier,obj.IdentifierType);
            obj.AddOutput(obj.CopyToIdentifier,obj.IdentifierType);

        end
        function Initialize(obj)
            % Initialize
            % See also AComponent.Initialize

        end
        
        function [out] = Process(obj,in)
            out=obj.CreateOutput(obj.CopyToIdentifier);
            m=metaclass(in);
            p={m.PropertyList.Name};
            for i=1:numel(m.PropertyList) %remove all items which do not have public set/get accessors and are not in the acStorage list
             if((iscell(m.PropertyList(i).GetAccess) ||...
                iscell(m.PropertyList(i).SetAccess)||...
                ~strcmp(m.PropertyList(i).GetAccess,'public') ||...
                ~strcmp(m.PropertyList(i).SetAccess,'public')) || strcmp(m.PropertyList(i).Name,'Name'))

             else
                 out.(m.PropertyList(i).Name)=in.(m.PropertyList(i).Name);
             end
            end
        end
    end
end

