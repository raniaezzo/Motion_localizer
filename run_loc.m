function [VP, pa] = run_loc(whichLoc)

% 'mt','mstL','mstR','fst'

debugTrigger = 0;

PsychDefaultSetup(2);
display = 1; % 1-AD % 2-laptop % 3-NY
if nargin < 1 || isempty(whichLoc) % pick mt by default given empty
     whichLoc = 'mt'; 
elseif strcmp(whichLoc, 'mst') % pick left mst by default given mst
     whichLoc = 'mstL';
end

addpath(genpath('HelperToolbox'));
filename = get_info(whichLoc);
%% Setup parameters and viewing geometry
data = [];
global GL; % GL data structure needed for all OpenGL demos
backGroundColor = [0 0 0]; %[0.5 0.5 0.5].*255; % Gray-scale - calibrate for display so white and black dots have same contrast with background
skipSync = 1; % skip Sync to deal with sync issues (should be for debugging only)
VP = SetupDisplay_loc(skipSync, backGroundColor, display,whichLoc);
if VP.stereoMode == 8 && display ~=2
    Datapixx('SetPropixxDlpSequenceProgram',1); % 1 is for RB3D mode, 3 for setting up to 480Hz, 5 for 1440Hz
    Datapixx('RegWr');    
    Datapixx('SetPropixx3DCrosstalkLR', 0); % minimize the crosstalk
    Datapixx('SetPropixx3DCrosstalkRL', 0); % minimize the crosstalk
end

VP.backGroundColor = backGroundColor;
priorityLevel=MaxPriority(VP.window);
Priority(priorityLevel);

pa = SetupParameters_loc(VP);
if strcmp(whichLoc, 'mstR') || strcmp(whichLoc, 'mstL') 
    pa = UpdatePa_mst(VP,pa,whichLoc); % need to update parameters for mst
end

pa.response = zeros(pa.numberOfTrials,1);
kb = SetupKeyboard();
pa.trialNumber = 0;
fn = 1; %Frame 1
dontClear = 0;

kb = SetupKeyboard();
VP = MakeTextures(pa,VP);
VP.debugTrigger = debugTrigger;
%% Generate new dot matrices for quick drawing rather than doing the calculations between frames

Screen('SelectStereoDrawbuffer', VP.window, 0);
Screen('DrawText', VP.window, 'Preparing Experiment...L',VP.Rect(3)/2-130,VP.Rect(4)/2);
Screen('SelectStereoDrawbuffer', VP.window, 1);
Screen('DrawText', VP.window, 'Preparing Experiment...R',VP.Rect(3)/2-130,VP.Rect(4)/2);
VP.vbl = Screen('Flip', VP.window, [], dontClear);

if strcmp(whichLoc, 'fst')
    create_stim_loc(VP,pa,whichLoc);
    load('DotBank.mat')
    pa.current_stimulus = dotMatrix.(char(whichLoc));
else
    pa.current_stimulus = zeros(pa.numberOfDots,8,pa.totalFrames);
end

StateID = 0;
OnGoing = 1;
skip = 0;
GetSecs; KbCheck;
kbIdx = GetKeyboardIndices;

whichFn = 1;
positions   = allcomb(d2r(pa.thetaDirs), pa.rDirs.*VP.pixelsPerDegree );
[VP.centerX, VP.centerY]     = pol2cart(positions(:,1), positions(:,2));
[centerX2, centerY2] = pol2cart(d2r(pa.allPositions(1,1)), tand(pa.allPositions(1,2))*VP.screenDistance);

whichCon = repelem(repmat([1;2],pa.nRepBlock,1),pa.blockDuration*VP.frameRate);

%% Experiment Starts
while ~kb.keyCode(kb.escKey) && OnGoing
    
    %% States control the experimental flow (e.g., inter trial interval, stimulus, response periods)
    switch StateID
        case 0            
            % waiting for trigger
            
            [VP kb] = wait_trigger(display,kb,VP)
            
            fn = 1;
            StateID = 1; % send to fixation point
            tic
        case 1 % Begin drawing stimulus
                        
            % if it's mt/mst, calculate dots in real time
            % if it's fst, skip this section and use pre-calculated dots
            if strcmp(whichLoc, 'mt') || strcmp(whichLoc, 'mstR') || strcmp(whichLoc, 'mstL')
                if whichCon(fn) == 1
                    if strcmp(pa.conditionNames{1}, 'circular')
                        [x y] = pol2cart(pa.theta+0.01.*sqrt(pa.r').*sin(ones(1,pa.numberOfDots).*2*pi*pa.tf.*GetSecs+pa.phi), pa.r');
                    else
                        [x y] = pol2cart(pa.theta, pa.r'+pa.amp.*sin(ones(1,pa.numberOfDots).*pa.tf.*GetSecs+pa.phi));
                    end
                else
                    x = x;
                    y = y;
                end
                pa.current_stimulus(:,:,fn) = [x'+centerX2, x'+centerX2, y'+centerY2, repelem(pa.dotDiameter,size(x',1),1), repelem(pa.dotColor(1,:),size(x',1),1)];
            end
            
            colors = pa.current_stimulus(:,5:7,fn);
            for view = 0:1 %VP.stereoViews
                Screen('SelectStereoDrawbuffer', VP.window, view);
                pa.dotPosition = [pa.current_stimulus(:,view+1,fn), pa.current_stimulus(:,3,fn)].*VP.pixelsPerMm;
                Screen('DrawDots',VP.window, pa.dotPosition', pa.current_stimulus(:,4,fn), colors', [VP.Rect(3)/2, VP.Rect(4)/2], 2);
                Screen('DrawTexture', VP.window, VP.bg(VP.curBg));
                               
                if pa.timeStamps(whichFn,3) == 1
                    Screen('DrawText', VP.window,'o',VP.Rect(3)./2+VP.centerX-7.1,VP.Rect(4)/2-7,repelem(VP.black,1,3));
                else
                    Screen('DrawText', VP.window,'+',VP.Rect(3)./2+VP.centerX-7.1,VP.Rect(4)/2-7,repelem(VP.black,1,3));
                end
                                
            end
            %%
            
            VP.vbl = Screen('Flip', VP.window, [], dontClear); % Draw frame
            
            % after every frame, calculate how much time has passed since the first frame
            % and calculate which frame should next frame be (if it needs to catch up)
            if fn == 1 && skip == 0 % get time of very first frame and use this as an absolute reference 
                pa.firstFrame = VP.vbl;
                skip = 1;
                pa.timeStamps(whichFn,1) = GetSecs - pa.firstFrame; % time so far
            else
                pa.timeStamps(whichFn,1) = GetSecs - pa.firstFrame;
                fn = round(pa.timeStamps(whichFn,1)/(1/VP.frameRate)); % which frame should it be now
                pa.fn(whichFn,1) = fn;
            end
            whichFn = whichFn +1; %goes to next frame
            % end experiment if time so far is longer than what it's supposed to be           
            if (pa.timeStamps(whichFn,1)>=size(pa.current_stimulus,3)*(1/pa.numFlips))||fn>=size(pa.current_stimulus,3)
                %pause(pa.endDur)
                toc
                Screen('Flip', VP.window, [], dontClear);
                OnGoing = 0; % End experiment
                break;
            end
            
            
    end
    
    % record response 
    [pa, kb, OnGoing] = check_resp(OnGoing,fn,pa,display,kb);
    
end

%% Save your data

save(filename,'pa','VP');

%% Clean up
RestrictKeysForKbCheck([]); % Reenable all keys for KbCheck:
ListenChar; % Start listening to GUI keystrokes again
ShowCursor;
clear moglmorpher;
Screen('CloseAll');%sca;
clear moglmorpher;
Priority(0);
if VP.stereoMode == 8 && display ~=2
    Datapixx('SetPropixxDlpSequenceProgram',0);
    Datapixx('RegWrRd');
end
Datapixx('Close');
toc
end


%% if black and white screen do this
% Datapixx('Open');
% Datapixx('SetPropixxDlpSequenceProgram',0);
% Datapixx('RegWrRd');
% Datapixx('Close');