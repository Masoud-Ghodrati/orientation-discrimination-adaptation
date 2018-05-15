function OriRevCorrStimHartley_MasV2_Annular(stim)
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
    
    [scr,stim,gTex] = OriRevCorrStim_Init(stim); %(stimIn); % initialise screen
    stim = OriRevCorrStim_Save(scr,stim);
    
    [happy stim] = OriRevCorrStim_InitComms(stim);
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
    
    stimLists = OriRevCorrStim_Show(scr,stim,gTex); %#ok<NASGU>
    
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


function [scr,stim,gTex] = OriRevCorrStim_Init(stim) %(stimIn)

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
% if stim.diamDeg == -1, % full screen - vertical fill
%     %  stim.diamPix = min(scr.rect(3:4));
%     stim.diamPix = max(scr.rect(3:4))*[1.2 1.2];
%     %     stim.centDeg = [0 0]; % centered!
% else
stim.CntdiamPix = ceil(stim.CntdiamDeg * scr.ppd);
stim.SurdiamPix = ceil(stim.SurdiamDeg * scr.ppd);
if length(stim.CntdiamDeg)==1 || length(stim.SurdiamDeg)==1
    stim.CntdiamPix = stim.CntdiamPix*[1 1];
    stim.SurdiamPix = stim.SurdiamPix*[1 1];
end
% end
stim.centPix = [1 -1].*ceil(stim.centDeg * scr.ppd);

stim.scPix = stim.scDeg * scr.ppd; % pixels
% stim.sfPix = stim.sfDeg / scr.ppd; % cycles/pixel
stim.sfPix = stim.sfList ./ scr.ppd; % cycles/pixel

% convert stimulus to screen units (pixels and frames) and randomize the
% stimuli
stim.nScene = ceil(stim.tTot * (scr.fps/stim.frPerScene));
stim.AllStim = OriRevCorrStim_RandTrial(stim);
stim.nSceneAndBlank=length(stim.AllStim);

% Build a procedural gabor texture for a gabor with a support of tw x th
% pixels, and a RGB color offset of 0.5 -- a 50% gray.

if stim.Condition ==1 % sine-wave grating
    
    gTex.Cnt = CreateProceduralSineGrating(scr.win, stim.CntdiamPix(1), stim.CntdiamPix(2), stim.LumList*[1 1 1 0],round(stim.CntdiamPix(1)/2), 0.5);
    gTex.Sur = CreateProceduralSineGrating(scr.win, stim.SurdiamPix(1), stim.SurdiamPix(2), stim.LumList*[1 1 1 0],round(stim.SurdiamPix(1)/2), 0);
    
elseif stim.Condition ==2 % surround only
    
    gTex.Cnt = CreateProceduralSineGrating(scr.win, stim.CntdiamPix(1), stim.CntdiamPix(2), stim.LumList*[1 1 1 0],round(stim.CntdiamPix(1)/2), 0);
    gTex.Sur = CreateProceduralSineGrating(scr.win, stim.SurdiamPix(1), stim.SurdiamPix(2), stim.LumList*[1 1 1 0],round(stim.SurdiamPix(1)/2), 0.5);
    
elseif stim.Condition ==3 % centre surround
    
    gTex.Cnt = CreateProceduralSineGrating(scr.win, stim.CntdiamPix(1), stim.CntdiamPix(2), stim.LumList*[1 1 1 0],round(stim.CntdiamPix(1)/2), 0.5);
    gTex.Sur = CreateProceduralSineGrating(scr.win, stim.SurdiamPix(1), stim.SurdiamPix(2), stim.LumList*[1 1 1 0],round(stim.SurdiamPix(1)/2), 0.5);
    
else
    
    error('Worng stimulus conidtion')
    
end


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
if thisStim(1)==0,
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


function  stimLists = OriRevCorrStim_Show(scr,stim,gTex)
% Loop through scenes (each scene is a unique grating)
% oriListInit stores the first 100 orientations, allowing sanity checking
% of the stimulus recreation

breakFlag = 0; % set to 1 if break early

% if stim.CBMEX,
%     cbmex('comment',255,0,'REC:status=START;');
% end
SurdestRect = repmat(scr.center+stim.centPix-0.5*stim.SurdiamPix,1,2) + [0 0 stim.SurdiamPix];
CntdestRect = repmat(scr.center+stim.centPix-0.5*stim.CntdiamPix,1,2) + [0 0 stim.CntdiamPix];
Screen('FillRect',scr.win,floor(stim.BackGrLum*scr.white));
Screen('FillRect',scr.win,scr.black,stim.PDpos');
Screen('Flip', scr.win, 0, 0); % wait for end of frame and show stimulus
for sc=1:stim.nSceneAndBlank
    
    
    % Choose contrast / orientation / phase /sf for this scene
    st=stim.AllStim(:,sc);
    thisStim.oriCnt = st(1);
    thisStim.contCnt = st(2);
    thisStim.phaseCnt = st(3);
    thisStim.sfCnt = st(4);
    thisStim.oriSur = st(5);
    thisStim.contSur = st(6);
    thisStim.phaseSur = st(7);
    thisStim.sfSur = st(8);
    
    if sc<=100,
        stimLists.oriCnt(sc) = thisStim.oriCnt;
        stimLists.contCnt(sc) = thisStim.contCnt;
        stimLists.phaseCnt(sc) = thisStim.phaseCnt;
        stimLists.sfCnt(sc) = thisStim.sfCnt;
        stimLists.oriSur(sc) = thisStim.oriSur;
        stimLists.contSur(sc) = thisStim.contSur;
        stimLists.phaseSur(sc) = thisStim.phaseSur;
        stimLists.sfSur(sc) = thisStim.sfSur;
    end
    
    % Loop over video frames
    
    tic;
    for fr = 1: stim.frPerScene,
        
        
        Screen('DrawTexture', scr.win, gTex.Sur,[],SurdestRect,360-thisStim.oriSur,[],[],[],[],[],[180-thisStim.phaseSur, thisStim.sfSur, thisStim.contSur, 0]);
        Screen('DrawTexture', scr.win, gTex.Cnt,[],CntdestRect,360-thisStim.oriCnt,[],[],[],[],[],[180-thisStim.phaseCnt, thisStim.sfCnt, thisStim.contCnt, 0]);
        
        Screen('FillRect',scr.win,scr.black,stim.PDpos');
        
        
        OriRevCorrStim_SendComms(stim,scr,sc,fr,st);
        
        Screen('Flip', scr.win, 0, 0); % wait for end of frame and show stimulus
        %         imageArray=Screen('GetImage', scr.win, [], [], [1],[]);
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
% Masoud: I UPDATED OriRevCorrStim_RandTrial function in 29 AUG 2106
SeqStimCounter=0;
All_Stim=[];

% Surround
for Cont_Sur = 1 :  stim.nCont,
    
    for Ori_Sur = 1 : stim.nOri,
        
        for Phs_Sur = 1 : stim.nPhase,
            
            for SF_Sur = 1 : stim.nsf,
                
                contSur = stim.contList(Cont_Sur);
                oriSur = stim.oriList(Ori_Sur);
                phaseSur = stim.phaseList(Phs_Sur);
                sffSur = stim.sfPix(SF_Sur);
                
                % Center
                for Cont_Cnt = 1 :  stim.nCont,
                    
                    for Ori_Cnt = 1 : stim.nOri,
                        
                        for Phs_Cnt = 1 : stim.nPhase,
                            
                            for SF_Cnt = 1 : stim.nsf,
                                
                                contCnt = stim.contList(Cont_Cnt);
                                oriCnt = stim.oriList(Ori_Cnt);
                                phaseCnt = stim.phaseList(Phs_Cnt);
                                sffCnt = stim.sfPix(SF_Cnt);
                                
                                
                                a=[oriCnt;contCnt;phaseCnt;sffCnt;oriSur;contSur;phaseSur;sffSur];
                                All_Stim=[All_Stim a];
                            end
                            
                        end
                        
                    end
                    
                end
                
            end
            
        end
        
    end
    
end
% save All_Stim All_Stim
Pre_build_Stim=[];
for sc = 1:stim.nScene
    % Choose contrast / orientation / phase /sf for this scene
    
    a=All_Stim(:,randi(size(All_Stim,2)));
    Pre_build_Stim=[Pre_build_Stim a];
    
end


