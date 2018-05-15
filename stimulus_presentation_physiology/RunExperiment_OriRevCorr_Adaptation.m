clear all
close all
clc

% settings
%% Define stimulus parameters
stim.centDeg = [0 0]; % (deg) x-y position of stimulus center
stim.diamDeg = -1;    % % (deg) aperture bounds. -1 gives full screen; single value specifies circular aperture; two values define a rectangle
stim.scDeg   = -1;    % set to -1 for grating
stim.frPerScene = 2; % number of frames per grating presentation (2 frames at 120 Hz gives 60 Hz)
stim.tTot = 3600;     % (s) total presentation time

stim.contList  = [30 60]/100; % list of contrasts (max 2 contrasts)
stim.LumList   = [30 70]/100; % list of luminances (max 2 contrasts)
stim.oriList   = 0:15:165;    % (deg) list of orientations to randomise
stim.phaseList = 0:45:315;    % (deg) list of phases to randomise
stim.sfList    = [0.1 0.2]; %[0.2 0.4 0.6 0.8 1.6 2.4]; %[0.05 0.125 0.25 0.5 1 2];  % list of spatial frequency
stim.DeltaT = 5; % time (sec) of blocks for change lum and cont

stim.BackLum = 0;             % 1: change the background based on stimuli, 0: set teh background to gray

if stim.BackLum==1,
    stim.BackGrLum=stim.LumList;
else stim.BackGrLum=0.5;
end

% Define screen parameters
stim.ScrWidth = 700;     % (mm) width
stim.ScrViewDist = 300;  % (mm)


% Define saving parameters
stim.fold = 'C:\data\CJ175\';
stim.fName = 'OriRevCorrMasV2_adapt_CJ181_';

% Communications
stim.DIO = false; % use DataPIXX digital output
stim.CBMEX = false; % true => use CBMEX for communications
stim.scCBMEX = 80; %(scenes) how often should  a message be sent to BlackRock
stim.PD = false; % use photodiode - plots a small white square on the top left corner of screen at stimulus onset
stim.PDpos = [1 1 150 150]; %(pixels) position of photodiode rectangle relative to top-left corner of screen (BOTTOM-RIGHT)

OriRevCorrStimHartley_MasV2_Adaptation(stim)
