clear all
close all
clc

% settings
%% Define stimulus parameters
stim.centDeg = [0 0]; % (deg) x-y position of stimulus center
stim.diamDeg = 10;   % % (deg) aperture bounds. -1 gives full screen; single value specifies circular aperture; two values define a rectangle
stim.scDeg   = -1;    % set to -1 for grating
stim.frPerScene = 2; % number of frames per grating presentation (2 frames at 120 Hz gives 60 Hz)
stim.tTot = 1800;     % (s) total presentation time

stim.contList  = 1;           % [0 1] list of contrasts to randomise (max 1 for grating, 100 for Gabor)
stim.contpolar = -1;          % +1 = white; -1 = black
stim.LumList   = 0.5;         % [0 1]
stim.oriList   = 0:15:165;    % (deg) list of orientations to randomise
stim.phaseList = 0:45:315;    % (deg) list of phases to randomise
stim.sfList    = 0.4; %[0.05 0.125 0.25 0.5 1 2];  % list of spatial frequency
stim.NumStimPerSeq = 11; % mean/LAMBDA for poisson distribution
stim.BackLum = 1;             % 1: change the background based on stimuli, 0: set teh background to gray

if stim.BackLum==1,
    stim.BackGrLum=stim.LumList;
else stim.BackGrLum=0.5;
end

% Define screen parameters
stim.ScrWidth = 700;     % (mm) width
stim.ScrViewDist = 730;  % (mm)


% Define saving parameters
stim.fold = 'C:\data\CJ175\';
stim.fName = 'OriRevCorrMasV2_hw_CJ175_';

% Communications
stim.DIO = true; % use DataPIXX digital output
stim.CBMEX = true; % true => use CBMEX for communications
stim.scCBMEX = 80; %(scenes) how often should  a message be sent to BlackRock
stim.PD = false; % use photodiode - plots a small white square on the top left corner of screen at stimulus onset
stim.PDpos = [1 1 150 150]; %(pixels) position of photodiode rectangle relative to top-left corner of screen (BOTTOM-RIGHT)

OriRevCorrStimHartley_MasV2_HalfWave(stim)
