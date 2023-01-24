% Startup VERA through this script


%Clear matlab environment
close all;
clearvars;
clc;
restoredefaultpath;


%add all paths
addpath(genpath('classes'));
addpath(genpath('Components'));
addpath(genpath('Dependencies'));

%java stuff to make sure that the GUI works as expected
warning off
javaaddpath('Dependencies/Widgets Toolbox/resource/MathWorksConsultingWidgets.jar');
import uiextras.jTree.*;
warning on

%startup GUI
guihandle=MainGUI();
addToolbarExplorationButtons(guihandle);