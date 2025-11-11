function checkDocker(image)
% Function to check docker installation [and docker image].
% If docker is installed, the specified image will be pulled.

arguments
    image {mustBeTextScalar} = ''
end

% First check docker installation
dockerPath = findBinPath('docker');
if isempty(dockerPath)
    if ismac
        % /usr/local/bin might not be in the system path env on macOS
        errorMsg = sprintf(['Docker not found!\nIf it''s already installed, ', ...
            'please run the line below in your terminal (NOT MATLAB Command Window!) and reboot:\n', ...
            'sudo launchctl config user path /usr/bin:/bin:/usr/sbin:/sbin:/usr/local/bin']);
        error(errorMsg);
    else
        errorMsg = 'Docker not found!';
        error(errorMsg);
    end
else
    fprintf('Docker found: %sdocker\n', [dockerPath, filesep]);
end

% Check docker image
if ~isempty(image)
    [~, id] = system(['docker images -q ' image]);
    if ~isempty(id)
        fprintf('docker image found: %s\n', image);
    end
    fprintf('\nPulling docker image...\n'); % Always pull to update local image
    system(['docker pull ' image]);
end
