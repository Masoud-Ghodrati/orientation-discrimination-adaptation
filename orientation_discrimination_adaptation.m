function stim = orientation_discrimination_adaptation(stim)

try
    
    AssertOpenGL;   % We use PTB-3
    
    % if you use ViewPixx/DataPixx for the first time run these to lines for
    % setting,
    % BitsPlusImagingPipelineTest(screenNumber);
    % BitsPlusIdentityClutTest([],1)
    
    [scr,stim] = OriRevCorrStim_Init(stim); %(stimIn); % initialise screen
    stim = OriRevCorrStim_Save(scr,stim);
    
    MyText = ['Hi ' stim.fName(find(stim.fName=='_',1,'last')+1:end) ' !\n\nJust some information about your task:\n\n',...
        stim.EstimatedTime '\n' stim.NumberofTrials '\n' stim.NumberofBlocks '\n\n BTW, you can listen to music\n\nBe a good subject :) and\n\nPress Any Key To Begin!' ];
    
    Screen('TextSize',scr.win,30);
    Screen('TextStyle',scr.win,2);
    DrawFormattedText(scr.win, MyText, 'center', 'center', scr.white*[1 1 1]/2);
    Screen('Flip', scr.win);
    KbStrokeWait;
    
    stimLists = OriRevCorrStim_Show(scr,stim); %#ok<NASGU>
    save(stim.fullFile, 'stimLists','-append')
    
    
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


%% house-keeping
stim.nACont = length(stim.AdaptContList);
stim.nAOri = length(stim.AdaptOriList);
stim.nAPhase = length(stim.AdaptPhaseList);
stim.nASf = length(stim.AdaptSfList);
stim.nALum = length(stim.AdaptLumList);

stim.nTOri = length(stim.TestOriList);
stim.nTOriDiff = length(stim.TestOriDiff);

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
PsychImaging('AddTask', 'FinalFormatting', 'DisplayColorCorrection', 'SimpleGamma');
% if stim.DIO
% PsychImaging('AddTask', 'General', 'EnableBits++Mono++Output');
% end
o=Screen('Preference','Verbosity',1);
[scr.win,scr.rect] = PsychImaging('OpenWindow',screenNumber, stim.BackGrLum,[]);
Screen('Preference','Verbosity',o);
%% Define VPIXX parameters
scr.width = stim.ScrWidth;     % (mm) width
% scr.pixelSize = 520/1920; % widtSaved to c:\data\marmo\OriRevCorr\OriRevCorr_Mas0134.math (mm) / width (pixels)
scr.viewDist = stim.ScrViewDist;  % (mm)

gamma1=2.3996; % measured on 11 April 14
% use this command for gamma correction in your codes
PsychColorCorrection('SetEncodingGamma',scr.win,1/gamma1);

Screen('Flip', scr.win, 0, 0);
[oldmaximumvalue oldclampcolors] = Screen('ColorRange', scr.win, 1024);

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
stim.centPixFix = [1 -1].*ceil(stim.FixationCentre * scr.ppd);
stim.FixAprPix = [1 1].*ceil(stim.FixationAertureSiz*scr.ppd);
stim.fixCrossDimPix = ceil(stim.TestFixationSize*scr.ppd);

% stim.scPix = stim.scDeg * scr.ppd; % pixels
% stim.sfPix = stim.sfDeg / scr.ppd; % cycles/pixel
stim.ASfPix = stim.AdaptSfList ./ scr.ppd; % cycles/pixel

% convert stimulus to screen units (pixels and frames) and randomize the
% stimuli
stim.DeltaStim = floor(stim.AdaptDuration * (scr.fps/stim.frPerScene));
stim.TestISIStim = floor(stim.TestISITime * scr.fps);
stim.TestStim_S1 = floor(stim.TestTime_S1 * scr.fps); % time (sec) of blocks for change lum and cont
stim.TestStim_S2 = floor(stim.TestTime_S2 * scr.fps); % time (sec) of blocks for change lum and cont
stim.AllStim = OriRevCorrStim_RandTrial(stim, scr);
stim.nScene = length(stim.AllStim);
% Make sure keyboard mapping is the same on all supported operating systems
% Apple MacOS/X, MS-Windows and GNU/Linux:
KbName('UnifyKeyNames');
% Init keyboard responses (caps doesn't matter)
advancestudytrial = KbName('n');
% Do dummy calls to GetSecs, WaitSecs, KbCheck to make sure
% they are loaded and ready when we need them - without delays
% in the wrong moment:
KbCheck;
WaitSecs(0.1);
GetSecs;
stim.CodeKey1 = KbName(stim.Key1);
stim.CodeKey2 = KbName(stim.Key2);

% Build a procedural gabor texture for a gabor with a support of tw x th
% pixels, and a RGB color offset of 0.5 -- a 50% gray.


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


function  stim = OriRevCorrStim_Show(scr,stim)
% Loop through scenes (each scene is a unique grating)
% oriListInit stores the first 100 orientations, allowing sanity checking
% of the stimulus recreation

breakFlag = 0; % set to 1 if break early
stim.Response = zeros(7, stim.nScene);
destRect = repmat(scr.center+stim.centPix-0.5*stim.diamPix,1,2) + [0 0 stim.diamPix];
FixFrame = repmat(scr.center+stim.centPixFix-0.5*stim.FixAprPix,1,2) + [0 0 stim.FixAprPix];
Screen('FillRect',scr.win, stim.BackGrLum*scr.white);
[VBLTimestamp TimFre] = Screen('Flip', scr.win, 0, 0); % wait for end of frame and show stimulus
stim.ElpsTim = cell(4, stim.nScene);

xCoords = [-stim.fixCrossDimPix stim.fixCrossDimPix 0 0];
yCoords = [0 0 -stim.fixCrossDimPix stim.fixCrossDimPix];
allCoords = [xCoords; yCoords];
BLKCounter = 1;

PerBlock = zeros(1, stim.RestEvery+1);
trblk = 1;

for tr = 1 : stim.nScene
    
    % Choose contrast / orientation / phase /sf for this scene
    st = stim.AllStim{1,tr};
    TestS1Ori = unique(st(1,st(end,:)==2));
    TestS2Ori = unique(st(1,st(end,:)==4));
       
    if stim.AllStim{2,tr} == 100
        
        sc = 1;
        thisStim.ori = st(1, sc);
        thisStim.cont = st(2, sc);
        thisStim.lum = st(3, sc);
        thisStim.phase = st(4, sc);
        thisStim.sf = st(5, sc);
        stim.BackGrLum = thisStim.lum;
        % Test stim 1
        gTex = CreateProceduralSineGrating(scr.win, stim.diamPix(1), stim.diamPix(2), thisStim.lum*[1 1 1 0],round(stim.diamPix(1)/2), 0.5);
        fullWindowMask = Screen('MakeTexture', scr.win, ones(scr.rect(4), scr.rect(3)) .* scr.white*stim.BackGrLum);
        for fr = 1 : stim.TestStim_S1
            Screen('DrawTexture', scr.win, fullWindowMask);
            Screen('DrawTexture', scr.win, gTex,[],destRect,270-thisStim.ori,[],[],[],[],[],[180-thisStim.phase, thisStim.sf, thisStim.cont, 0]);
            Screen('FillOval', scr.win, scr.white*stim.BackGrLum*[1 1 1], [FixFrame(1) FixFrame(2) FixFrame(3) FixFrame(4)],[]);
            Screen('DrawLines', scr.win, allCoords, stim.lineWidthPix, scr.white*stim.TestFixationColor, [scr.center(1)+stim.centPixFix(1), scr.center(2)+stim.centPixFix(2)], []);
            [VBLTimestamp, TimFre] = Screen('Flip', scr.win, 0, 0); % wait for end of frame and show stimulus
            stim.ElpsTim{2,tr}(fr) = 1000*TimFre;
        end
        
        % ISI
        sc = sc +1;
        if stim.DynamicNoise == true
            
            if mean(st(1:end-1, st(end,:)==3)) == -1
                
                imageTextureISI = Screen('MakeTexture', scr.win, im2uint8( scr.white*stim.BackGrLum*ones(destRect(3)-destRect(1))),[],[]);
                for fr = 1 : stim.TestISIStim
                    Screen('DrawTexture', scr.win, fullWindowMask);
                    Screen('DrawTexture', scr.win, imageTextureISI,[], destRect);
                    Screen('FillOval', scr.win, scr.white*stim.BackGrLum*[1 1 1], [FixFrame(1) FixFrame(2) FixFrame(3) FixFrame(4)],[]);
                    Screen('DrawLines', scr.win, allCoords, stim.lineWidthPix, scr.white*stim.TestFixationColor, [scr.center(1)+stim.centPixFix(1), scr.center(2)+stim.centPixFix(2)], []);
                    [VBLTimestamp, TimFre] = Screen('Flip', scr.win, 0, 0); % wait for end of frame and show stimulus
                    stim.ElpsTim{3,tr}(fr) = 1000*TimFre;
                    
                end
                
            elseif mean(st(1:end-1, st(end,:)==3)) == -2
                
                for fr = 1 : stim.TestISIStim
                    
                    NoisISI = OrientedNoise_ISI(stim, 0, scr, sc, st);
                    imageTextureISI = Screen('MakeTexture', scr.win, im2uint8(NoisISI), [], []);
                    Screen('DrawTexture', scr.win, imageTextureISI,[], destRect);
                    Screen('DrawTexture', scr.win, fullWindowMask);
                    Screen('FillOval', scr.win, scr.white*stim.BackGrLum*[1 1 1], [FixFrame(1) FixFrame(2) FixFrame(3) FixFrame(4)],[]);
                    Screen('DrawLines', scr.win, allCoords, stim.lineWidthPix, scr.white*stim.TestFixationColor, [scr.center(1)+stim.centPixFix(1), scr.center(2)+stim.centPixFix(2)], []);
                    [VBLTimestamp, TimFre] = Screen('Flip', scr.win, 0, 0); % wait for end of frame and show stimulus
                    stim.ElpsTim{3,tr}(fr) = 1000*TimFre;
                    
                end
                
            end
            
            
        elseif  stim.DynamicNoise == false
            
            if mean(st(1:end-1, st(end,:)==3)) == -1
                imageTextureISI = Screen('MakeTexture', scr.win, im2uint8(stim.BackGrLum*ones(destRect(3)-destRect(1))),[],[]);
            elseif mean(st(1:end-1, st(end,:)==3)) == -2
                NoisISI = OrientedNoise_ISI(stim, 0, scr, sc, st);
                imageTextureISI = Screen('MakeTexture', scr.win, im2uint8(NoisISI), [], []);
            end
            for fr = 1 : stim.TestISIStim
                Screen('DrawTexture', scr.win, fullWindowMask);
                Screen('DrawTexture', scr.win, imageTextureISI,[],destRect);
                Screen('FillOval', scr.win, scr.white*stim.BackGrLum*[1 1 1], [FixFrame(1) FixFrame(2) FixFrame(3) FixFrame(4)],[]);
                Screen('DrawLines', scr.win, allCoords, stim.lineWidthPix, scr.white*stim.TestFixationColor, [scr.center(1)+stim.centPixFix(1), scr.center(2)+stim.centPixFix(2)], []);
                [VBLTimestamp, TimFre] = Screen('Flip', scr.win, 0, 0); % wait for end of frame and show stimulus
                stim.ElpsTim{3,tr}(fr) = 1000*TimFre;
            end
            
        end
        
        
        % Test stim 2
        sc = sc +1;
        thisStim.ori = st(1, sc);
        thisStim.cont = st(2, sc);
        thisStim.lum = st(3, sc);
        thisStim.phase = st(4, sc);
        thisStim.sf = st(5, sc);
        keyIsDown = 0;
        gTex = CreateProceduralSineGrating(scr.win, stim.diamPix(1), stim.diamPix(2), thisStim.lum*[1 1 1 0],round(stim.diamPix(1)/2),0.5);
        Screen('DrawTexture', scr.win, fullWindowMask);
        Screen('DrawTexture', scr.win, gTex,[],destRect,270-thisStim.ori,[],[],[],[],[],[180-thisStim.phase, thisStim.sf, thisStim.cont, 0]);
        Screen('FillOval', scr.win, scr.white*stim.BackGrLum*[1 1 1], [FixFrame(1) FixFrame(2) FixFrame(3) FixFrame(4)],[]);
        Screen('DrawLines', scr.win, allCoords, stim.lineWidthPix, scr.white*stim.TestFixationColor, [scr.center(1)+stim.centPixFix(1), scr.center(2)+stim.centPixFix(2)], []);
        [VBLTimestamp startrt] = Screen('Flip', scr.win, 0, 0); % wait for end of frame and show stimulus
        
    else
        
        % Adaptation
        for sc = 1 : sum(st(end,:)==1);
            
            thisStim.ori = st(1, sc);
            thisStim.cont = st(2, sc);
            thisStim.lum = st(3, sc);
            thisStim.phase = st(4, sc);
            thisStim.sf = st(5, sc);
            stim.BackGrLum = thisStim.lum;
            if sc == 1
                gTex = CreateProceduralSineGrating(scr.win, stim.diamPix(1), stim.diamPix(2), thisStim.lum*[1 1 1 0],round(stim.diamPix(1)/2),0.5);
            elseif diff([st(2,sc-1), st(2,sc)])~=0 || diff([st(3,sc-1),st(3,sc)])~=0
                gTex = CreateProceduralSineGrating(scr.win, stim.diamPix(1), stim.diamPix(2), thisStim.lum*[1 1 1 0],round(stim.diamPix(1)/2),0.5);
            end
            
            % Loop over video frames
            fullWindowMask = Screen('MakeTexture', scr.win, ones(scr.rect(4), scr.rect(3)) .* scr.white*stim.BackGrLum);
            for fr = 1: stim.frPerScene,
                Screen('DrawTexture', scr.win, fullWindowMask);
                Screen('DrawTexture', scr.win, gTex,[],destRect,360-thisStim.ori,[],[],[],[],[],[180-thisStim.phase, thisStim.sf, thisStim.cont, 0]);
                Screen('FillOval', scr.win, scr.white*stim.BackGrLum*[1 1 1], [FixFrame(1) FixFrame(2) FixFrame(3) FixFrame(4)],[]);
                Screen('DrawLines', scr.win, allCoords, stim.lineWidthPix, scr.white*stim.TestFixationColor, [scr.center(1)+stim.centPixFix(1), scr.center(2)+stim.centPixFix(2)], []);
                [VBLTimestamp, TimFre] = Screen('Flip', scr.win, 0, 0); % wait for end of frame and show stimulus
                [~, ~,keyCode] = KbCheck(-1); % check for key-press
                if find(keyCode)==KbName('ESCAPE'), breakFlag = 1; break; end % check for ESC press
                % keep the time
                stim.ElpsTim{1,tr}(fr, sc) = 1000*TimFre;
            end
            
            if breakFlag==1, break; end % ESC key - break this loop too
            
        end
        if breakFlag==1, break; end % ESC key - break this loop too
        
        % Test stim 1
        sc = sc +1;
        thisStim.ori = st(1, sc);
        thisStim.cont = st(2, sc);
        thisStim.lum = st(3, sc);
        thisStim.phase = st(4, sc);
        thisStim.sf = st(5, sc);
        stim.BackGrLum = thisStim.lum;
        gTex = CreateProceduralSineGrating(scr.win, stim.diamPix(1), stim.diamPix(2), thisStim.lum*[1 1 1 0],round(stim.diamPix(1)/2),0.5);
        fullWindowMask = Screen('MakeTexture', scr.win, ones(scr.rect(4), scr.rect(3)) .* scr.white*stim.BackGrLum);
        for fr = 1 : stim.TestStim_S1
            Screen('DrawTexture', scr.win, fullWindowMask);
            Screen('DrawTexture', scr.win, gTex,[],destRect,270-thisStim.ori,[],[],[],[],[],[180-thisStim.phase, thisStim.sf, thisStim.cont, 0]);
            Screen('FillOval', scr.win, scr.white*stim.BackGrLum*[1 1 1], [FixFrame(1) FixFrame(2) FixFrame(3) FixFrame(4)],[]);
            Screen('DrawLines', scr.win, allCoords, stim.lineWidthPix, scr.white*stim.TestFixationColor, [scr.center(1)+stim.centPixFix(1), scr.center(2)+stim.centPixFix(2)], []);
            [VBLTimestamp, TimFre] = Screen('Flip', scr.win, 0, 0); % wait for end of frame and show stimulus
            stim.ElpsTim{2,tr}(fr) = 1000*TimFre;
        end
        
        % ISI
        sc = sc +1;
        if stim.DynamicNoise == true
            
            if mean(st(1:end-1, st(end,:)==3)) == -1
                
                imageTextureISI = Screen('MakeTexture', scr.win, im2uint8(stim.BackGrLum*ones(destRect(3)-destRect(1))),[],[]);
                for fr = 1 : stim.TestISIStim
                    Screen('DrawTexture', scr.win, fullWindowMask);
                    Screen('DrawTexture', scr.win, imageTextureISI,[],destRect);
                    Screen('FillOval', scr.win, scr.white*stim.BackGrLum*[1 1 1], [FixFrame(1) FixFrame(2) FixFrame(3) FixFrame(4)],[]);
                    Screen('DrawLines', scr.win, allCoords, stim.lineWidthPix, scr.white*stim.TestFixationColor, [scr.center(1)+stim.centPixFix(1), scr.center(2)+stim.centPixFix(2)], []);
                    [VBLTimestamp, TimFre] = Screen('Flip', scr.win, 0, 0); % wait for end of frame and show stimulus
                    stim.ElpsTim{3,tr}(fr) = 1000*TimFre;
                end
                
            elseif mean(st(1:end-1, st(end,:)==3)) == -2
                
                for fr = 1 : stim.TestISIStim
                    NoisISI = OrientedNoise_ISI(stim, 0, scr, sc, st);
                    imageTextureISI = Screen('MakeTexture', scr.win, im2uint8(NoisISI), [], []);
                    Screen('DrawTexture', scr.win, fullWindowMask);
                    Screen('DrawTexture', scr.win, imageTextureISI,[],destRect);
                    Screen('FillOval', scr.win, scr.white*stim.BackGrLum*[1 1 1], [FixFrame(1) FixFrame(2) FixFrame(3) FixFrame(4)],[]);
                    Screen('DrawLines', scr.win, allCoords, stim.lineWidthPix, scr.white*stim.TestFixationColor, [scr.center(1)+stim.centPixFix(1), scr.center(2)+stim.centPixFix(2)], []);
                    [VBLTimestamp, TimFre] = Screen('Flip', scr.win, 0, 0); % wait for end of frame and show stimulus
                    stim.ElpsTim{3,tr}(fr) = 1000*TimFre;
                end
                
            end
            
        elseif stim.DynamicNoise == false
            
            if mean(st(1:end-1, st(end,:)==3)) == -1
                imageTextureISI = Screen('MakeTexture', scr.win, im2uint8(stim.BackGrLum*ones(destRect(3)-destRect(1))),[],[]);
            elseif mean(st(1:end-1, st(end,:)==3)) == -2
                NoisISI = OrientedNoise_ISI(stim, 0, scr, sc, st);
                imageTextureISI = Screen('MakeTexture', scr.win, im2uint8(NoisISI), [], []);
            end
            for fr = 1 : stim.TestISIStim
                Screen('DrawTexture', scr.win, fullWindowMask);
                Screen('DrawTexture', scr.win, imageTextureISI,[],destRect);
                Screen('FillOval', scr.win, scr.white*stim.BackGrLum*[1 1 1], [FixFrame(1) FixFrame(2) FixFrame(3) FixFrame(4)],[]);
                Screen('DrawLines', scr.win, allCoords, stim.lineWidthPix, scr.white*stim.TestFixationColor, [scr.center(1)+stim.centPixFix(1), scr.center(2)+stim.centPixFix(2)], []);
                [VBLTimestamp, TimFre] = Screen('Flip', scr.win, 0, 0); % wait for end of frame and show stimulus
                stim.ElpsTim{3,tr}(fr) = 1000*TimFre;
            end
            
        end
        
        
        % Test stim 2
        sc = sc +1;
        thisStim.ori = st(1, sc);
        thisStim.cont = st(2, sc);
        thisStim.lum = st(3, sc);
        thisStim.phase = st(4, sc);
        thisStim.sf = st(5, sc);
        keyIsDown = 0;
        gTex = CreateProceduralSineGrating(scr.win, stim.diamPix(1), stim.diamPix(2), thisStim.lum*[1 1 1 0],round(stim.diamPix(1)/2),0.5);
        Screen('DrawTexture', scr.win, fullWindowMask);
        Screen('DrawTexture', scr.win, gTex,[],destRect,270-thisStim.ori,[],[],[],[],[],[180-thisStim.phase, thisStim.sf, thisStim.cont, 0]);
        Screen('FillOval', scr.win, scr.white*stim.BackGrLum*[1 1 1], [FixFrame(1) FixFrame(2) FixFrame(3) FixFrame(4)],[]);
        Screen('DrawLines', scr.win, allCoords, stim.lineWidthPix, scr.white*stim.TestFixationColor, [scr.center(1)+stim.centPixFix(1), scr.center(2)+stim.centPixFix(2)], []);
        [VBLTimestamp startrt] = Screen('Flip', scr.win, 0, 0); % wait for end of frame and show stimulus
        
    end
    
    while (GetSecs - startrt)<=stim.TestTime_S2
        [keyIsDown, secs, keyCode] = PsychHID('KbCheck');
        if keyCode(stim.CodeKey1)==1 || keyCode(stim.CodeKey2)==1
            break;
        end
    end
    
    [VBLTimestamp, TimFre] = Screen('Flip', scr.win, 0, 0); % wait for end of frame and show stimulus
    stim.ElpsTim{4,tr} = 1000*(TimFre-startrt);
    
    while keyCode(stim.CodeKey1)==0 && keyCode(stim.CodeKey2)==0
        [keyIsDown, secs, keyCode] = PsychHID('KbCheck');
        WaitSecs(0.001);
    end
    RT = 1000*(secs - startrt);
    Ans = 0;
    if (TestS1Ori-TestS2Ori)<0 && keyCode(stim.CodeKey1)==1 || (TestS1Ori-TestS2Ori)>0 && keyCode(stim.CodeKey2)==1
        Ans = 1;
    end
    
    Screen('DrawTexture', scr.win, fullWindowMask);
    stim.Response(:, tr) = [RT Ans TestS1Ori TestS2Ori TestS1Ori-TestS2Ori find(keyCode) stim.AllStim{2,tr}];
    if stim.Feedback
        if Ans==1
            [wavedata freq ] = audioread([stim.fold 'correct.wav']); % load sound file (make sure that it is in the same folder as this script
            Snd('Play',wavedata',freq');
            Screen('Flip', scr.win);
            WaitSecs(2) %waits 6 seconds for sound to play,if this wait is too short then sounds will be cutoff
        else
            [wavedata freq ] = audioread([stim.fold 'wrong.wav']); % load sound file (make sure that it is in the same folder as this script
            Snd('Play',wavedata',freq');
            Screen('Flip', scr.win);
            WaitSecs(2) %waits 6 seconds for sound to play,if this wait is too short then sounds will be cutoff
        end
        
    end
    PerBlock(trblk) = Ans;
    trblk = trblk +1;
    if tr > 1 && mod(tr, stim.RestEvery)==1
        PerfinThisBLK = round(100*mean(PerBlock));
        PerfWhole = round(100*mean(stim.Response(2,1:find(stim.Response(end,:)~=0,1,'last'))));
        
        if PerfinThisBLK<65
            
            MyText = ['Opps ' stim.fName(find(stim.fName=='_',1,'last')+1:end) ' !\n\n You have just finished block  ' num2str(BLKCounter),...
                '  out of  ' num2str(stim.NumBlock) '  blocks' '\n\n Your performance in this block is: ' num2str(PerfinThisBLK),...
                '\n Your overal performance is: ' num2str(PerfWhole) '\n\n You can do better\n\n Take a rest! Press Any Key To Begin When Ready'];
            
        elseif PerfinThisBLK>=65 && PerfinThisBLK<90
            MyText = ['Welldone ' stim.fName(find(stim.fName=='_',1,'last')+1:end) ' !\n\n You have just finished block  ' num2str(BLKCounter),...
                '  out of  ' num2str(stim.NumBlock) '  blocks' '\n\n Your performance in this block is: ' num2str(PerfinThisBLK),...
                '\n Your overal performance is: ' num2str(PerfWhole) '\n\n Keep doing well!\n\n Take a rest! Press Any Key To Begin When Ready'];
        elseif PerfinThisBLK>=90 && PerfinThisBLK<=99
            MyText = ['Fantastic job ' stim.fName(find(stim.fName=='_',1,'last')+1:end) ' !\n\n You have just finished block  ' num2str(BLKCounter),...
                '  out of  ' num2str(stim.NumBlock) '  blocks' '\n\n Your performance in this block is: ' num2str(PerfinThisBLK),...
                '\n Your overal performance is: ' num2str(PerfWhole) '\n\n Why not higher!?\n\n Take a rest! Press Any Key To Begin When Ready'];
        elseif PerfinThisBLK==100
            MyText = ['You are a legend ' stim.fName(find(stim.fName=='_',1,'last')+1:end) ' !\n\n You have just finished block  ' num2str(BLKCounter),...
                '  out of  ' num2str(stim.NumBlock) '  blocks' '\n\n Your performance in this block is: ' num2str(PerfinThisBLK),...
                '\n Your overal performance is: ' num2str(PerfWhole) ' \n\n Take a rest! Press Any Key To Begin When Ready'];
        end
        
        DrawFormattedText(scr.win, MyText, 'center', 'center', scr.white*[0 0 0]);
        [VBLTimestamp, TimFre1] = Screen('Flip', scr.win, 0, 0);
        KbStrokeWait;
        BLKCounter = BLKCounter +1;
        PerBlock = zeros(1, stim.RestEvery);
        trblk = 1;
    end
end

function AllTrials = OriRevCorrStim_RandTrial(stim, scr)
% generates a random stimulus
% random number generator is initialised in OriRevCorrStim_Init
% and there should be no calls that affect RNG other than in this function
stim.EarlyStartTim = floor(stim.TeststartWind_Early(1) * (scr.fps/stim.frPerScene)) : floor(stim.TeststartWind_Early(2) * (scr.fps/stim.frPerScene));
stim.LateStartTim = floor(stim.TeststartWind_Late(1) * (scr.fps/stim.frPerScene)) : floor(stim.TeststartWind_Late(2) * (scr.fps/stim.frPerScene));
stim.AdapTestStartTim = floor(stim.AdaptationTestWind(1) * (scr.fps/stim.frPerScene)) : floor(stim.AdaptationTestWind(2) * (scr.fps/stim.frPerScene));

Pre_build_Stim = cell(2, length(stim.TestOriDiff)*sum(stim.NumTrial));
tCnt = 1;

for sc1 = 1 : length(stim.TestOriDiff)
    
    for sc2 = 1 : stim.NumTrial(1)
        a = [];
        
        % make test stims
        % first stim
        oriS1 = stim.TestOriList(randi(stim.nTOri));
        phaseS1 = stim.AdaptPhaseList(randi(stim.nAPhase));
        sffS1 = stim.ASfPix(randi(stim.nASf));
        contS1 = stim.AdaptContList(2);
        lumS1 = stim.AdaptLumList(2);
        
        a = [a [oriS1;contS1;lumS1;phaseS1;sffS1;2]];
        % ISI
        if stim.TestISIType == -1
            a = [a [-1*ones(size(a,1)-1, 1); 3]];
        elseif stim.TestISIType == -2
            a = [a [-2*ones(size(a,1)-1, 1); 3]];
        else
            error('Mask Type (ISI Type) can be either 1 or 2')
        end
        
        % second Stim
        if sc2 <= round(stim.NumTrial(1)/2)
            oriS2 = oriS1 + stim.TestOriDiff(sc1);
        else
            oriS2 = oriS1 - stim.TestOriDiff(sc1);
        end
        phaseS2 = stim.AdaptPhaseList(randi(stim.nAPhase));
        sffS2 = stim.ASfPix(randi(stim.nASf));
        contS2 = stim.AdaptContList(2);
        lumS2 = stim.AdaptLumList(2);
        a = [a [oriS2;contS2;lumS2;phaseS2;sffS2;4]];
        
        Pre_build_Stim{1,tCnt} = a;
        Pre_build_Stim{2,tCnt} = 100;
        tCnt = tCnt +1;
    end
end

for sc1 = 1 : length(stim.TestOriDiff)
    
    for sc2 = 1 : stim.NumTrial(2)
        a = [];
        % Make adaptation stim
        DeltaFr = stim.AdapTestStartTim(randi(length(stim.AdapTestStartTim)));
        ori = stim.AdaptOriList(randi(stim.nAOri, [1 DeltaFr]));
        phase = stim.AdaptPhaseList(randi(stim.nAPhase, [1 DeltaFr]));
        sff = stim.ASfPix(randi(stim.nASf, [1 DeltaFr]));
        cont = stim.AdaptContList(1)*ones(1, DeltaFr);
        lum = stim.AdaptLumList(1)*ones(1, DeltaFr);
        Ind = ones(1, DeltaFr);
        a = [ori;cont;lum;phase;sff;Ind];
        
        % make test stims
        % first stim
        oriS1 = stim.TestOriList(randi(stim.nTOri));
        phaseS1 = stim.AdaptPhaseList(randi(stim.nAPhase));
        sffS1 = stim.ASfPix(randi(stim.nASf));
        contS1 = stim.AdaptContList(1);
        lumS1 = stim.AdaptLumList(1);
        
        a = [a [oriS1;contS1;lumS1;phaseS1;sffS1;2]];
        % ISI
        if stim.TestISIType == -1
            a = [a [-1*ones(size(a,1)-1, 1); 3]];
        elseif stim.TestISIType == -2
            a = [a [-2*ones(size(a,1)-1, 1); 3]];
        else
            error('Mask Type (ISI Type) can be either 1 or 2')
        end
        % second Stim
        if sc2 <= round(stim.NumTrial(2)/2)
            oriS2 = oriS1 + stim.TestOriDiff(sc1);
        else
            oriS2 = oriS1 - stim.TestOriDiff(sc1);
        end
        phaseS2 = stim.AdaptPhaseList(randi(stim.nAPhase));
        sffS2 = stim.ASfPix(randi(stim.nASf));
        contS2 = stim.AdaptContList(1);
        lumS2 = stim.AdaptLumList(1);
        a = [a [oriS2;contS2;lumS2;phaseS2;sffS2;4]];
        
        Pre_build_Stim{1,tCnt} = a;
        Pre_build_Stim{2,tCnt} = 200;
        tCnt = tCnt +1;
    end
end


for sc1 = 1 : length(stim.TestOriDiff)
    
    for sc2 = 1 : stim.NumTrial(3)
        a = [];
        % Make adaptation stim
        DeltaFr = stim.EarlyStartTim(randi(length(stim.EarlyStartTim)));
        ori = stim.AdaptOriList(randi(stim.nAOri, [1 stim.DeltaStim+DeltaFr]));
        phase = stim.AdaptPhaseList(randi(stim.nAPhase, [1 stim.DeltaStim+DeltaFr]));
        sff = stim.ASfPix(randi(stim.nASf, [1 stim.DeltaStim+DeltaFr]));
        cont = [stim.AdaptContList(1)*ones(1, stim.DeltaStim) stim.AdaptContList(2)*ones(1, DeltaFr)];
        lum = [stim.AdaptLumList(1)*ones(1, stim.DeltaStim) stim.AdaptLumList(2)*ones(1, DeltaFr)];
        Ind = ones(1, stim.DeltaStim+DeltaFr);
        a = [ori;cont;lum;phase;sff;Ind];
        
        % make test stims
        % first stim
        oriS1 = stim.TestOriList(randi(stim.nTOri));
        phaseS1 = stim.AdaptPhaseList(randi(stim.nAPhase));
        sffS1 = stim.ASfPix(randi(stim.nASf));
        contS1 = stim.AdaptContList(2);
        lumS1 = stim.AdaptLumList(2);
        
        a = [a [oriS1;contS1;lumS1;phaseS1;sffS1;2]];
        % ISI
        if stim.TestISIType == -1
            a = [a [-1*ones(size(a,1)-1, 1); 3]];
        elseif stim.TestISIType == -2
            a = [a [-2*ones(size(a,1)-1, 1); 3]];
        else
            error('Mask Type (ISI Type) can be either 1 or 2')
        end
        % second Stim
        if sc2 <= round(stim.NumTrial(3)/2)
            oriS2 = oriS1 + stim.TestOriDiff(sc1);
        else
            oriS2 = oriS1 - stim.TestOriDiff(sc1);
        end
        phaseS2 = stim.AdaptPhaseList(randi(stim.nAPhase));
        sffS2 = stim.ASfPix(randi(stim.nASf));
        contS2 = stim.AdaptContList(2);
        lumS2 = stim.AdaptLumList(2);
        a = [a [oriS2;contS2;lumS2;phaseS2;sffS2;4]];
        
        Pre_build_Stim{1,tCnt} = a;
        Pre_build_Stim{2,tCnt} = 300;
        tCnt = tCnt +1;
    end
end

for sc1 = 1 : length(stim.TestOriDiff)
    
    for sc2 = 1 : stim.NumTrial(4)
        a = [];
        % Make adaptation stim
        DeltaFr = stim.LateStartTim(randi(length(stim.LateStartTim)));
        ori = stim.AdaptOriList(randi(stim.nAOri, [1 stim.DeltaStim+DeltaFr]));
        phase = stim.AdaptPhaseList(randi(stim.nAPhase, [1 stim.DeltaStim+DeltaFr]));
        sff = stim.ASfPix(randi(stim.nASf, [1 stim.DeltaStim+DeltaFr]));
        cont = [stim.AdaptContList(1)*ones(1, stim.DeltaStim) stim.AdaptContList(2)*ones(1, DeltaFr)];
        lum = [stim.AdaptLumList(1)*ones(1, stim.DeltaStim) stim.AdaptLumList(2)*ones(1, DeltaFr)];
        Ind = ones(1, stim.DeltaStim+DeltaFr);
        a = [ori;cont;lum;phase;sff;Ind];
        
        % make test stims
        % first stim
        oriS1 = stim.TestOriList(randi(stim.nTOri));
        phaseS1 = stim.AdaptPhaseList(randi(stim.nAPhase));
        sffS1 = stim.ASfPix(randi(stim.nASf));
        contS1 = stim.AdaptContList(2);
        lumS1 = stim.AdaptLumList(2);
        
        a = [a [oriS1;contS1;lumS1;phaseS1;sffS1;2]];
        % ISI
        if stim.TestISIType == -1
            a = [a [-1*ones(size(a,1)-1, 1); 3]];
        elseif stim.TestISIType == -2
            a = [a [-2*ones(size(a,1)-1, 1); 3]];
        else
            error('Mask Type (ISI Type) can be either 1 or 2')
        end
        % second Stim
        if sc2 <= round(stim.NumTrial(4)/2)
            oriS2 = oriS1 + stim.TestOriDiff(sc1);
        else
            oriS2 = oriS1 - stim.TestOriDiff(sc1);
        end
        phaseS2 = stim.AdaptPhaseList(randi(stim.nAPhase));
        sffS2 = stim.ASfPix(randi(stim.nASf));
        contS2 = stim.AdaptContList(2);
        lumS2 = stim.AdaptLumList(2);
        a = [a [oriS2;contS2;lumS2;phaseS2;sffS2;4]];
        
        
        Pre_build_Stim{1,tCnt} = a;
        Pre_build_Stim{2,tCnt} = 400;
        tCnt = tCnt +1;
        
    end
end

Rnd = randperm(length(Pre_build_Stim));
AllTrials = Pre_build_Stim(:,Rnd);
