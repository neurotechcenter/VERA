% Startup VERA Pipeline Designer through this script

%Clear matlab environment
clearvars;
clc;

%add all paths
addpath(genpath('classes'));
addpath(genpath('Components'));
addpath(genpath('Dependencies'));
addpath(genpath('PipelineDesigner'));

%java stuff to make sure that the GUI works as expected
warning off
javaaddpath('Dependencies/Widgets Toolbox/resource/MathWorksConsultingWidgets.jar');
import uiextras.jTree.*;
warning on

%startup GUI
f = waitbar(0.3,'Opening Pipeline Designer...');

PipelineDesigner();

waitbar(1,f);
close(f);