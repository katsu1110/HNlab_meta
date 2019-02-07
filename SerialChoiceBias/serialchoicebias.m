function out = serialchoicebias(behmat, lmode)
%%
% re-analyze serial choice bias
%
% INPUT: 'behmat = getBeh(ex)'
%              lmode ... [0 0] : search for lambda
%                             [1 lambda] use lambda to fit
%
% OUTPUT: out ... if 'lambda' is given ....
%                       ... cc: choice correlation (Pitkow et al., 2015) between model
%                         prediction and actual animals' choice
%                       ... beta: weight of each predictor (first value is intercept) 
%
%                       ... if 'lambda_search' is given ....
%                       ... Lambda: lambda value, Deviance: deviance
%
% GLM:
% ch(t) = b0 + b1*ch(t-1) + b2*stm(t-1) + b3*targetPos(t-1) + b4*outcome(t-1)
% 
% cross-validation: fitting on signal trials, evaluating on no-signal trials
% 

% generate matrix
varnames = {'pre ch', 'pre stm', 'pre outcome', 'pre sacc dir'};
lenv = length(varnames);

% use completed trials after at least one completed trials
prefs = [1; behmat(1:end-1, 4)];
behmat(prefs | behmat(:, 4)==1, :) = [];

% dependent variable
y = behmat(2:end, 11);

% independent variables
X = [behmat(1:end-1, 11), sign(behmat(1:end-1, 6)), behmat(1:end-1, 9), behmat(1:end-1, 12)];
X = zscore(X);

% cross-validation
cvi = behmat(2:end, 5);

% model fitting
switch lmode(1)
    case 0
        % fit using signal trials
        [~, FitInfo] = lassoglm(X(cvi > 0, :), y(cvi > 0), 'binomial', 'link', 'probit', 'CV', 5);
        out.Deviance = FitInfo.Deviance;
        out.Lambda = FitInfo.Lambda;
%         lam = FitInfo.Lambda(FitInfo.Deviance==min(FitInfo.Deviance));
%         out.Lambda = lam(1);
    otherwise
         cc = zeros(1, lenv);
        for i = 1:lenv
            % fit using signal trials
            [B, FitInfo] = lassoglm(X(cvi > 0, 1:i), y(cvi > 0), 'binomial', ...
                'link', 'probit', 'lambda', lmode(2));
            beta = [FitInfo.Intercept; B];
        %     beta = glmfit(X(cvi > 0, 1:i), y(cvi > 0), 'binomial','link','probit');

            % cross correlation as validation score using 0% signal trials
            data = y(cvi == 0);
            pred = glmval(beta, X(cvi == 0, 1:i), 'probit');
        %     [~, ~, ~, auc] = perfcurve(data, pred, 1);
        %     cc(i) = (pi/sqrt(2))*(auc - 0.5);
            sigxy = cov(data, pred);
            sigx = var(data);
            sigy = var(pred);
            alpha = sigxy(1, 2)/sqrt(sigx*sigy - sigxy(1,2)^2);
            cc(i) = alpha/sqrt(1 + alpha^2);
        end
        out.cc = cc;
        out.beta = beta';
end
    