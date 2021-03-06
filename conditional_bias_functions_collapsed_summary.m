function conditional_bias_functions_collapsed_summary
	
% Code to fit the history-dependent drift diffusion models as described in
% Urai AE, de Gee JW, Tsetsos K, Donner TH (2019) Choice history biases subsequent evidence accumulation. eLife, in press.
%
% MIT License
% Copyright (c) Anne Urai, 2019
% anne.urai@gmail.com

global colors
thesecolors = {[0 0 0], colors(1, :), colors(2, :), colors(3, :)};

load(sprintf('~/Data/serialHDDM/allds_cbfs_mediansplit.mat'));
periods    = {'fast', 'slow'};
modelnames = regexprep(regexprep(regexprep(models, 'stimcoding_', ''), '_', ' '), 'prevresp', '');
close all; 
subplot(3,7,1); hold on;

for p = 1:2,
    for m = 2:length(models),
    	xpos = p+(m-1.3)*0.25
        bar(xpos, nanmean(allds.(periods{p})(:, m)), 'edgecolor', 'none', ...
            'facecolor', thesecolors{m}, 'basevalue', 0.5, 'barwidth', 0.23);
    end
end

dat = [allds.fast(:, 1) allds.slow(:, 1)];

% now the data on top
% compute the bootstrapped 95% CI 
ebar_ci = bootci(5000, @mean, dat);
ebar_ci_sem = {ebar_ci(1, :), ebar_ci(2, :)}; % CI based on bootstrap
ebar_ci_sem = nanstd(dat) ./ sqrt(size(dat, 1)) * 1.96; % CI based on s.e.m.
            
h = ploterr([1 2], nanmean(dat), [], ebar_ci_sem, 'abshhxy', 0);
set(h(1), 'color', 'k', 'marker', 'o', ...
    'markerfacecolor', 'w', 'markeredgecolor', 'k', 'linewidth', 0.5, 'markersize', 3, ...
    'linestyle', 'none');
set([h(2)], 'linewidth', 0.5, 'color', 'k');
            
ylabel('Choice bias (fraction)'); xlabel('Response time');
set(gca, 'xtick', [1.4 2.4], 'xticklabel', periods);
% title(sprintf('Model %s', modelnames{m}));
axis tight; disp(get(gca, 'ylim'));
%ylim([0.5 0.55]);
offsetAxes;
%if m > 2, set(gca, 'yticklabel', []); end
set(gca, 'ycolor', 'k', 'xcolor', 'k');
tightfig;
print(gcf, '-dpdf', sprintf('~/Data/serialHDDM/CBF_barplot_summary.pdf'));

end

