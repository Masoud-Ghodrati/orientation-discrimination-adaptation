clear all
close all
clc
% Masoud: I UPDATED OriRevCorrStim_RandTrial function in 29 AUG 2106
% settings
%% Define stimulus parameters
stim.centDeg = [0 0]; % (deg) x-y position of stimulus center
stim.diamDeg = -1;    % % (deg) aperture bounds. -1 gives full screen; single value specifies circular aperture; two values define a rectangle
stim.scDeg   = -1;    % set to -1 for grating
stim.frPerScene = 2; % number of frames per grating presentation (2 frames at 120 Hz gives 60 Hz)
stim.tTot = 1800;     % (s) total presentation time %3600 for 1h

stim.contList  = 0.2;           % [0.08 0.16 40 1] list of contrasts to randomise (max 1 for grating, 100 for Gabor)
stim.LumList   = 0.5;         % [0 1]
stim.oriList   = 0:10:180;    % (deg) list of orientations to randomise
stim.phaseList = 0:45:315;    % (deg) list of phases to randomise
stim.sfList    = [0.1 0.2]; %[0.05 0.125 0.25 0.4 0.5 1 2];%[0.25 0.4];%[0.05 0.125 0.25 0.4 0.5 1 2] ;%[0.125 0.4];%[0.05 0.125 0.25 0.5 1 2]; %0.4  % list of spatial frequency
stim.NumStimPerSeq = 500; % mean/LAMBDA for poisson distribution
stim.BackLum = 0;             % 1: change the background based on stimuli, 0: set teh background to gray

if stim.BackLum==1,
    stim.BackGrLum=stim.LumList;
else stim.BackGrLum=0.5;
end

% Define screen parameters
stim.ScrWidth = 700;     % (mm) width
stim.ScrViewDist = 300;  % (mm)


% Define saving parameters
stim.fold = 'S:\CJ178\';
stim.fName = 'OriRevCorrMasV2_CJ178_';

% Communications
stim.DIO = true; % use DataPIXX digital output
stim.CBMEX = false; % true => use CBMEX for communications
stim.scCBMEX = 80; %(scenes) how often should  a message be sent to BlackRock
stim.PD = false; % use photodiode - plots a small white square on the top left corner of screen at stimulus onset
stim.PDpos = [1 1 150 150]; %(pixels) position of photodiode rectangle relative to top-left corner of screen (BOTTOM-RIGHT)

OriRevCorrStimHartley_MasV2(stim)
