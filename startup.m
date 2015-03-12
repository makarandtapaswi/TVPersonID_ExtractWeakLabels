%% Initialize the StoryGraphs project
% This file will be called automatically on starting Matlab in this directory.

clear all;
clc;
close all;

% Make some directories
if ~exist('tmp/', 'dir'),           mkdir('tmp/'); end
if ~exist('cache/', 'dir'),         mkdir('cache/'); end

global PID;

%% Working directory
PID.base_dir = [fileparts(mfilename('fullpath')) '/'];

% Check first initialization
first_init;

%% Repository folders
addpath(genpath('utilities/'));
addpath('weak_labeling//');
addpath('initializers/');
addpath('text/');
addpath(genpath('ext/'));


%% Go go go :)
fprintf('=======================================================\n');
fprintf(['Initialized Improved Weak labeling for Person Identification in TV series repository. Example video for:', ...
         '\n\t%20s : The Big Bang Theory', ...
         '\n\t%20s : Buffy the Vampire Slayer', ...
     '\n'], ...
     'BBT(se, ep)', 'BUFFY(se, ep)');

