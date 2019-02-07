function behmat = getBeh(ex)
%%
% generate behavioral matrix from ex-file
% INPUT: ex ... ex file
%
% OUTPUT: behmat (all the trials x params):
% 1, session number 
% 2, trial number
% 3, cued side (0: left, 1: right)
% 4, fixation break (1: yes, 0: no)
% 5, Dc
% 6, hdx
% 7, Dc2
% 8, hdx2
% 9, correct (1) or error (0) 
% 10, reward size
% 11, choice (1: far, 0: near) 
% 12, saccade direction (1: down, 0: up)
% 13, RT
% 14, available reward size (0: small, 1: medium, 2: large) 
%
% EXAMPLE: behmat = getEye(ex);
%

% session basic info
len_alltr = length(ex.Trials);

% initialize matrix
behmat = nan(len_alltr, 14);

% trial number
behmat(:, 2) = 1:len_alltr;

% fixation break
behmat(:, 4) = 1*([ex.Trials.Reward] == 0);

% Dc
behmat(:, 5) = [ex.Trials.Dc];

% hdx
behmat(:, 6) = [ex.Trials.hdx];


if isfield(ex.Trials, 'Dc2')
    % cued side
    behmat(:, 3) = 1*([ex.Trials.x0] > 0);

    % Dc2
    behmat(:, 7) = [ex.Trials.Dc2];

    % hdx2
    behmat(:, 8) = [ex.Trials.hdx2];
end

% correct
behmat(:, 9) = [ex.Trials.Reward];
behmat(behmat(:, 9)==0, 9) = nan;
behmat(behmat(:, 9)==-1, 9) = 0;

% reward size
behmat(:, 10) = [ex.Trials.RewardSize];

% saccade direction
behmat(:, 12) = [ex.Trials.RespDir];

tr = find(behmat(:, 4)==0);
behmat(:, 14) = 0;
for i = 1:length(tr)
    % choice
    if (ex.Trials(tr(i)).hdx > 0 && ex.Trials(tr(i)).Reward==1) || ...
            (ex.Trials(tr(i)).hdx < 0 && ex.Trials(tr(i)).Reward==-1)
        behmat(tr(i), 11) = 1;
    elseif (ex.Trials(tr(i)).hdx < 0 && ex.Trials(tr(i)).Reward==1) || ...
            (ex.Trials(tr(i)).hdx > 0 && ex.Trials(tr(i)).Reward==-1)
        behmat(tr(i), 11) = 0;
    end
    
    % reaction time
    behmat(tr(i), 13) = ex.Trials(tr(i)).times.choice - ex.Trials(tr(i)).times.fpOff;
    
    % available reward size
    if i > 2
        behmat(tr(i-1)+1:tr(i)-1, 14) = behmat(tr(i-1), 14);
    end
    if i > 3
        if behmat(tr(i-2), 9)==1 && behmat(tr(i-1), 9)==1
            behmat(tr(i), 14) = 1;
            if i > 4 && behmat(tr(i-3), 9)==1
                behmat(tr(i), 14) = 2;
            end
        end
    end
end
