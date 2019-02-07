function plot_serial(serial, lamdas)
%%
% visualize results from 'serialchoicebias_batch.m'
%
% load data from 'load('Z:\Katsuhisa\learning_project\data\serial.mat')'
% load data from 'load('Z:\Katsuhisa\learning_project\data\lamdas.mat')'
%

close all;
figure;
animals = {'kiwi', 'mango'};
varnames = {'C_{n-1}', 'T_{n-1}', 'W_{n-1}', 'M_{n-1}'};   
lenv = length(varnames);
num_a = zeros(1, 2);
for a = 1:2 % animal
    % animal idx
    ani = serial.matrix(:,1)==a;
    num_a(a) = sum(ani);
    d = 50/a;
    
    if a==1
        % lambda
        subplot(4,4, 1:4:16)
        x = nanmean(lamdas.lambda, 1);
        y = nanmean(lamdas.deviance, 1);
        plot(x, y)
        hold on;
        yy = get(gca, 'YLim');
        lam = x(y==min(y));
        plot(lam*[1 1], yy, '-r')
        text(lam*1.1, yy(1)+0.5*(yy(2)-yy(1)), ['\lambda = ' num2str(lam)], 'color', 'r', 'fontsize', 6)
        xlabel('lambda')
        ylabel('deviance')
        set(gca, 'box', 'off', 'tickdir', 'out')
    end
    
    % cross validation error from stepwise GLM
    subplot(4, 4, [2 + 8*(a-1) 6 + 8*(a-1)])
    mat = nan_remove_pair(serial.matrix(ani, end-(lenv-1):end), [], 'median');
    % stats
    pvals = nan(1, lenv);
    pvals(1) = signrank(mat(:, 1));
    for s = 1:lenv-1
        pvals(s+1) = signrank(mat(:, s), mat(:, s+1));
    end
    % plot
    waterfallchart4mat([mat, mat(:, end)])
    hold on;
    for s = 1:lenv
       if pvals(s) < 0.05/lenv
          text(s-0.1, 1.1*nanmean(mat(:, s)), '*') 
       end
    end
    ylabel({[animals{a} ' (n=' num2str(num_a(a)) ')' ], 'choice correlation'})
    if a==1
        set(gca, 'XTick', 1:lenv, 'XTickLabel', cell(1, lenv))
    else
        set(gca, 'XTick', 1:lenv, 'XTickLabel', varnames)
        xtickangle(45)
    end
    xlim([0.5 lenv+0.5])
    set(gca, 'box', 'off', 'tickdir', 'out')
    
    % serial choice weights
    subplot(4, 4, [3 + 8*(a-1) 7 + 8*(a-1)])
    plot([-1 1], [-1 1], '-', 'color', 0.5*ones(1, 3))
    hold on;
    plot([-1 1], [1 -1], '-', 'color', 0.5*ones(1, 3))
    hold on;
    mapc = parula(num_a(a));
    scatter(serial.matrix(ani, 3), serial.matrix(ani, 4), 10, mapc, 'linewidth', 0.5);
    axis(0.42*[-1 1 -1 1])
    if a==2
        xlabel({'pre choice weight: C_{n-1}'})
    end
    ylabel({'pre stimulus sign weight: T_{n-1}'})
    set(gca, 'XTick', [-0.4 0 0.4])
    set(gca, 'YTick', [-0.4 0 0.4])
    set(gca, 'box', 'off', 'tickdir', 'out')
    
    % serial choice weights
    xl = ones(1, floor(num_a(a)/d) + 1);
    labs = cell(1, floor(num_a(a)/d) + 1);
    begin = 1 + num_a(1)*(a - 1);
    for k = 1:floor(num_a(a)/d)
        xl(k) = 1 + d*(k-1);
        slash = strfind(serial.seslist{begin}, '/');
        labs{k} = serial.seslist{begin}(slash(1)+1:slash(2)-1);
        begin = begin + d;
    end
    xl(end) = num_a(a); 
    slash = strfind(serial.seslist{num_a(1)+(a-1)*num_a(2)}, '/');
    labs{end} = serial.seslist{num_a(1)+(a-1)*num_a(2)}(slash(1)+1:slash(2)-1);
    for k = 1:2
        subplot(4, 4, k*4 + 8*(a-1))
        scatter(1:num_a(a), serial.matrix(ani, 2+k), 10, mapc, 'o', 'linewidth', 0.5);
        if k==1
            ylabel({'C_{n-1}', 'weight'})
            xlabel('sessions')
            set(gca, 'XTick', xl, 'fontsize',7)
        else
            ylabel({'T_{n-1}', 'weight'})
            set(gca, 'XTick', xl, 'XTickLabel', labs, 'fontsize',6)            
        end
        xtickangle(45)
        xlim([0.5 num_a(a)+0.5])
        ylim([-0.42 0.42])
        set(gca, 'YTick', [-0.4 0 0.4])
        set(gca, 'box', 'off', 'tickdir', 'out')
    end
end


    