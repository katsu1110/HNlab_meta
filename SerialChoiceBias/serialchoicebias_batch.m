function serial = serialchoicebias_batch
%%
% perform ' serialchoicebias.m' in batch given the list of sessions

% path
if ispc
    mypath = 'Z:/';
else
    mypath = '/gpfs01/nienborg/group/';
end

% kiwi list
load([mypath 'Katsuhisa/pupil_project/dataset/kiwi/analysis/list_ki_dxall.mat'])

% mango list
load([mypath 'Katsuhisa/pupil_project/dataset/mango/analysis/list_ma_dxall.mat'])

lists = {list_ki_dxall, list_ma_dxall};
lenl = length(lists);
listsconcat = [list_ki_dxall, list_ma_dxall];
lenses = [length(list_ki_dxall), length(list_ma_dxall)];

% initialize
serial.varnames = {'animal_id', 'w intercept', 'w pre ch', 'w pre stm', 'w pre outcome', 'w pre sacc dir', ...
    'cc pre ch', 'cc pre stm', 'cc pre outcome', 'cc pre sacc dir'};
lenv = length(serial.varnames);

% %%
% % find lambda
% sesdev = cell(1, sum(lenses));
% seslam = cell(1, sum(lenses));
% disp('looking for lambda ...')
% parfor i = 1:sum(lenses)
%     try
%         % load ex
%         ex = load([mypath 'Katsuhisa/data/' listsconcat{i}], 'ex');
% 
%         % behavior
%         behmat = getBeh(ex.ex);
% 
%         % model fit
%         out = serialchoicebias(behmat, [0 0]);        
% 
%         % assign
%         sesdev{i} = out.Deviance;
%         seslam{i} = out.Lambda;
%         cand = out.Lambda(out.Deviance==min(out.Deviance));
%         disp([num2str(cand(1)) ': ' listsconcat{i}])
%     catch
%          disp(['Err : ' listsconcat{i}])
%         continue
%     end
% end
% lamdas.deviance = nan(sum(lenses), 100);
% lamdas.lambda = nan(sum(lenses), 100);
% for i = 1:sum(lenses)
%     lamdas.deviance(i, :) = sesdev{i};
%     lamdas.lambda(i, :) = seslam{i};
% end
% x = nanmean(lamdas.lambda, 1);
% y = nanmean(lamdas.deviance, 1);
% lam = x(y==min(y));
% disp(['found lambda: ' num2str(lam)])
% disp('----------------------------')
% 
% % autosave
% save([mypath 'Katsuhisa/learning_project/data/lamdas.mat'], 'lamdas', '-v7.3')

%%
lam = 0.01022;
serial.matrix = nan(sum(lenses), lenv);
serial.seslist = cell(1, sum(lenses));
c = 1;
for l = 1:lenl
    % initialization
    ani_list = lists{l};
    sesdata = cell(1, lenses(l));
    seslist = cell(1, lenses(l));
    
    % model fitting
    parfor i = 1:lenses(l)
        try
            % load ex
            ex = load([mypath 'Katsuhisa/data/' ani_list{i}], 'ex');

            % behavior
            behmat = getBeh(ex.ex);

            % model fit
            out = serialchoicebias(behmat, [1 lam]);

            % assign
            sesdata{i} = [l, out.beta, out.cc];
            seslist{i} = ani_list{i};
            disp(['stored! ' ani_list{i}]);
        catch
            disp(['Err: '  ani_list{i}]);
        end
    end
    % re-assign
    for i = 1:lenses(l)
        try
           serial.seslist{c} = seslist{i};
           serial.matrix(c, :) = sesdata{i};
        catch
            continue
        end
       c = c + 1;
    end
end

% autosave
save([mypath 'Katsuhisa/learning_project/data/serial.mat'], 'serial', '-v7.3')
disp('saved!')