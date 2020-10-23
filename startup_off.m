close all;
clearvars;


addpath(genpath('classes'));
addpath(genpath('Components'));
addpath(genpath('Dependencies'));
javaaddpath('Dependencies/Widgets Toolbox/resource/MathWorksConsultingWidgets.jar');
import uiextras.jTree.*;
guihandle=MainGUI();
addToolbarExplorationButtons(guihandle);