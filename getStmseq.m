function stmmat = getStmseq(ex, c)
%%
% extract stimulus sequence from ex-file
% INPUT: ex ... ex file
%              c ... 1, hdx; 2, hdx2
%
% OUTPUT: stmmat (all the trials x stimulus sequence):
%
% EXAMPLE: stmmat = getEye(ex, 1);
%

switch c
    case 1
        seq = 'hdx_seq';
    case 2
        seq = 'hdx_seq2';
end
len_alltr = length(ex.Trials);
n = zeros(1, len_alltr);
for i = 1:len_alltr
    n(i) = length(ex.Trials(i).(seq));
end
moden = mode(n);
stmmat = nan(len_alltr, moden);
for i = 1:len_alltr
    v = ex.Trials(i).(seq);
    lenv = length(v);
    if lenv < moden
        stmmat(i, 1:lenv) = v;
        stmmat(i, lenv:end) = v(end);
    elseif lenv > moden
        stmmat(i, :) = v(1:moden);
    else
        stmmat(i, :) = v;
    end
end
