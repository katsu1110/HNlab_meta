function [EyeX, EyeY, EyeP] = getEyedata(ex, smoothing)
%%
% get eye data from ex-file
% INPUT: ex ... ex file
%        smoothing ... 0, raw 1, smoothing 
%  (signal reconstruction from velocity for eye positions and bandpass
%  filtering for pupil size)
%
% OUTPUT: EyeX, EyeY, EyeP ... horizontal, vertical positions, and pupil
%         size (trials x time)
%
% NOTE: - only completed trials are used and only eye data during stimulus
%       presentation are stored
%       - sampling rate is 500 Hz
%
% EXAMPLE: eyedata = getEye(ex);
%

if nargin < 2; smoothing = 1; end

% only use completed trials
Trials = ex.Trials(abs([ex.Trials.Reward]) > 0);
len_tr = length(Trials);

% old time or new time of ex-file structure
if isfield(Trials(1),'TrialStart_remappedGetSecs')
      time = 'N';   % new
elseif ~isfield(Trials(1),'TrialStart_remappedGetSecs')...
        && isfield(Trials(1),'TrialStartDatapixx')...
        && isfield(Trials(1).times, 'lastEyeReadingDatapixx')
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
Fs = 500; % 500 Hz
stmdur = ceil(Trials(1).Start(end)-Trials(1).Start(1));
eyedata.x = []; eyedata.y = []; eyedata.p = [];
for i = 1:len_tr            
    % timing of start and end of stimulus presentation
    if time == 'N'
        t = Trials(i).Eye.t(1:Trials(i).Eye.n)-Trials(i).TrialStartDatapixx;
        st = Trials(i).Start - Trials(i).TrialStart_remappedGetSecs;            

        % get the timing of start and end of stimulus
        [~,stpos] = min(abs(t-st(1)));
        [~,enpos] = min(abs(t-st(end)));         
    elseif time == 'O'
        delta = Trials(i).Eye.t(Trials(i).Eye.n) - Trials(i).TrialStartDatapixx - Trials(i).times.lastEyeReading;
        t = Trials(i).Eye.t(1:Trials(i).Eye.n)-Trials(i).TrialStartDatapixx-delta;
        st = Trials(i).Start - Trials(i).TrialStart;

        [~,stpos] = min(abs(t-st(1)));
        [~,enpos] = min(abs(t-st(end)));
    elseif time == 'C'
         stpos = floor(Trials(i).times.startFixation*sampRate);
         enpos = floor((Trials(i).Start(end) - Trials(i).Start(1))*sampRate);
    end
 
    if isempty(enpos) || isnan(enpos)
        enpos = Trials(i).Eye.n;
    end
    
    % eye data (monocular)
    nonan = ~isnan(Trials(i).Eye.v(1,:));
    try
        eyex = mean(Trials(i).Eye.v([1 4], nonan), 1);
        eyey = mean(Trials(i).Eye.v([2 5], nonan), 1);
        eyep = mean(Trials(i).Eye.v([3 6], nonan), 1);
    catch
        eyex = Trials(i).Eye.v(1, nonan);
        eyey = Trials(i).Eye.v(2, nonan);
        eyep = Trials(i).Eye.v(3, nonan);
    end
    eyex = (eyex - pos0(1))*again(1)*dpp;
    eyey = (eyey - pos0(2))*again(2)*dpp;
    
    % concatenation
    veclensofar = length(eyedata.x);
    eyedata.x = [eyedata.x, eyex];
    eyedata.y = [eyedata.y, eyey];
    eyedata.p = [eyedata.p, eyep];
    
    % timing info
    eyedata.trstartidx(i) = veclensofar + 1;
    eyedata.stmstartidx(i) = veclensofar + 1 + stpos;
    eyedata.trstopidx(i) = veclensofar + length(eyex);    
    eyedata.stmstopidx(i) = veclensofar + 1 + enpos; 
end 

% smoothing
if smoothing
    % reconstruction from velocity (Engbert & Mergenthaler, 2006)
    eyedata.x = smooth_eye(eyedata.x, Fs);
    eyedata.y = smooth_eye(eyedata.y, Fs);
    
    % bandpass filtering
    dim = 2; cutoff = [0.01 10]; % Urai et al., 2017
    [B, A] = butter(dim, 2*cutoff/Fs);
    eyedata.p = filter(B, A, eyedata.p);
end

% reassignment
EyeX = nan(len_tr, Fs*stmdur);
EyeY = nan(len_tr, Fs*stmdur);
EyeP = nan(len_tr, Fs*stmdur);
for i = 1:len_tr
    sig = eyedata.x(eyedata.stmstartidx(i):eyedata.stmstopidx(i));
    EyeX(i,:) = interp1(1:length(sig), sig, 1:Fs*stmdur);
    sig = eyedata.y(eyedata.stmstartidx(i):eyedata.stmstopidx(i));
    EyeY(i,:) = interp1(1:length(sig), sig, 1:Fs*stmdur);
    sig = eyedata.p(eyedata.stmstartidx(i):eyedata.stmstopidx(i));
    EyeP(i,:) = interp1(1:length(sig), sig, 1:Fs*stmdur);
end

% subfunctions
function e = smooth_eye(e, samplingRate)
% reconstruct eye-positions from velocities
len_eye = length(e);
vel = zeros(1,len_eye);
for i = 3:len_eye-2
      vel(i) = samplingRate*(e(i+2)+e(i+1)-e(i-1)-e(i-2))/6;
end

% reconstruct eye position
e = e(1) + cumsum(vel, 2)/samplingRate;