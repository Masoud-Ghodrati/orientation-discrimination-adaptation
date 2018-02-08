clear
close all
clc

% settings
%% Define stimulus parameters
stim.centDeg = [0 0]; % (deg) x-y position of stimulus center
stim.diamDeg = 6.5;    % (deg) specifies circular aperture; two values define a rectangle
stim.frPerScene = 2;  % number of frames per grating presentation for adaptation period (2 frames at 120 Hz gives 60 Hz)

stim.AdaptContList = [10 70]/100; % [30 60]/100; list of contrasts (max 2 contrasts)
stim.AdaptLumList = [30 30]/100;  % [30 70]/100; list of luminances (max 2 contrasts)
stim.AdaptOriList = 0:15:165;     % (deg) list of orientations to randomise
stim.AdaptPhaseList = 0:45:315;   % (deg) list of phases to randomise
stim.AdaptSfList = [1.5]; % list of spatial frequency
stim.AdaptDuration = 6; % time (sec) of blocks for change lum and cont

stim.TestContList  = stim.AdaptContList(2); % Test contrast
stim.TestLumList  = stim.AdaptLumList(2);  % Test lumiance

stim.TestOriList   = 40:50; % (deg) list of test orientations
% stim.TestOriDiff = [0.5 1.5 3 4.5 7.5 12];%[0.25 0.5 0.75 1.5 3 4.5];%[0.5 1.5 3 4.5 7.5 12];%[2 4 8 12 16]; %[5:4:30]; % the size of orientation test for stim 2
stim.TestOriDiff = [0.25 0.5 .75 1.5 3 4.5]; %[0.5 1.5 3 4.5 7.5 12];%[2 4 8 12 16]; %[5:4:30]; % the size of orientation test for stim 2

stim.TestTime_S1 = 0.2; % time (sec) of first test stim
stim.TestTime_S2 = 0.2; % time (sec) of second test stim
stim.TestISITime = 0.2; % time (sec) of ISI
stim.TestISIType = -2; % -1: blank, -2: noise
stim.TeststartWind_Early = [0.2 1]; % time (sec) window in which the test 1 is presented after cont/lum transition, randomly selected from this window
stim.TeststartWind_Late = [4 5]; % time (sec) window in which the test 1 is presented after cont/lum transition, randomly selected from this window
stim.AdaptationTestWind = [2 4]+1; %

stim.TestApertureColor_S1 = [1 1 1]/2; % circular aperture color for test 1 stim
stim.TestApertureColor_S2 = [1 1 1]/2; % circular aperture color for test 2 stim
stim.ApertureWidth = 2; % circular aperture width
stim.TestFixationColor = [0 0 0]; % fixation color for all stages but test 1 and 2 stims
stim.TestFixationSize = 0.3; % fixation size
stim.lineWidthPix = 2;
stim.TestFixationColor_S1 = [0 0 0];  % fication color for test 1 stim
stim.TestFixationColor_S2 = [0 0 0]; % fication color for test 2 stim
stim.FixationCentre = [0 0];
stim.FixationAertureSiz = 1; % deg;
stim.NumTrial = [10 10 10 10]; %[20 20 14 14];     % number of trials per orientation change condition (e.g., 10 trials for orientation change size of 2 degree between test 1 and 2 stims)
stim.RestEvery = 35;
stim.NumBlock = round(sum(length(stim.TestOriDiff)*stim.NumTrial)/stim.RestEvery);

% Filtered Noise specifications for Test 1 and 2 stims
stim.SfCenterTest = stim.AdaptSfList(1); %1;  % the center of Guassian Function for Sf, it might be a bit confusing, refer to these paper: Heeley, D. W., et al. "The oblique effect in orientation acuity." Vision research 37.2 (1997): 235-242.
stim.SfBWTest = 0.2; % SF BW of the filter
stim.OriBWTest = 32; % BW for Orietation (spread)
% Filtered Noise specifications for ISI
stim.SfBWISI = stim.SfBWTest;  % the center of Guassian Function for Sf
stim.OriBWISI = 360; % BW for Orietation (spread), this is full BW as it need to cover all the orientation

stim.BackLum = 1;             % 1: change the background based on stimuli, 0: set teh background to gray
if stim.BackLum==1,
    stim.BackGrLum = stim.AdaptLumList(1);
else stim.BackGrLum=0.5;
end

% Respose key
stim.Key1 = 'LeftArrow'; % if test 1 stim is rotated anti-clockwise relative to test 2 stim
stim.Key2 = 'RightArrow'; % if test 1 stim is rotated clockwise relative to test 2 stim
stim.Feedback = 1; % 1: give sound feedback to subjects, 0) no feedback
% Define screen parameters
stim.ScrWidth = 700;     % (mm) width
stim.ScrViewDist = 700;  % (mm)

% some infor to show
stim.EstimatedTime = [ '   Estimated Time   ' num2str(([3 5 7 10]*[length(stim.TestOriDiff)*stim.NumTrial]')/60) '   mins '];
stim.NumberofTrials = ['     Number of Trials ' num2str(sum(length(stim.TestOriDiff)*stim.NumTrial)) '        '];
stim.NumberofBlocks = ['     Number of Blocks ' num2str(stim.NumBlock) '        '];

% display([ '******    Estimated Time ' num2str(([3 5 7 10]*[length(stim.TestOriDiff)*stim.NumTrial]')/60) '   mins ******']);
% display([ '******    Number of Trials ' num2str(sum(length(stim.TestOriDiff)*stim.NumTrial)) '       ******']);
% display([ '******    Number of Blocks ' num2str(stim.NumBlock) '       ******']);
% display('------ If you are happy, press any key ------')
% pause()
% Define saving parameters
% stim.fold = 'C:\data\Masoud_Psycho_Task\Version2\';
stim.fold = [cd '\'];
stim.fName = 'Behavioral_Exp_Subject_test';
stim = orientation_discrimination_adaptation(stim);


%% analysis part
close all
load(stim.fullFile)

%%
close all
Cof = 10;
Color = [0 0 0;1 0 0;0 1 0;0 0 1];
Ind = unique( stimLists.Response(end,:) );
for i = 1 : length(Ind)
    
    Resp{i} = stimLists.Response(:, stimLists.Response(end, :)==Ind(i));
    
end

OriSiz = unique(round(Cof*stimLists.Response(5,:)));
for j = 1 : length(Ind)
    for i = 1 : length(OriSiz)
        
        Perf{j}(1,i) = median(Resp{j}(1, round(Cof*Resp{j}(5,:))==OriSiz(i))) ; % RT
        Perf{j}(2,i) = mean(Resp{j}(2, round(Cof*Resp{j}(5,:))==OriSiz(i))) ; % Perf
        
    end
end

for j = 1 : length(Ind)
    if j<=2
        subplot(2,2,1)
    else
        subplot(2,2,2)
    end
    plot(fliplr(-stim.TestOriDiff), Perf{j}(1,1:length(stim.TestOriDiff)), '-o', 'color', Color(j,:)), hold on
    plot(stim.TestOriDiff, Perf{j}(1, length(stim.TestOriDiff)+1:end), '-o', 'color', Color(j,:)), hold on
    
    if j==2
        legend('','discrimination','','adaptation')
    elseif j==4
        legend('','early','','late')
    end
    xlabel('\Delta Ori')
    ylabel('RT (ms)')
end


for j = 1 : length(Ind)
    if j<=2
        subplot(2,2,3)
    else
        subplot(2,2,4)
    end
    plot(fliplr(-stim.TestOriDiff), 1-Perf{j}(2,1:length(stim.TestOriDiff)), '-o', 'color', Color(j,:)), hold on
    plot(stim.TestOriDiff, Perf{j}(2, length(stim.TestOriDiff)+1:end), '-o', 'color', Color(j,:)), hold on
    if j==2
        legend('','discrimination','','adaptation')
    elseif j==4
        legend('','early','','late')
    end
    xlabel('\Delta Ori')
    ylabel('Response')
end
%%
figure,
AdaptFrameTime = cell2mat(stimLists.ElpsTim(1,:));
Stim1FrameTime = cell2mat(stimLists.ElpsTim(2,:));
Stim1FrameTime = diff(reshape(Stim1FrameTime, stim.TestStim_S1, stim.nScene),1,1);
ISIFrameTime = cell2mat(stimLists.ElpsTim(3,:));
ISIFrameTime = diff(reshape(ISIFrameTime, stim.TestStim_S1, stim.nScene),1,1);
Stim2Time = cell2mat(stimLists.ElpsTim(4,:));

subplot(221)
hist(diff(AdaptFrameTime, 1),linspace(0,20,100))
xlabel('Frame Time Adaptation Period (ms)')

subplot(222)
hist(Stim1FrameTime(:),linspace(0,20,100))
xlabel('Frame Time S1 Period (ms)')

subplot(223)
hist(ISIFrameTime(:),linspace(0,20,100))
xlabel('Frame Time ISI Period (ms)')

subplot(224)
hist(Stim2Time,100)
xlabel('Time of S2 (ms)')

