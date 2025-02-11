classdef FileLoader < AComponent
    %FileLoader - Component loads data from a file with a file selector
    % Generic component that allows to select a file which will than be
    %passed to the AData object that implements IFileLoader
    % See also AData, IFileLoader

    properties
        Identifier char       % Data identifier
        IdentifierType char   % Data type, See also AData
        FileTypeWildcard char % Wildcard definition for File Loader
        InputFilepath char
    end

    methods
        function obj = FileLoader()
            %FileLoader - Constructor
            obj.Identifier       = 'MRI';
            obj.IdentifierType   = 'Volume';
            obj.FileTypeWildcard = '*.*';
            obj.InputFilepath    = '';
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

            % if strcmp(obj.Name,'FileLoader')
            %     obj.Name=[obj.Identifier 'Loader'];
            % end
        end
        function Initialize(obj)
            % Initialize
            % See also AComponent.Initialize

        end

        function [out] = Process(obj)
            % Process - opens file selector GUI and passes the file or
            % folder to the Data object
            % See also AComponent.Process, IFileLoader
            if ~isempty(obj.InputFilepath)

                % working directory is VERA project
                if isAbsolutePath(obj.InputFilepath)
                    [path,file,ext] = fileparts(obj.InputFilepath);
                else
                    [path,file,ext] = fileparts(fullfile(obj.ComponentPath,'..',obj.InputFilepath));
                    path = GetFullPath(path);
                end

                file = [file,ext];

                % Open a file load dialog if you can't find the path
                if ~exist(fullfile(path,file),'file')
                    [file,path] = uigetfile(obj.FileTypeWildcard,['Please select ' obj.Identifier]);
                end
            else
                [file,path] = uigetfile(obj.FileTypeWildcard,['Please select ' obj.Identifier]);
            end

            if isequal(file,0)
                error([obj.Identifier ' selection aborted']);
            else
                out=obj.CreateOutput(obj.Identifier);
                out.LoadFromFile(fullfile(path,file));
            end

        end
    end
end

