classdef FileLoader < AComponent
    %INPUTCOMPONENT Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        Identifier char
        IdentifierType char
        FileTypeWildcard char
    end
    
    methods
        function obj = FileLoader()
            obj.Identifier='';
            obj.IdentifierType='';
            obj.FileTypeWildcard='*.*';
        end
        function Publish(obj)
            obj.AddOutput(obj.Identifier,obj.IdentifierType);
            obj.Name=[obj.Identifier 'Loader'];
        end
        function Initialize(obj)
            if(isempty(obj.Identifier))
                error('No Identifier Tag specified');
            end
            if(isempty(obj.IdentifierType))
                error('No Type specified');
            end
            if(~isObjectTypeOf(obj.IdentifierType,'IFileLoader'))
                error(['Invalid IdentifierType; ' obj.IdentifierType ' has to implement IFileLoader']);
            end
        end
        
        function [out] = Process(obj)
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

