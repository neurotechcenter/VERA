classdef FileLoader < AComponent
    %FileLoader - Component loads data from a file with a file selector
    %Generic component that allows to select a file which will than be
    %passed to the AData object that implements IFileLoader
    %See also AData, IFileLoader
    
    properties
        Identifier char % Data identifier
        IdentifierType char % Data type, See also AData
        FileTypeWildcard char % Wildcard definition for File Loader
    end
    
    methods
        function obj = FileLoader()
            %FileLoader - Constructor
            obj.Identifier='';
            obj.IdentifierType='';
            obj.FileTypeWildcard='*.*';
        end
        function Publish(obj)
            % Publish - Define Output for Component
            % See also AComponent.Publish
            if(isempty(obj.Identifier))
                error('No Identifier Tag specified');
            end
            if(isempty(obj.IdentifierType))
                error('No Type specified');
            end
            if(~isObjectTypeOf(obj.IdentifierType,'IFileLoader'))
                error(['Invalid IdentifierType; ' obj.IdentifierType ' has to implement IFileLoader']);
            end
            obj.AddOutput(obj.Identifier,obj.IdentifierType);
            obj.Name=[obj.Identifier 'Loader'];
        end
        function Initialize(obj)
            % Initialize
            % See also AComponent.Initialize

        end
        
        function [out] = Process(obj)
            % Process - opens file selector GUI and passes the file or
            % folder to the Data object
            % See also AComponent.Process, IFileLoader
             [file,path]=uigetfile(obj.FileTypeWildcard,['Please select ' obj.Identifier]);
             if isequal(file,0)
                 error([obj.Identifier ' selection aborted']);
             else
                 out=obj.CreateOutput(obj.Identifier);
                 out.LoadFromFile(fullfile(path,file));
             end
        end
    end
end

