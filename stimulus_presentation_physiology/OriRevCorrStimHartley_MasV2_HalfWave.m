function OriRevCorrStimHartley_MasV2_HalfWave(stim)
% Screen('Preference', 'SkipSyncTests', 0);
% OriRevCorrStim - Orientation Reverse Correlation Stimulus for
% Rat electrophysiology (Sine-Grating with different luminances and contrasts)

% presents a grating of randomly chosen orientation / contrast / phase / spatial frequency for
% a specified time
% Typically I'd expect to update the "scene" at 60 Hz
% (every 2 frames on 120 Hz VPixx)
%
% We use a number of methods to ensure synchronisation between stimulus
% presentation and data acquisition:

%    - photodiode is flashed when a specific stimulus combination is presented
%    - DataPixx digital lins are set to indicate every new scene (regularclock)
%    - network message is sent every few seconds with the scene count (slow clock)

% Note that the random number generator is initialised in OriRevCorrStim_Init
% and there should be no calls that affect the RNG other than in the
% function OriRevCorrStim_RandTrial

% HISTORY
% 12/04/13 - NP - Wrote it
% 11/04/14 -MGho - Modified it
try
    
    AssertOpenGL;   % We use PTB-3
    
    % if you use ViewPixx/DataPixx for the first time run these to lines for
    % setting,
    % BitsPlusImagingPipelineTest(screenNumber);
    % BitsPlusIdentityClutTest([],1)
    
    [~,stim, CurrST] = OriRevCorrStim_Init1(stim); %(stimIn); % initialise screen
    Screen('CloseAll'); % close all windows
    [scr,stim] = OriRevCorrStim_Init(stim); %(stimIn); % initialise screen
    stim = OriRevCorrStim_Save(scr,stim);
    
    [happy, stim] = OriRevCorrStim_InitComms(stim);
    if ~happy,
        return;
    end
    
    Screen('TextSize',scr.win,50);
    Screen('TextStyle',scr.win,2);
    Message='Please start recording and then click';
    %     clc
    display('******!!!  Please start recording and then click   !!!*******')
    Screen('FillRect',scr.win,scr.black);
    Screen('FillRect',scr.win,scr.black,stim.PDpos');
    DrawFormattedText(scr.win,Message,'center','center',[1024 0 0]);
    Screen('Flip',scr.win);
    GetClicks(scr.win);
    
    stimLists = OriRevCorrStim_Show(scr,stim,CurrST); %#ok<NASGU>
    
    save(stim.fullFile, 'stimLists','-append')
    
    Screen('TextSize',scr.win,50);
    Screen('TextStyle',scr.win,2);
    Message='Please stop recording and then click';
    
    display('*****!!!  Please stop recording and then click   !!!*******')
    display(stim.fullFile)
    Screen('FillRect',scr.win,scr.black);
    DrawFormattedText(scr.win,Message,'center','center',[1024 0 0]);
    
    Screen('Flip',scr.win);
    GetClicks(scr.win);
    
catch me
    me %#ok<NOPRT>
    keyboard
end
ShowCursor;
ListenChar(0); % restore keyboard input echo
% Screen('LoadNormalizedGammaTable', scr.win, scr.oldLUT); % restore original LUT
Screen('CloseAll'); % close all windows

function [scr,stim,CurrST] = OriRevCorrStim_Init1(stim) %(stimIn)

% Vpixx paramteres
stim.triggerOnset = 0.002;		% Trigger onset delay in seconds
stim.triggerDuration = 0.002;	% Trigger pulse duration in seconds

% %Load GUI
% [hGUI,stim] = OriRevCorr_GUI(stim);
% close(hGUI);
% pause(0.1);

%% Define randomisation parameters
stim.rSeed = sum(100*clock);
stim.rStream = RandStream('mt19937ar','Seed',stim.rSeed);
RandStream.setGlobalStream(stim.rStream); % note to the uninitiated - this is object oriented coding

%% house-keeping
stim.nCont = length(stim.contList);
stim.nOri = length(stim.oriList);
stim.nPhase = length(stim.phaseList);
stim.nsf = length(stim.sfList);
stim.nLum = length(stim.LumList);

% %% Set the Toolbox preferences
% Screen('Preference', 'SkipSyncTests', 2);
% Screen('Preference', 'VisualDebugLevel', 1);
Screen('Preference', 'SkipSyncTests', 1)
Screen('Preference', 'VisualDebugLevel', 0);
KbName('UnifyKeyNames');

screenNumber = max(Screen('Screens'));
% if you use ViewPixx/DataPixx/PsychImaging for the first time after any config, run these to lines for
% setting,
% BitsPlusImagingPipelineTest(screenNumber);
% BitsPlusIdentityClutTest([],1)
PsychImaging('PrepareConfiguration');
% PsychImaging('AddTask', 'General', 'EnableNative10BitFramebuffer');
PsychImaging('AddTask','General','FloatingPoint32Bit');
PsychImaging('AddTask', 'FinalFormatting', 'DisplayColorCorrection', 'ClampOnly');
% if stim.DIO
%     PsychImaging('AddTask', 'General', 'EnableBits++Mono++Output');
% end
o=Screen('Preference','Verbosity',1);
[scr.win,scr.rect] = PsychImaging('OpenWindow',screenNumber,127*[1 1 1],[],32,2);
Screen('Preference','Verbosity',o);
%% Define VPIXX parameters
scr.width = stim.ScrWidth;     % (mm) width
% scr.pixelSize = 520/1920; % widtSaved to c:\data\marmo\OriRevCorr\OriRevCorr_Mas0134.math (mm) / width (pixels)
scr.viewDist = stim.ScrViewDist;  % (mm)




% gamma1=2.3996; % measured on 11 April 14
% use this command for gamma correction in your codes
% PsychColorCorrection('SetEncodingGamma',scr.win,1/gamma1);

Screen('Flip', scr.win, 0, 1);
[oldmaximumvalue oldclampcolors] = Screen('ColorRange', scr.win,1024);

% Screen('BlendFunction', scr.win, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA); % reduce aliasing
% scr.oldLUT = Screen('LoadNormalizedGammaTable', scr.win, scr.LUT);
[scr.center(1), scr.center(2)] = RectCenter(scr.rect);
% Obtain screen parameters
% default colour indices
scr.black = BlackIndex(scr.win);
scr.white = WhiteIndex(scr.win);

scr.ifi = Screen('GetFlipInterval', scr.win);
scr.fps = 1/scr.ifi;
% scr.ppd = pi * (scr.rect(3)-scr.rect(1)) / atan(scr.width/scr.viewDist/2) / 360; % pixels per degree
scr.ppd =  ((scr.rect(3)-scr.rect(1))/scr.width) / ((180/pi) * atan(1/scr.viewDist));
scr.cent = floor((scr.rect(3:4)-scr.rect(1:2)) / 2);

GetSecs; % preload this function
HideCursor;	% Hide the mouse cursor
Priority(MaxPriority(scr.win));

% convert to pixels / frames etc.
if stim.diamDeg == -1, % full screen - vertical fill
    %  stim.diamPix = min(scr.rect(3:4));
    stim.diamPix = max(scr.rect(3:4))*[1.2 1.2];
    %     stim.centDeg = [0 0]; % centered!
else
    stim.diamPix = ceil(stim.diamDeg * scr.ppd);
    if length(stim.diamPix)==1,
        stim.diamPix = stim.diamPix*[1 1];
    end
end
stim.centPix = [1 -1].*ceil(stim.centDeg * scr.ppd);

stim.scPix = stim.scDeg * scr.ppd; % pixels
% stim.sfPix = stim.sfDeg / scr.ppd; % cycles/pixel
stim.sfPix = stim.sfList ./ scr.ppd; % cycles/pixel


% Build a procedural gabor texture for a gabor with a support of tw x th
% pixels, and a RGB color offset of 0.5 -- a 50% gray.
if stim.scDeg==-1, % sine-wave grating
    gTex = CreateProceduralSineGrating(scr.win, stim.diamPix(1), stim.diamPix(2), stim.LumList*[1 1 1 0],round(stim.diamPix(1)/2),0.5);
else % Gabor
    gTex = CreateProceduralGabor(scr.win, stim.diamPix(1), stim.diamPix(2), 0, [0.5 0.5 0.5 0.0]);
end

% convert stimulus to screen units (pixels and frames) and randomize the
% stimuli
stim.nScene = ceil(stim.tTot * (scr.fps/stim.frPerScene));
[stim, CurrST]= OriRevCorrStim_RandTrial(stim, scr, gTex);
stim.nSceneAndBlank=length(stim.AllStim);



function [scr,stim] = OriRevCorrStim_Init(stim) %(stimIn)

% Vpixx paramteres
stim.triggerOnset = 0.002;		% Trigger onset delay in seconds
stim.triggerDuration = 0.002;	% Trigger pulse duration in seconds

% %Load GUI
% [hGUI,stim] = OriRevCorr_GUI(stim);
% close(hGUI);
% pause(0.1);

%% Define randomisation parameters
stim.rSeed = sum(100*clock);
stim.rStream = RandStream('mt19937ar','Seed',stim.rSeed);
RandStream.setGlobalStream(stim.rStream); % note to the uninitiated - this is object oriented coding

%% house-keeping
stim.nCont = length(stim.contList);
stim.nOri = length(stim.oriList);
stim.nPhase = length(stim.phaseList);
stim.nsf = length(stim.sfList);
stim.nLum = length(stim.LumList);

% %% Set the Toolbox preferences
% Screen('Preference', 'SkipSyncTests', 2);
% Screen('Preference', 'VisualDebugLevel', 1);
Screen('Preference', 'SkipSyncTests', 1)
Screen('Preference', 'VisualDebugLevel', 0);
KbName('UnifyKeyNames');

screenNumber = max(Screen('Screens'));
% if you use ViewPixx/DataPixx/PsychImaging for the first time after any config, run these to lines for
% setting,
% BitsPlusImagingPipelineTest(screenNumber);
% BitsPlusIdentityClutTest([],1)
PsychImaging('PrepareConfiguration');
% PsychImaging('AddTask', 'General', 'EnableNative10BitFramebuffer');
PsychImaging('AddTask','General','FloatingPoint32Bit');
PsychImaging('AddTask', 'FinalFormatting', 'DisplayColorCorrection', 'ClampOnly');
PsychImaging('AddTask', 'General', 'EnableBits++Mono++Output');
o=Screen('Preference','Verbosity',1);
[scr.win,scr.rect] = PsychImaging('OpenWindow',screenNumber,0.5*[1 1 1],[]);
Screen('Preference','Verbosity',o);
%% Define VPIXX parameters
scr.width = stim.ScrWidth;     % (mm) width
% scr.pixelSize = 520/1920; % widtSaved to c:\data\marmo\OriRevCorr\OriRevCorr_Mas0134.math (mm) / width (pixels)
scr.viewDist = stim.ScrViewDist;  % (mm)




% gamma1=2.3996; % measured on 11 April 14
% use this command for gamma correction in your codes
% PsychColorCorrection('SetEncodingGamma',scr.win,1/gamma1);

Screen('Flip', scr.win, 0, 1);
[oldmaximumvalue oldclampcolors] = Screen('ColorRange', scr.win,1024);

% Screen('BlendFunction', scr.win, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA); % reduce aliasing
% scr.oldLUT = Screen('LoadNormalizedGammaTable', scr.win, scr.LUT);
[scr.center(1), scr.center(2)] = RectCenter(scr.rect);
% Obtain screen parameters
% default colour indices
scr.black = BlackIndex(scr.win);
scr.white = WhiteIndex(scr.win);

scr.ifi = Screen('GetFlipInterval', scr.win);
scr.fps = 1/scr.ifi;
% scr.ppd = pi * (scr.rect(3)-scr.rect(1)) / atan(scr.width/scr.viewDist/2) / 360; % pixels per degree
scr.ppd =  ((scr.rect(3)-scr.rect(1))/scr.width) / ((180/pi) * atan(1/scr.viewDist));
scr.cent = floor((scr.rect(3:4)-scr.rect(1:2)) / 2);

GetSecs; % preload this function
HideCursor;	% Hide the mouse cursor
Priority(MaxPriority(scr.win));

% convert to pixels / frames etc.
if stim.diamDeg == -1, % full screen - vertical fill
    %  stim.diamPix = min(scr.rect(3:4));
    stim.diamPix = max(scr.rect(3:4))*[1.2 1.2];
    %     stim.centDeg = [0 0]; % centered!
else
    stim.diamPix = ceil(stim.diamDeg * scr.ppd);
    if length(stim.diamPix)==1,
        stim.diamPix = stim.diamPix*[1 1];
    end
end
stim.centPix = [1 -1].*ceil(stim.centDeg * scr.ppd);

stim.scPix = stim.scDeg * scr.ppd; % pixels
% stim.sfPix = stim.sfDeg / scr.ppd; % cycles/pixel
stim.sfPix = stim.sfList ./ scr.ppd; % cycles/pixel


% Build a procedural gabor texture for a gabor with a support of tw x th
% pixels, and a RGB color offset of 0.5 -- a 50% gray.
% if stim.scDeg==-1, % sine-wave grating
%     gTex = CreateProceduralSineGrating(scr.win, stim.diamPix(1), stim.diamPix(2), stim.LumList*[1 1 1 0],round(stim.diamPix(1)/2),0.5);
% else % Gabor
%     gTex = CreateProceduralGabor(scr.win, stim.diamPix(1), stim.diamPix(2), 0, [0.5 0.5 0.5 0.0]);
% end

% convert stimulus to screen units (pixels and frames) and randomize the
% stimuli
% stim.nScene = ceil(stim.tTot * (scr.fps/stim.frPerScene));
% [stim, CurrST]= OriRevCorrStim_RandTrial(stim, scr, gTex);
% stim.nSceneAndBlank=length(stim.AllStim);






function stim = OriRevCorrStim_Save(scr,stim) %#ok<INUSL>
% save parameter listing

% find the next available file
fileNames = dir([stim.fold stim.fName '*.mat']);
Temp = struct2cell(fileNames);
F = char(Temp(1,:));

if isempty(F), %no files already exist
    fNum = '0000';
else
    %find numbers in files - ignore Saving.Base and .mat
    G = str2num(F(:, length(stim.fName)+1:end-4)); %#ok<ST2NM>
    fNum = num2str(max(G) + 1,'%0.4d'); %increment file number & make it 4 chars
end

stim.fullFile = [stim.fold stim.fName fNum '.mat'];

%save the parameters
save(stim.fullFile, 'scr','stim', '-v7.3');
disp(['Saved to ' stim.fullFile]);


function [happy, stim] = OriRevCorrStim_InitComms(stim)
% Communications controls
% 1) Set up VPIxx / DataPixx connectoin
% 2) Connect to Blackrock & send stimulus information

happy = 1; % we start out happy

if stim.DIO ==1, % prepare output connections using VPixx
    try
        stim.highTime = 1.0; % time to be high in the beginning of the frame (in 100 us steps = 0.1 ms steps)
        stim.lowTime = 24.8-stim.highTime; % followed by x msec low (enough to fill the rest of the frame high + low = 24.8 ms)
        stim.TriggerDataONE = [repmat(bin2dec('0000000001'),stim.highTime*10,1);repmat(bin2dec('00000000000'),stim.lowTime*10,1)]';
        stim.TriggerDataTHREE = [repmat(bin2dec('0000000011'),stim.highTime*10,1);repmat(bin2dec('00000000000'),stim.lowTime*10,1)]';
        stim.TriggerDataFIVE = [repmat(bin2dec('0000000101'),stim.highTime*10,1);repmat(bin2dec('00000000000'),stim.lowTime*10,1)]';
        stim.TriggerDataNUM = [repmat(bin2dec('0000011000'),stim.highTime*10,1);repmat(bin2dec('00000000000'),stim.lowTime*10,1)]';
        stim.TriggerDataSIX = [repmat(bin2dec('0000000110'),stim.highTime*10,1);repmat(bin2dec('00000000000'),stim.lowTime*10,1)]';
        stim.TriggerDataOVERLAP = [repmat(bin2dec('0000011011'),stim.highTime*10,1);repmat(bin2dec('00000000000'),stim.lowTime*10,1)]';
        %         stim.TriggerDataOFF = [repmat(bin2dec('0000000000'),stim.highTime*10,1);repmat(bin2dec('00000000000'),stim.lowTime*10,1)]';
        %         Datapixx('Open');
        %         Datapixx('StopAllSchedules');
        %         Datapixx('RegWrRd');    % Synchronize Datapixx registers to local register cache
        %
        %         % We'll make sure that all the TTL digital outputs are low before we start
        %         Datapixx('SetDoutValues', 0);
        %         Datapixx('RegWrRd');
        %
        %         doutWave = [1 0];
        %         bufferAddress = 8e6;
        %         Datapixx('WriteDoutBuffer', doutWave, bufferAddress);
        %         samplesPerTrigger = size(doutWave,2);
        %         Datapixx('SetDoutSchedule', stim.triggerOnset,...
        %             [3, 2],...
        %             3, bufferAddress, samplesPerTrigger);
        % [3, 2] is a 2 element array, then the first element specifies the
        % rate, and the second element specifies the units of the rate.
        % If units = 1, then the rate is interpreted as integer samples/second.
        % If units = 2, then the rate is interpreted as integer samples/video frame.
        % If units = 3, then the rate is interpreted as double precision seconds/sample
        % (sample period).
        
        %         dio = [];
    catch ME %#ok<NASGU>
        disp('Unable to initialise VPixx digital output lines');
        happy = 0;
        %         dio = [];
    end
else
    %     dio = [];
end


if stim.CBMEX, % if network switch is used, open a CBMEX session
    try
        cbmex('open');
        % add stimulus file name as comment
        % send stimulus filename to Blackrock
        [path, file, ~] = fileparts(stim.fullFile);
        my_text=strcat(...
            'FileInfo:',...
            'file_name=',file,';',...
            'path=',strrep(path,':',''),';');
        cbmex('comment',0,0,my_text);
        
        % stimulus timing parameters
        my_text=strcat(...
            'FileInfo:',...
            'tTot=',num2str(stim.tTot),';',...
            'frPerScene=',num2str(stim.frPerScene),';',...
            'nCont=',num2str(stim.nCont),';',...
            'nOri=',num2str(stim.nOri),';',...
            'nPhase=',num2str(stim.nPhase),';',...
            'nsf=',num2str(stim.nsf),';',...
            'nLum=',num2str(stim.nLum),';');
        
        cbmex('comment',0,0,my_text);
        disp('sent')
    catch ME
        happy = 0;
        disp('Unable to initialise cbmex connection');
        disp(ME.message)
        disp(['Line ' num2str(ME.stack.line)])
    end
end


function OriRevCorrStim_SendComms(stim,scr,sc,fr,thisStim)
% send Photodiode / VPIXX communications
% lock these to frame 1 of each scene
Blank=0;
if sum(diff(thisStim))==0,
    Blank=1;
end
if stim.CBMEX && mod(sc,stim.scCBMEX)==1, % send message with scene number every few seconds
    tmpTxt=strcat('*Stimulus:sc=',num2str(sc),';#');
    cbmex('comment',0,0,tmpTxt);
end

if stim.DIO,
    
    if fr==1,
        if mod(sc,stim.scCBMEX)==1 && Blank==1,
            BitsPlusPlus('DIOCommand', scr.win, 1, 255, stim.TriggerDataOVERLAP, 0);
            
            
        elseif mod(sc,stim.scCBMEX)==1, %mod(sc,ceil(stim.tCBMEX*scr.fps/stim.frPerScene))==1,
            BitsPlusPlus('DIOCommand', scr.win, 1, 255, stim.TriggerDataNUM, 0);
            %             %             doutWave = [3 0];
            % %         elseif mod(sc,stim.scCBMEX)~=1 && Blank==0,%thisStim.ori==0
            % %             BitsPlusPlus('DIOCommand', scr.win, 1, 255, stim.TriggerDataONE, 0);
            %             %             doutWave = [1 0];
            %         end
            
            
        elseif Blank==1,
            BitsPlusPlus('DIOCommand', scr.win, 1, 255, stim.TriggerDataTHREE, 0);
            %             %             doutWave = [5 0];
        end
        
        
    end
end

if stim.PD
    
    
    if fr==1
        if mod(sc,stim.scCBMEX)==1
            %         && thisStim.cont == stim.contList(1) && ...
            %             thisStim.ori == stim.oriList(1) && ...
            %             thisStim.phase == stim.phaseList(1) && ...
            %             thisStim.sf == stim.sfList(1),
            
            Screen('FillRect',scr.win,scr.white,stim.PDpos');
        end
    else
        Screen('FillRect',scr.win,scr.black,stim.PDpos');
    end
    
    
end


function  stimLists = OriRevCorrStim_Show(scr,stim,CurrST)
% Loop through scenes (each scene is a unique grating)
% oriListInit stores the first 100 orientations, allowing sanity checking
% of the stimulus recreation

breakFlag = 0; % set to 1 if break early

% if stim.CBMEX,
%     cbmex('comment',255,0,'REC:status=START;');
% end
destRect = repmat(scr.center+stim.centPix-0.5*stim.diamPix,1,2) + [0 0 stim.diamPix];
Screen('FillRect',scr.win,floor(stim.BackGrLum*scr.white));
Screen('FillRect',scr.win,scr.black,stim.PDpos');
Screen('Flip', scr.win, 0, 0); % wait for end of frame and show stimulus
for sc=1:stim.nSceneAndBlank
    
    
    % Choose contrast / orientation / phase /sf for this scene
    st=stim.AllStim(:,sc);
    thisStim.ori = st(2);
    thisStim.cont = st(3);
    thisStim.phase = st(4);
    thisStim.sf = st(5);
    
    if sc<=100,
        stimLists.ori(sc) = thisStim.ori;
        stimLists.cont(sc) = thisStim.cont;
        stimLists.phase(sc) = thisStim.phase;
        stimLists.sf(sc) = thisStim.sf;
        
    end
    
    % Loop over video frames
    
    tic;
    for fr = 1: stim.frPerScene,
        
        if stim.scDeg==-1 && st(1)<length(CurrST.UnqStimNam), % sine-wave grating
            imageTexture = Screen('MakeTexture', scr.win, im2uint8(CurrST.UnqStimfile{st(1)}),[],[]);
            Screen('DrawTexture', scr.win, imageTexture,[],destRect);
            %             Screen('DrawTexture', scr.win, imageTexture,[],stim.centPix,[],[],[],[],[],[],[]);
            
            %         elseif stim.scDeg~=-1 && sum(diff(st))~=0, % Gabor
            
            %         Screen('DrawTexture', scr.win, gTex, [], [], 360-thisStim.ori, [], [], [], [], kPsychDontDoRotation, [180-thisStim.phase, stim.sfPix, stim.scPix, thisStim.cont, 1, 0, 0, 0]);
            
            Screen('FillRect',scr.win,scr.black,stim.PDpos');
            
        else
            
            Screen('FillRect',scr.win,floor(stim.BackGrLum*scr.white));
            Screen('FillRect',scr.win,scr.black,stim.PDpos');
        end
        
        
        
        OriRevCorrStim_SendComms(stim,scr,sc,fr,st(2:end));
        %         (stim,scr,sc,fr,thisStim)
        Screen('Flip', scr.win, 0, 0); % wait for end of frame and show stimulus
        
        [~, ~,keyCode] = KbCheck(-1); % check for key-press
        %
        if find(keyCode)==KbName('ESCAPE'), breakFlag = 1; break; end % check for ESC press
        
    end
    stimLists.ElpsTim(sc)=toc;
    
    if breakFlag==1, break; end % ESC key - break this loop too
    
end


function [stim, CurrST] = OriRevCorrStim_RandTrial(stim, scr, gTex)
% generates a random stimulus
% random number generator is initialised in OriRevCorrStim_Init
% and there should be no calls that affect RNG other than in this function

StimCount = 1;
destRect = repmat(scr.center+stim.centPix-0.5*stim.diamPix,1,2) + [0 0 stim.diamPix];
destRectR = floor(destRect);
for UnqOri = 1 : length(stim.oriList),
    for UnqSf = 1: length(stim.sfList),
        for UnqPh = 1 : length(stim.phaseList),
            
            Screen('DrawTexture', scr.win, gTex,[],destRect,stim.oriList(UnqOri),[],[],[],[],[],[180-stim.phaseList(UnqPh), stim.sfPix(UnqSf), stim.contList, 0]);
            
            imageArray=Screen('GetImage', scr.win);
            Screen('Flip', scr.win, 0, 0); % wait for end of frame and show stimulus
            %             save  imageArray imageArray
            %             sdgsd
            %             im1 = uint8(zeros(size(imageArray)));
            %             for iMasx = 1 : size(imageArray,1)
            %                 for iMasy = 1 : size(imageArray,2)
            %
            %                     if imageArray(iMasx, iMasy, 1)==0 && imageArray(iMasx, iMasy, 2)==0 && imageArray(iMasx, iMasy, 3)==1
            %                         im1(iMasx, iMasy,:) = [127 127 127];
            %                     else
            %                         im1(iMasx, iMasy,:) = imageArray(iMasx, iMasy,:);
            %
            %                     end
            %                 end
            %             end
            %
            grating= (im2double(rgb2gray(imageArray(destRectR(2):destRectR(4),destRectR(1):destRectR(3),:)))*2)-1;
            %             save grating grating
            %             grating = rand(size(grating));
            if stim.contpolar >0
                CurrST.UnqStimfile{StimCount} = (grating.*(grating>0))/2+0.5;
                
            else
                CurrST.UnqStimfile{StimCount} = (grating.*(grating<0))/2+0.5;
            end
            CurrST.UnqStimNam{StimCount} = [stim.oriList(UnqOri) stim.contpolar stim.phaseList(UnqPh) stim.sfPix(UnqSf)];
            StimCount = StimCount + 1;
            
        end
    end
end

try
    load Pre_build_Stim.mat
    stim.AllStim = Pre_build_Stim;
    stim.UnqStim = CurrST.UnqStimNam;
catch
    SeqStimCounter=0;
    Pre_build_Stim=[];
    StimPerSeq = max(stim.NumStimPerSeq);
    % save CurrST CurrST
    for sc = 1:stim.nScene
        % Choose contrast / orientation / phase /sf for this scene
        
        R = randi(length(CurrST.UnqStimNam));
        SelectedSTim = [R CurrST.UnqStimNam{R}]';
        Pre_build_Stim=[Pre_build_Stim SelectedSTim];
        SeqStimCounter=SeqStimCounter+1;
        if SeqStimCounter==StimPerSeq,
            
            SeqStimCounter=0;
            
            StimPerSeq=poissrnd(stim.NumStimPerSeq)+1;
            SelectedSTim=[length(CurrST.UnqStimNam)+1 StimPerSeq StimPerSeq StimPerSeq StimPerSeq]';
            Pre_build_Stim=[Pre_build_Stim SelectedSTim];
            
        end
        
        
    end
    stim.AllStim = Pre_build_Stim;
    stim.UnqStim = CurrST.UnqStimNam;
    save Pre_build_Stim Pre_build_Stim
end