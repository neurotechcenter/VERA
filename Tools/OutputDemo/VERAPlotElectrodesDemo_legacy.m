%% Startup, load brain.mat and add VERA to MATLAB path
clear;
close all;
clc;

% Add VERA to path
addpath(genpath(fullfile(cd,'..','..')))

% Load output from VERA MatOutput component
[filename,filepath] = uigetfile('*.mat','Select brain.mat file to load','MultiSelect','off');
if filepath == 0
    fprintf('\nError: Please select at least one file.\n')
    return;
end

brainmat = load(fullfile(filepath,filename));

elec_radius = 0.5;

%% Plot implanted electrodes on brain model
% Create color map from annotations (surface labels)
[remap,cmap,names,name_id] = createColormapFromAnnotations(brainmat.annotation);

% Plot brain model using VERA function (uses trisurf)
figure;
plot3DModel(gca,brainmat.cortex,remap);
colormap(cmap); % colorize with annotation for Surface
cb = colorbar('Ticks',[name_id; name_id(end)+1]+0.5,'TickLabels',[names; {'electrodes'}]);
clim([1 name_id(end)+2]) % add 2, one for unknown, 1 for electrodes
cb.TickLabelInterpreter = 'none';
alpha(0.05);
hold on;
% Plot electrodes in one color
plotBallsOnVolume(gca,brainmat.tala.electrodes,[],elec_radius);


%% Plot brain model with sticks
NumImplants = size(brainmat.electrodeDefinition.Definition,1);
NumElecs    = [brainmat.electrodeDefinition.Definition.NElectrodes];
implantcmap = jet(NumImplants);

figure;
plot3DModel(gca,brainmat.cortex,[]);
alpha(0.3);
hold on;
elecCtr  = 1;
for i = 1:NumImplants
    plot3([brainmat.tala.electrodes(elecCtr,1), brainmat.tala.electrodes(elecCtr + NumElecs(i)-1,1)],...
          [brainmat.tala.electrodes(elecCtr,2), brainmat.tala.electrodes(elecCtr + NumElecs(i)-1,2)],...
          [brainmat.tala.electrodes(elecCtr,3), brainmat.tala.electrodes(elecCtr + NumElecs(i)-1,3)],...
          'Color',implantcmap(i,:),'LineWidth',6)

    elecCtr = elecCtr + NumElecs(i);
end
colormap([0.5 0.5 0.5;implantcmap]); 
cb = colorbar('Ticks',[0:NumImplants]+1.5,'TickLabels',{'cortex',brainmat.electrodeDefinition.Definition.Name});
clim([1 NumImplants+2])
cb.TickLabelInterpreter = 'none';

%% Plot implanted electrodes on brain model, using electrode labels
% Use secondary labels (more specific) for electrode locations (typically volume labels)
% Secondary labels come from using the "ReplaceLabels" component
cell_array_labels = cellfun(@(x)x{1},brainmat.SecondaryLabel,'UniformOutput',false); % convert to easier to use cell array
unique_labels     = unique(cell_array_labels);
label_cols        = distinguishable_colors(length(unique_labels));

% Plot brain model using VERA function (uses trisurf)
fullcolor = figure;
plot3DModel(gca,brainmat.cortex,remap);
colormap(cmap); % colorize with annotation for Surface
alpha(0.1);
hold on;
% Plot electrodes colorized by brain area (annotation, secondary labels)
for i=1:length(unique_labels)
    % Find the electrodes that belong to each unique label and color them appropriately
    elecsToPlot = strcmp(unique_labels{i},cell_array_labels);
    plotBallsOnVolume(gca,brainmat.tala.electrodes(elecsToPlot,:),label_cols(i,:),elec_radius);
end
view(-114,25)

% Modify colorbar to include more detailed labeling (original surface labels on bottom, electrode labels on top)
cb            = colorbar;
cb.Ticks      = [name_id; (name_id(end)+1:1:name_id(end)+length(unique_labels))']+0.5;
cb.TickLabels = {names{:}, unique_labels{:}}';
cb.TickLabelInterpreter = 'none';
clim([name_id(1) name_id(end) + length(unique_labels) + 1])

%% Plot implanted electrodes on gray brain model, using electrode labels
% Use secondary labels (more specific) for electrode locations (typically volume labels)
% Secondary labels come from using the "ReplaceLabels" component
cell_array_labels = cellfun(@(x)x{1},brainmat.SecondaryLabel,'UniformOutput',false); % convert to easier to use cell array
unique_labels     = unique(cell_array_labels);
label_cols        = distinguishable_colors(length(unique_labels));

% Plot brain model using VERA function (uses trisurf)
figure;
plot3DModel(gca,brainmat.cortex);
colormap([0.5 0.5 0.5]); % colorize grayscale
alpha(0.1);
hold on;
plotElNums(brainmat.tala.electrodes*1.075, 1:size(brainmat.tala.electrodes,1), 12);
% Plot electrodes colorized by brain area (secondary labels)
for i=1:length(unique_labels)
    % Find the electrodes that belong to each unique label and color them appropriately
    elecsToPlot = strcmp(unique_labels{i},cell_array_labels);
    plotBallsOnVolume(gca,brainmat.tala.electrodes(elecsToPlot,:),label_cols(i,:),elec_radius);
end
view(-114,25)

% Modify colorbar to include electrode labeling
cb            = colorbar;
cb.Ticks      = [1:length(unique_labels)+1]+0.5;
cb.TickLabels = {'cortex',unique_labels{:}}';
cb.TickLabelInterpreter = 'none';
clim([1 length(unique_labels) + 2])


% Save the best one
saveas(fullcolor,[filepath,filename(1:end-4),'.fig'])







