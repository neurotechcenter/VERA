%% Startup, load brain.mat and add VERA to MATLAB path
clear;
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

modelOpacity        = 1; % Range from 0 to 1
viewX               = -114; 
viewY               = 25;   

GenerateRotatingGif = 1;
numGifFrames        = 180;
numGifColors        = 256;
GifDelayTime        = 0.1; % seconds

%% Create surface annotation colors
[surfRemap,surfcmap,surfNames,surfName_id] = createColormapFromAnnotations(brainmat.surfaceModel,0);

fullcolorFig = figure('Position',[50 50 1200 900]);
modelPlot = plot3DModel(gca,brainmat.surfaceModel.Model,surfRemap);
colormap(surfcmap); % colorize with annotation for Surface
alpha(modelOpacity);

% Modify colorbar to include more detailed labeling (surface labels on bottom, electrode labels on top)
cb                      = colorbar;
cb.Ticks                = surfName_id+0.5;
cb.TickLabels           = surfNames(:);
cb.TickLabelInterpreter = 'none';
clim([surfName_id(1) surfName_id(end)+1])

% Save full color figure
saveas(fullcolorFig,[filepath,filename(1:end-4),'.fig'])

%% Create Rotating Figure
if GenerateRotatingGif
    set(gcf,'color','w');
    set(gca,'CameraViewAngleMode','Manual')
    axis equal
    zoom(1.3)
    for i = 1:numGifFrames
        view(i/numGifFrames*360+viewX,viewY)
        drawnow
        frame = getframe(fullcolorFig);
        im{i} = frame2im(frame);
    end
    
    for i = 1:numGifFrames
        [A,map] = rgb2ind(im{i},numGifColors);
        if i == 1
            imwrite(A,map,[filepath,filename(1:end-4),'.gif'],"gif","LoopCount",Inf,"DelayTime",GifDelayTime);
        else
            imwrite(A,map,[filepath,filename(1:end-4),'.gif'],"gif","WriteMode","append","DelayTime",GifDelayTime);
        end
    end
    clear frame im A map
end