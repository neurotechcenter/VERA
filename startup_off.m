close all;
clearvars;


addpath(genpath('classes'));
addpath(genpath('Plugins'));
addpath(genpath('Dependencies'));
javaaddpath('Dependencies/Widgets Toolbox/resource/MathWorksConsultingWidgets.jar');
guihandle=MainGUI();
addToolbarExplorationButtons(guihandle);