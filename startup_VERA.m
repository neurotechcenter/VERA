close all;
clearvars;
clc;
restoredefaultpath;

addpath(genpath('classes'));
addpath(genpath('Components'));
addpath(genpath('Dependencies'));
warning off
javaaddpath('Dependencies/Widgets Toolbox/resource/MathWorksConsultingWidgets.jar');
import uiextras.jTree.*;
warning on
guihandle=MainGUI();
addToolbarExplorationButtons(guihandle);