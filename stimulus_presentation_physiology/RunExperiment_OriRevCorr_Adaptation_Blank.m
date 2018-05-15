clear all
close all
clc

% settings
%% Define stimulus parameters
stim.centDeg = [0 0]; % (deg) x-y position of stimulus center
stim.diamDeg = -1;    % % (deg) aperture bounds. -1 gives full screen; single value specifies circular aperture; two values define a rectangle
stim.scDeg   = -1;    % set to -1 for grating
stim.frPerScene = 2; % number of frames per grating presentation (2 frames at 120 Hz gives 60 Hz)
stim.contList  = [30 60]/100;   % list of contrasts (max 2 contrast)
stim.LumList   = [30 70]/100;   % list of luminances
% rat Conditions = [ 0.5  1;
%                    0.5  0.65;
%                    0.33 0.65;
%                    0.67 0.65 ]; % different conditions
stim.oriList   = 0:15:165;    % (deg) list of orientations
stim.phaseList = 0:45:315;    % (deg) list of phases
stim.sfList    = [0.1 0.2]; %[0.2 0.4 0.6 0.8 1.6 2.4]; %[0.05 0.125 0.25 0.5 1 2];  % list of spatial frequency
stim.DeltaS1 = 4; % time (sec) for lum-cont condition 1 (stim 1)
stim.DeltaS2 = 6; % time (sec) for lum-cont condition 2 (stim 2)
stim.DeltaBLK = 4; % time (sec) for blank (stim 5)
stim.Reps = 15;  % number of reps per transition condition

stim.BackLum = 0; % 1: change the background based on stimuli, 0: set teh background to gray

if stim.BackLum==1,
    stim.BackGrLum=stim.LumList;
else stim.BackGrLum=0.5;
end

% Define screen parameters
stim.ScrWidth = 700;     % (mm) width
stim.ScrViewDist = 300;  % (mm)

% Define saving parameters
stim.fold = 'S:\CJ178\';
stim.fName = 'OriRevCorrMasV2_adaptBLK_CJ178_';

% Communications
stim.DIO = true; % use DataPIXX digital output
stim.CBMEX = false; % true => use CBMEX for communications
stim.scCBMEX = 80; %(scenes) how often should  a message be sent to BlackRock
stim.PD = false; % use photodiode - plots a small white square on the top left corner of screen at stimulus onset
stim.PDpos = [1 1 150 150]; %(pixels) position of photodiode rectangle relative to top-left corner of screen (BOTTOM-RIGHT)

OriRevCorrStimHartley_MasV2_Adaptation_Blank(stim)
