classdef XfrmLoader < AComponent
    %XfrmLoader - Component loads data from a file with a file selector
    % Allows loading a transformation matrix as a text file

    properties
        TIdentifier char       % Data identifier
        FileTypeWildcard char % Wildcard definition for File Loader
        InputFilepath char
    end

    methods
        function obj = XfrmLoader()
            %FileLoader - Constructor
            obj.TIdentifier      = 'T';
            obj.FileTypeWildcard = '*.*';
            obj.InputFilepath    = '';
        end
        function Publish(obj)
            % Publish - Define Output for Component
            % See also AComponent.Publish
            obj.AddOutput(obj.TIdentifier,'TransformationMatrix');

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
                    [file,path] = uigetfile(obj.FileTypeWildcard,['Please select ' obj.TIdentifier]);
                end
            else
                [file,path] = uigetfile(obj.FileTypeWildcard,['Please select ' obj.TIdentifier]);
            end

            if isequal(file,0)
                error([obj.TIdentifier ' selection aborted']);
            else
                out   = obj.CreateOutput(obj.TIdentifier);

                [~, filename, ext] = fileparts(file);
                if strcmp(ext,'.txt')
                    T = load(fullfile(path,file));
                elseif strcmp(ext,'.mat')
                    strctT = load(fullfile(path,file));
                    fields = fieldnames(strctT);

                    T = strctT.(fields{1});
                else
                    error([obj.TIdentifier ' selection aborted. Unknown file type']);
                end
                out.T = T;
            end

        end
    end
end

