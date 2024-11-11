%% Startup, load brain.mat and add VERA to MATLAB path
clear;
close all;
clc;

% Add VERA to path
p = mfilename('fullpath');
FILEPATH = fileparts(p);
addpath(genpath(fullfile(FILEPATH,'..','..','classes')));
addpath(genpath(fullfile(FILEPATH,'..','..','Components')));
addpath(genpath(fullfile(FILEPATH,'..','..','dependencies')));
clear p FILEPATH


% Load output from VERA MatOutput component
[filename,filepath] = uigetfile('*.mat','Select brain.mat file to load','MultiSelect','off');
if filepath == 0
    fprintf('\nError: Please select at least one file.\n')
    return;
end

brainmat = load(fullfile(filepath,filename));

GenerateRotatingGif = 0;
modelOpacity = 0.1; % Range from 0 to 1

%% Create surface annotation colors
[surfRemap,surfcmap,surfNames,surfName_id] = createColormapFromAnnotations(brainmat.surfaceModel);

%% Create electrode annotation colors
for i = 1:length(brainmat.electrodes.Label)
    if isempty(brainmat.electrodes.Label{i})
        brainmat.electrodes.Label(i) = {{'no-label'}};
    end
end

electrodeLabels       = cellfun(@(x)x{1},brainmat.electrodes.Label,'UniformOutput',false);          % convert to easier to use cell array
uniqueElectrodeLabels = unique(electrodeLabels);
electrodeColors       = distinguishable_colors(length(uniqueElectrodeLabels));
electrodeRadius       = 0.75;

%% Plot implanted electrodes on brain model, using electrode labels
% Plot brain model using VERA function (uses trisurf)

fullcolorFig = figure('Position',[50 50 1200 900]);
modelPlot = plot3DModel(gca,brainmat.surfaceModel.Model,surfRemap);
colormap(surfcmap); % colorize with annotation for Surface
alpha(modelOpacity);
hold on;
% Plot electrodes colorized by brain area (annotation)
for i = 1:length(uniqueElectrodeLabels)
    % Find the electrodes that belong to each unique label and color them appropriately
    elecsToPlot = strcmp(uniqueElectrodeLabels{i},electrodeLabels);
    elecPlot = plotBallsOnVolume(gca,brainmat.electrodes.Location(elecsToPlot,:),electrodeColors(i,:),electrodeRadius);
end
% Plot electrode numbering
plotElNums(brainmat.electrodes.Location*1.075, 1:size(brainmat.electrodes.Location,1), 12);
view(-114,25)

% Modify colorbar to include more detailed labeling (surface labels on bottom, electrode labels on top)
cb                      = colorbar;
cb.Ticks                = [surfName_id; (surfName_id(end)+1:1:surfName_id(end)+length(uniqueElectrodeLabels))']+0.5;
cb.TickLabels           = [surfNames(:); uniqueElectrodeLabels(:)];
cb.TickLabelInterpreter = 'none';
clim([surfName_id(1) surfName_id(end)+length(uniqueElectrodeLabels)+1])

% Save full color figure
saveas(fullcolorFig,[filepath,filename(1:end-4),'.fig'])

%% Create Rotating Figure
if GenerateRotatingGif
    set(gcf,'color','w');
    set(gca,'CameraViewAngleMode','Manual')
    axis equal
    zoom(1.3)
    numFrames = 180;
    for i = 1:numFrames
        view(i/numFrames*360-114,25)
        drawnow
        frame = getframe(fullcolorFig);
        im{i} = frame2im(frame);
    end
    
    for i = 1:numFrames
        [A,map] = rgb2ind(im{i},256);
        if i == 1
            imwrite(A,map,[filepath,filename(1:end-4),'.gif'],"gif","LoopCount",Inf,"DelayTime",0.1);
        else
            imwrite(A,map,[filepath,filename(1:end-4),'.gif'],"gif","WriteMode","append","DelayTime",0.1);
        end
    end
    clear numFrames frame im A map
end

%% Plot implanted electrodes on brain model
% Plot brain model using VERA function (uses trisurf)

figure;
plot3DModel(gca,brainmat.surfaceModel.Model,surfRemap);
colormap(surfcmap); % colorize with annotation for Surface
alpha(modelOpacity);
hold on;
% Plot electrodes in one color
plotBallsOnVolume(gca,brainmat.electrodes.Location,[],electrodeRadius);
view(-114,25)

% Colorbar with only surface labels
cb                      = colorbar;
cb.Ticks                = [surfName_id; surfName_id(end)+1]+0.5;
cb.TickLabels           = [surfNames; {'electrodes'}];
cb.TickLabelInterpreter = 'none';
clim([1 surfName_id(end)+2]) % add 2, one for unknown, 1 for 'electrodes'

%% Plot brain model with trajectories
% Plot grayscale brain model with sticks identifying implant trajectories
NumImplants = size(brainmat.electrodes.Definition,1);
NumElecs    = [brainmat.electrodes.Definition.NElectrodes];
implantcmap = jet(NumImplants);

figure;
plot3DModel(gca,brainmat.surfaceModel.Model,[]);
alpha(modelOpacity);
hold on;
elecCtr = 1;
for i = 1:NumImplants
    plot3([brainmat.electrodes.Location(elecCtr,1), brainmat.electrodes.Location(elecCtr + NumElecs(i)-1,1)],...
          [brainmat.electrodes.Location(elecCtr,2), brainmat.electrodes.Location(elecCtr + NumElecs(i)-1,2)],...
          [brainmat.electrodes.Location(elecCtr,3), brainmat.electrodes.Location(elecCtr + NumElecs(i)-1,3)],...
          'Color',implantcmap(i,:),'LineWidth',6)

    elecCtr = elecCtr + NumElecs(i);
end
colormap([0.5 0.5 0.5; implantcmap]); 
view(-114,25)

% Colorbar with grayscale brain model and implant trajectories in jet
cb                      = colorbar;
cb.Ticks                = [0:NumImplants]+1.5;
cb.TickLabels           = {'cortex',brainmat.electrodes.Definition.Name};
cb.TickLabelInterpreter = 'none';
clim([1 NumImplants+2])

%% Plot implanted electrodes on gray brain model, using electrode labels
% Plot brain model using VERA function (uses trisurf)

figure;
plot3DModel(gca,brainmat.surfaceModel.Model);
colormap([0.5 0.5 0.5]); % colorize grayscale
alpha(modelOpacity);
hold on;
% Plot electrodes colorized by brain area
for i=1:length(uniqueElectrodeLabels)
    % Find the electrodes that belong to each unique label and color them appropriately
    elecsToPlot = strcmp(uniqueElectrodeLabels{i},electrodeLabels);
    plotBallsOnVolume(gca,brainmat.electrodes.Location(elecsToPlot,:),electrodeColors(i,:),electrodeRadius);
end
% Plot electrode numbering
plotElNums(brainmat.electrodes.Location*1.075, 1:size(brainmat.electrodes.Location,1), 12);
view(-114,25)

% Modify colorbar to include electrode labeling
cb                      = colorbar;
cb.Ticks                = [0:length(uniqueElectrodeLabels)]+1.5;
cb.TickLabels           = [{'cortex'}; uniqueElectrodeLabels(:)];
cb.TickLabelInterpreter = 'none';
clim([1 length(uniqueElectrodeLabels) + 2])


%% Plot implanted electrodes using custom electrode names from the recording amplifier

if ~isempty(brainmat.electrodeNamesKey)
    elNamesKey = struct2cell(brainmat.electrodeNamesKey);
    
    eeg_idx     = zeros(size(brainmat.electrodes.Name,1),1);
    eeg_elNames = cell(size(brainmat.electrodes.Name,1),1);
    
    for i = 1:size(brainmat.electrodes.Name,1)
        % find indices of recorded electrodes
        if any(strcmp(elNamesKey(2,:),brainmat.electrodes.Name{i}))
            eeg_idx(i) = find(strcmp(elNamesKey(2,:),brainmat.electrodes.Name{i}));
        end
        % create cell of recorded electrode names with the correct indices
        if eeg_idx(i) ~= 0
            eeg_elNames{i} = elNamesKey(1,eeg_idx(i))';
        else
            eeg_elNames{i} = '';
        end
    end
    
    figure;
    plot3DModel(gca,brainmat.surfaceModel.Model);
    colormap([0.5 0.5 0.5]); % colorize grayscale
    alpha(modelOpacity);
    hold on;
    % Plot electrodes colorized by brain area
    for i=1:length(uniqueElectrodeLabels)
        % Find the electrodes that belong to each unique label and color them appropriately
        elecsToPlot = strcmp(uniqueElectrodeLabels{i},electrodeLabels);
        plotBallsOnVolume(gca,brainmat.electrodes.Location(elecsToPlot,:),electrodeColors(i,:),electrodeRadius);
        
    end
    for i = 1:size(brainmat.electrodes.Location,1)
        % Plot electrode names
        text(brainmat.electrodes.Location(i,1)*1.075, brainmat.electrodes.Location(i,2)*1.075, brainmat.electrodes.Location(i,3)*1.075, eeg_elNames{i},'FontSize',12,'FontWeight','bold','color','b');
    end
    view(-114,25)
    
    % Modify colorbar to include electrode labeling
    cb                      = colorbar;
    cb.Ticks                = [0:length(uniqueElectrodeLabels)]+1.5;
    cb.TickLabels           = [{'cortex'}; uniqueElectrodeLabels(:)];
    cb.TickLabelInterpreter = 'none';
    clim([1 length(uniqueElectrodeLabels) + 2])
end



