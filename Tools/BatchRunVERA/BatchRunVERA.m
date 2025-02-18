% BatchRunVERA is a script to run multiple VERA projects sequentially. See
% the readme for more information

%% Basic setup
clear
close all;
clc;

% Set up VERA path
mfilePath    = fileparts(mfilename('fullpath'));
VERArootpath = (fullfile(mfilePath,'..','..'));

% Change to the VERA root path. This assumes this script is still located
% in VERA/Tools/BatchRunVERA
cd(VERArootpath);

%% Start VERA
% Setting visibility 'off' runs slightly faster
VERAVisibility = 'on';

% Start VERA first because it clears all variables
guihandle = startup_VERA(VERAVisibility);

%% Subjects to run
projectFolderDir = '/path/to/VERA/Project/Folders';

% With a little ingenuity these can be generated programmatically
projectFolders{1} = 'VERA_Subject01';
projectFolders{2} = 'VERA_Subject02';
projectFolders{3} = 'VERA_Subject03';

% Generate list of VERA project directories to run
for i = 1:length(projectFolders)
    projectFolders_Fullpath{i} = fullfile(projectFolderDir, projectFolders{i});
end

%% Run through projects
for i = 1:length(projectFolders_Fullpath)
    fprintf(['Running project: ', projectFolders{i},'\n'])

    % Open project in VERA
	openProject(guihandle,[],[],projectFolders_Fullpath{i});

    % Run all components
	runAll(guihandle);
end