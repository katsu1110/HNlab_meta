function eyedata = getEye(ex, c)
%%
% get eye data from ex-file
% INPUT: ex ... ex file
%              c ... 1, for fixation task; 2, for task with choice
%
% OUTPUT: eyedata ... structure containing relevant info
%
% EXAMPLE: eyedata = getEye(ex);
%

% deal with inputs
if nargin < 2; c = 2; end

% session basic info
len_alltr = length(ex.Trials);
tr = find(abs([ex.Trials.Reward]) > 0);
try
    label_seq = label4StmPerTr(ex);
catch
    label_seq = ones(1, len_alltr);
end

% old time or new time of ex-file structure
if isfield(ex.Trials(1),'TrialStart_remappedGetSecs')
      time = 'N';   % new
elseif ~isfield(ex.Trials(1),'TrialStart_remappedGetSecs')...
        && isfield(ex.Trials(1),'TrialStartDatapixx')...
        && isfield(ex.Trials(1).times, 'lastEyeReadingDatapixx')
      time = 'O';   % old
else
    time = 'C';    % classic
end

% gain of eye calibration
if isfield(ex.eyeCal,'RXGain') && isfield(ex.eyeCal,'LXGain')
   rgain = [ex.eyeCal.RXGain; ex.eyeCal.RYGain];
   lgain = [ex.eyeCal.LXGain; ex.eyeCal.LYGain];
   again = nanmean([rgain, lgain], 2);
elseif isfield(ex.eyeCal,'RXGain') && ~isfield(ex.eyeCal,'LXGain')
         again = [ex.eyeCal.RXGain; ex.eyeCal.RYGain];
elseif ~isfield(ex.eyeCal,'RXGain') && isfield(ex.eyeCal,'LXGain')
        again = [ex.eyeCal.LXGain; ex.eyeCal.LYGain];
else
    again = [ex.eyeCal.XGain; ex.eyeCal.YGain];
end
% adjust spurious gains 
if again(1) > 300 || isnan(again(1))
    again(1) = 300;
end
if again(2) > 300 || isnan(again(2))
    again(2) = 300;
end
if again(1) < 200
    again(1) = 200;
end
if again(2) < 200
    again(2) = 200;
end

% offset position
if isfield(ex.eyeCal,'Delta')
   pos0 = [mean([ex.eyeCal.Delta.RX0]) mean([ex.eyeCal.Delta.RY0])];
elseif isfield(ex.eyeCal,'RX0')
    pos0 = [ex.eyeCal.RX0 ex.eyeCal.RY0];
else
    pos0 = [ex.eyeCal.X0 ex.eyeCal.Y0];
end

% degree per pixels
if isfield(ex,'setup')
    if ex.setup.monitorWidth==56
        screenNum = 1;
    else
        screenNum = 2;                
    end
else
    screenNum = ex.screen_number;
end
        
if screenNum==1
        dpp = 0.0167;
elseif screenNum==2
        dpp = 0.0117;
end

% extract eye data
eyedata.gain = again;
eyedata.trlabel = label_seq;
eyedata.x = [];
eyedata.y = [];
eyedata.p = [];
unilab = unique(label_seq);
lenuni = length(unilab) - 1;
eyec = 0;
for i = 1:len_alltr            
    % timing of start and end of stimulus presentation
    try
        if time == 'N'
            t = ex.Trials(i).Eye.t(1:ex.Trials(i).Eye.n)-ex.Trials(i).TrialStartDatapixx;
            st = ex.Trials(i).Start - ex.Trials(i).TrialStart_remappedGetSecs;            

            % get the timing of start and end of stimulus
            [~,stpos] = min(abs(t-st(1)));
            [~,enpos] = min(abs(t-st(end))); 
            
            % start fixation
            [~, startfix] = min(abs(t-(ex.Trials(i).times.startFixation-ex.Trials(i).TrialStart_remappedGetSecs)));
            
            % choice saccade, if any
            if c==2
                [~, fpoffpos] = min(abs(t-(ex.Trials(i).times.fpOff-ex.Trials(i).TrialStart_remappedGetSecs)));
                [~, chpos] = min(abs(t-(ex.Trials(i).times.choice-ex.Trials(i).TrialStart_remappedGetSecs)));
            end            
        elseif time == 'O'
            delta = Trials(tr(i)).Eye.t(ex.Trials(i).Eye.n) - ex.Trials(i).TrialStartDatapixx - ex.Trials(i).times.lastEyeReading;
            t = ex.Trials(i).Eye.t(1:ex.Trials(i).Eye.n)-ex.Trials(i).TrialStartDatapixx-delta;
            st = ex.Trials(i).Start - ex.Trials(i).TrialStart;

            [~,stpos] = min(abs(t-st(1)));
            [~,enpos] = min(abs(t-st(end)));
            [~, startfix] = min(abs(t-(ex.Trials(i).times.startFixation-ex.Trials(i).fpOn)));
            
            if c==2
                [~,fpoffpos] = min(abs(t-(ex.Trials(i).times.fpOff-ex.Trials(i).times.startFixation)));
                [~,chpos] = min(abs(t-(ex.Trials(i).times.choice-ex.Trials(i).times.startFixation)));
            end
         elseif time == 'C'
             stpos = floor(ex.Trials(i).times.startFixation*sampRate);
             enpos = floor((ex.Trials(i).Start(end) - ex.Trials(i).Start(1))*sampRate);
             startfix = 1;
             fpoffpos = 1;
             chpos = 1;
        end
    catch
        stpos = 1;
        enpos = 1;
        startfix = 1;
        fpoffpos = 1;
        chpos = 1;
    end    
    if isempty(enpos) || isnan(enpos)
        enpos = ex.Trials(i).Eye.n;
    end
    
    % eye data (binocular)
    nonan = ~isnan(ex.Trials(i).Eye.v(1,:));
    xr = ex.Trials(i).Eye.v(1, nonan);
    yr = ex.Trials(i).Eye.v(2, nonan);
    psr = ex.Trials(i).Eye.v(3, nonan);
    xl = ex.Trials(i).Eye.v(4, nonan);
    yl = ex.Trials(i).Eye.v(5, nonan);
    psl = ex.Trials(i).Eye.v(6, nonan);
    
    % centerize
    xr = (xr - pos0(1))*again(1)*dpp;
    yr = (yr - pos0(2))*again(2)*dpp;
    xl = (xl - pos0(1))*again(1)*dpp;
    yl = (yl - pos0(2))*again(2)*dpp;
    
    veclensofar = length(eyedata.x);
    eyedata.x = [eyedata.x, eyex];
    eyedata.y = [eyedata.y, eyey];
    eyedata.p = [eyedata.p, eyep];
    
    % reward, timing
    if c==2 || lenuni < 4 % one stimulus per trial
        eyedata.reward(i) = ex.Trials(i).Reward;
        eyedata.trstartidx(i) = veclensofar + 1;
        eyedata.startfixidx(i) = veclensofar + 1 + startfix;
        eyedata.stmstartidx(i) = veclensofar + 1 + stpos;
        eyedata.trstopidx(i) = veclensofar + length(eyex);    
        eyedata.stmstopidx(i) = veclensofar + 1 + enpos;
    else % four stimulus per trial
        if ismember(label_seq(i), [0, 1]) 
            eyec = eyec + 1;
            eyedata.reward(eyec) = ex.Trials(i).Reward;
            eyedata.trstartidx(eyec) = veclensofar + 1;
            eyedata.startfixidx(eyec) = veclensofar + 1 + startfix;
            eyedata.stmstartidx(eyec) = veclensofar + 1 + stpos;
            eyedata.trstopidx(eyec) = veclensofar + length(eyex);    
            eyedata.stmstopidx(eyec) = veclensofar + 1 + enpos;
        else
            eyedata.reward(eyec) = ex.Trials(i).Reward;
            eyedata.trstopidx(eyec) = veclensofar + length(eyex);    
            eyedata.stmstopidx(eyec) = veclensofar + 1 + enpos;
        end
    end
    
    if c==2
        % stimulus, choice, reaction time
        eyedata.ch(i) = 0;
        if isfield(ex.Trials(i), 'Dc')
            eyedata.dc(i) = ex.Trials(i).Dc;
        else
            eyedata.dc(i) = nan;
        end
        if isfield(ex.Trials(i), 'hdx')
            eyedata.hdx(i) = ex.Trials(i).hdx;
            if (ex.Trials(i).hdx < 0 && ex.Trials(i).Reward==-1) || ...
                    (ex.Trials(i).hdx > 0 && ex.Trials(i).Reward==1)
                eyedata.ch(i) = 1;
            elseif (ex.Trials(i).hdx < 0 && ex.Trials(i).Reward==1) || ...
                    (ex.Trials(i).hdx > 0 && ex.Trials(i).Reward==-1)
                eyedata.ch(i) = -1;
            end
        else
            eyedata.hdx(i) = nan;
        end
        if isfield(ex.Trials(i), 'or')
            eyedata.or(i) = ex.Trials(i).or;
            if (ex.Trials(i).or < 45 && ex.Trials(i).Reward==-1) || ...
                    (ex.Trials(i).or > 45 && ex.Trials(i).Reward==1)
                eyedata.ch(i) = 1;
            elseif (ex.Trials(i).or < 45 && ex.Trials(i).Reward==1) || ...
                    (ex.Trials(i).or > 45 && ex.Trials(i).Reward==-1)
                eyedata.ch(i) = -1;
            end
        else
            eyedata.or(i) = nan;
        end
        eyedata.rt(i) = ex.Trials(i).times.choice - ex.Trials(i).times.fpOff;
        % choice vector
        eyedata.choicevec(i).x = eyex(fpoffpos:chpos) - nanmean(eyex(stpos:enpos));
        eyedata.choicevec(i).y = eyey(fpoffpos:chpos) - nanmean(eyey(stpos:enpos));
    end
end 