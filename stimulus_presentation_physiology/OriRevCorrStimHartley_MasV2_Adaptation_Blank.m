function OriRevCorrStimHartley_MasV2_Adaptation_Blank(stim)
% Screen('Preference', 'SkipSyncTests', 0);
% OriRevCorrStim - Orientation Reverse Correlation Stimulus for
% Marmo electrophysiology (Sine-Grating with different luminances and contrasts)

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
% wrote by Mas 4 Sep 2016

try
    
    AssertOpenGL;   % We use PTB-3
    
    % if you use ViewPixx/DataPixx for the first time run these to lines for
    % setting,
    % BitsPlusImagingPipelineTest(screenNumber);
    % BitsPlusIdentityClutTest([],1)
    
    [scr,stim] = OriRevCorrStim_Init(stim); %(stimIn); % initialise screen
    stim = OriRevCorrStim_Save(scr,stim);
    
    [happy, stim] = OriRevCorrStim_InitComms(stim);
    if ~happy,
        return;
    end
    
    Screen('TextSize',scr.win,50);
    Screen('TextStyle',scr.win,2);
    Message='Please start recording and then click';
    display('******!!!  Please start recording and then click   !!!*******')
    Screen('FillRect',scr.win,scr.black);
    Screen('FillRect',scr.win,scr.black,stim.PDpos');
    DrawFormattedText(scr.win,Message,'center','center',[1024 0 0]);
    Screen('Flip',scr.win);
    GetClicks(scr.win);
    
    stimLists = OriRevCorrStim_Show(scr,stim); %#ok<NASGU>
    
    save(stim.fullFile, 'stimLists','-append')
    
    Screen('TextSize',scr.win,50);
    Screen('TextStyle',scr.win,2);
    Message='Please stop recording and then click';
    display('******!!!  Please stop recording and then click   !!!*******')
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


function [scr,stim] = OriRevCorrStim_Init(stim) %(stimIn)

% Vpixx paramteres
stim.triggerOnset = 0.002;		% Trigger onset delay in seconds
stim.triggerDuration = 0.002;	% Trigger pulse duration in seconds

%% Define randomisation parameters, I don't use these lines in this code, but didn't delete
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
PsychImaging('AddTask', 'General', 'EnableBits++Mono++Output');
% end
o=Screen('Preference','Verbosity',1);
[scr.win,scr.rect] = PsychImaging('OpenWindow',screenNumber,stim.BackGrLum,[]);
Screen('Preference','Verbosity',o);
%% Define VPIXX parameters
scr.width = stim.ScrWidth;     % (mm) width
% scr.pixelSize = 520/1920; % widtSaved to c:\data\marmo\OriRevCorr\OriRevCorr_Mas0134.math (mm) / width (pixels)
scr.viewDist = stim.ScrViewDist;  % (mm)

% gamma1=2.3996; % measured on 11 April 14
% use this command for gamma correction in your codes; we don't need for
% Display++
% PsychColorCorrection('SetEncodingGamma',scr.win,1/gamma1);

Screen('Flip', scr.win, 0, 1);
[oldmaximumvalue oldclampcolors] = Screen('ColorRange', scr.win,1024);
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

% convert stimulus to screen units (pixels and frames) and randomize the
% stimuli
stim.DeltaStim1 = floor(stim.DeltaS1 * (scr.fps/stim.frPerScene));
stim.DeltaStim2 = floor(stim.DeltaS2 * (scr.fps/stim.frPerScene));
stim.DeltaStimBLK = floor(stim.DeltaBLK * (scr.fps/stim.frPerScene));
stim.AllStim = OriRevCorrStim_RandTrial(stim);
stim.nSceneAndBlank=length(stim.AllStim);



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
save(stim.fullFile, 'scr','stim');
disp(['Saved to ' stim.fullFile]);


function [happy, stim] = OriRevCorrStim_InitComms(stim)
% Communications controls
% 1) Set up VPIxx / DataPixx/Display+= connectoin
% 2) Connect to Blackrock & send stimulus information

happy = 1; % we start out happy

if stim.DIO ==1, % prepare output connections using VPixx
    try
        stim.highTime = 1.0; % time to be high in the beginning of the frame (in 100 us steps = 0.1 ms steps)
        stim.lowTime = 24.8-stim.highTime; % followed by x msec low (enough to fill the rest of the frame high + low = 24.8 ms)
        
        stim.TriggerDataFirstStim = [repmat(bin2dec('0000000011'),stim.highTime*10,1);repmat(bin2dec('00000000000'),stim.lowTime*10,1)]';
        stim.TriggerDataSecondStim = [repmat(bin2dec('0000011000'),stim.highTime*10,1);repmat(bin2dec('00000000000'),stim.lowTime*10,1)]';
        stim.TriggerDataBlank = [repmat(bin2dec('0000011011'),stim.highTime*10,1);repmat(bin2dec('00000000000'),stim.lowTime*10,1)]';
        
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
        %
        %         % stimulus timing parameters
        my_text=strcat(...
            'FileInfo:',...
            'frPerScene=',num2str(stim.frPerScene),';',...
            'nCont=',num2str(stim.nCont),';',...
            'nOri=',num2str(stim.nOri),';',...
            'nPhase=',num2str(stim.nPhase),';',...
            'nsf=',num2str(stim.nsf),';',...
            'nLum=',num2str(stim.nLum),';');
        %
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
% Blank=0;
% if sum(diff(thisStim))==0,
%     Blank=1;
% end
if stim.CBMEX && mod(sc,stim.scCBMEX)==1, % send message with scene number every few seconds
    tmpTxt=strcat('*Stimulus:sc=',num2str(sc),';#');
    cbmex('comment',0,0,tmpTxt);
end

ContLumChange = 0;
if sc > 1
    if diff([stim.AllStim(6,sc-1),stim.AllStim(6,sc)])~=0 %|| diff([stim.AllStim(3,sc-1),stim.AllStim(3,sc)])~=0
        
        if stim.AllStim(6,sc)==1,
            ContLumChange = 1;
        elseif stim.AllStim(6,sc)==2,
            ContLumChange = 2;
        else stim.AllStim(6,sc)==3,
            ContLumChange = 3;
        end
        
    end
    
else
    
    ContLumChange = 1;
    
end

if stim.DIO,
    if fr==1,
        if ContLumChange==1,
            BitsPlusPlus('DIOCommand', scr.win, 1, 255, stim.TriggerDataFirstStim, 0);
            
        elseif ContLumChange==2, %mod(sc,ceil(stim.tCBMEX*scr.fps/stim.frPerScene))==1,
            BitsPlusPlus('DIOCommand', scr.win, 1, 255, stim.TriggerDataSecondStim, 0);
            
        elseif ContLumChange==3,
            BitsPlusPlus('DIOCommand', scr.win, 1, 255, stim.TriggerDataBlank, 0);
            
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


function  stimLists = OriRevCorrStim_Show(scr,stim)
% Loop through scenes (each scene is a unique grating)
% oriListInit stores the first 100 orientations, allowing sanity checking
% of the stimulus recreation
tic;
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
    thisStim.ori = st(1);
    thisStim.cont = st(2);
    thisStim.lum = st(3);
    thisStim.phase = st(4);
    thisStim.sf = st(5);
    
    if sc<=200,
        stimLists.ori(sc) = thisStim.ori;
        stimLists.cont(sc) = thisStim.cont;
        stimLists.lum(sc) = thisStim.lum;
        stimLists.phase(sc) = thisStim.phase;
        stimLists.sf(sc) = thisStim.sf;
        
    end
    
    if sc == 1,
        if stim.scDeg==-1, % sine-wave grating
            gTex = CreateProceduralSineGrating(scr.win, stim.diamPix(1), stim.diamPix(2), thisStim.lum*[1 1 1 0],round(stim.diamPix(1)/2),0.5);
        else % Gabor
            gTex = CreateProceduralGabor(scr.win, stim.diamPix(1), stim.diamPix(2), 0, [0.5 0.5 0.5 0.0]);
        end
        
    elseif diff([stim.AllStim(2,sc-1),stim.AllStim(2,sc)])~=0 || diff([stim.AllStim(3,sc-1),stim.AllStim(3,sc)])~=0,
        if sum(diff(st))~= 0,
            if stim.scDeg==-1, % sine-wave grating
                gTex = CreateProceduralSineGrating(scr.win, stim.diamPix(1), stim.diamPix(2), thisStim.lum*[1 1 1 0],round(stim.diamPix(1)/2),0.5);
            else % Gabor
                gTex = CreateProceduralGabor(scr.win, stim.diamPix(1), stim.diamPix(2), 0, [0.5 0.5 0.5 0.0]);
            end
        end
        
    end
    
    % Loop over video frames
    
    for fr = 1: stim.frPerScene,
        
        if stim.scDeg==-1 && sum(diff(st))~=0, % sine-wave grating
            
            Screen('DrawTexture', scr.win, gTex,[],destRect,360-thisStim.ori,[],[],[],[],[],[180-thisStim.phase, thisStim.sf, thisStim.cont, 0]);
            Screen('FillRect',scr.win,scr.black,stim.PDpos');
        else
            
            Screen('FillRect',scr.win,floor(stim.BackGrLum*scr.white));
            Screen('FillRect',scr.win,scr.black,stim.PDpos');
        end
        
        OriRevCorrStim_SendComms(stim,scr,sc,fr,st);
        
        Screen('Flip', scr.win, 0, 0); % wait for end of frame and show stimulus
        
        [~, ~,keyCode] = KbCheck(-1); % check for key-press
        %
        if find(keyCode)==KbName('ESCAPE'), breakFlag = 1; break; end % check for ESC press
        
    end
    stimLists.ElpsTim(sc)=toc;
    
    if breakFlag==1, break; end % ESC key - break this loop too
    
end


function Pre_build_Stim = OriRevCorrStim_RandTrial(stim)
% generates a random stimulus
% random number generator is initialised in OriRevCorrStim_Init
% and there should be no calls that affect RNG other than in this function
LumCont = [0 0;
    0 1;
    1 0;
    1 1];
LumContCond = [];

c1 = 1;
for i = 1 : size(LumCont,1),
    for j = 1 : size(LumCont,1),
        
        LumContCond(:,c1) = [LumCont(i,:) LumCont(j,:)];
        c1 = c1 + 1;
    end
end

stim.RepsMat = zeros(stim.Reps, size(LumContCond,2));
for i = 1 : stim.Reps,
    stim.RepsMat(i,:) = randperm(size(LumContCond,2));
end
stim.RepsMat = stim.RepsMat(:);

OneSeq = [];
for sc = 1 : stim.DeltaStim1+stim.DeltaStim2
    % Choose contrast / orientation / phase /sf for this scene
    
    ori = stim.oriList(randi(stim.nOri));
    phase = stim.phaseList(randi(stim.nPhase));
    sff = stim.sfPix(randi(stim.nsf));
    a=[ori;phase;sff];
    OneSeq=[OneSeq a];
    
end

Pre_build_Stim=[];

for Allsc = 1 : length(stim.RepsMat)
    
    if Allsc>1
        for Scb = 1 : stim.DeltaStimBLK
            Pre_build_Stim=[Pre_build_Stim 3*ones(6,1)];
        end
    end
    
    CurrCoLu = LumContCond(:,stim.RepsMat(Allsc));
    
    
    if CurrCoLu(1)==1
        cont = stim.contList(2);
    else
        cont = stim.contList(1);
    end
    
    if CurrCoLu(2)==1
        lum =  stim.LumList(2);
    else
        lum =  stim.LumList(1);
    end
    
    tsc = 0;
    for Sc1 = 1 : stim.DeltaStim1,
        tsc = tsc +1;
        Pre_build_Stim = [Pre_build_Stim [OneSeq(1,tsc); cont; lum;OneSeq(2,tsc);OneSeq(3,tsc); 1]];
        
    end
    
    
    if CurrCoLu(3)==1
        cont = stim.contList(2);
    else
        cont = stim.contList(1);
    end
    
    if CurrCoLu(4)==1
        lum =  stim.LumList(2);
    else
        lum =  stim.LumList(1);
    end
    
    for Sc2 = 1 : stim.DeltaStim2,
        tsc = tsc +1;
        Pre_build_Stim = [Pre_build_Stim [OneSeq(1,tsc); cont; lum; OneSeq(2,tsc); OneSeq(3,tsc); 2]];
        
    end
end


