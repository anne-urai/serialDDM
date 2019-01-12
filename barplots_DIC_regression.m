function barplots_DIC_regression()

% Code to fit the history-dependent drift diffusion models described in
% Urai AE, Gee JW de, Donner TH (2018) Choice history biases subsequent evidence accumulation. bioRxiv:251595
%
% MIT License
% Copyright (c) Anne Urai, 2018
% anne.urai@gmail.com

addpath(genpath('~/code/Tools'));
warning off; close all;
global datasets datasetnames mypath

% ============================================ %
% DIC COMPARISON BETWEEN DC, Z AND BOTH
% ============================================ %

% 1. STIMCODING, only prevresps
mdls = {'regress_nohist', ...
    'regress_z_lag1', ...
    'regress_dc_lag1', ...
    'regress_dcz_lag1', ...
    'regress_z_lag2', ...
    'regress_dc_lag2', ...
    'regress_dcz_lag2', ...
    'regress_z_lag3', ...
    'regress_dc_lag3', ...
    'regress_dcz_lag3'};

for d = 1:length(datasets),
    close all;
    subplot(3, 2, 1);
    getPlotDIC(mdls, d);
    title(datasetnames{d});
    set(gca, 'xtick', [1 4 7], 'xticklabel', {'lag 1', 'lag2', 'lag3'}, 'xticklabelrotation', -30);
    ylabel({'\Delta DIC from model'; 'without history'}, 'interpreter', 'tex');
    drawnow; tightfig;
    print(gcf, '-dpdf', sprintf('~/Data/serialHDDM/figure1b_HDDM_DIC_regression_d%d.pdf', d));
end

close all;

end

% ============================================ %
% DIC COMPARISON BETWEEN DC, Z AND BOTH
% ============================================ %

function getPlotDIC(mdls, d)

global datasets mypath colors
colors(3, :) = mean(colors([1 2], :));
colors = repmat(colors, 3, 1);
axis square; hold on;

mdldic = nan(1, length(mdls));
for m = 1:length(mdls),
    
    if ~exist(sprintf('%s/summary/%s/%s_all.mat', ...
            mypath, datasets{d}, mdls{m}), 'file'),
        disp('cant find this model')
        continue;
    end
    
    load(sprintf('%s/summary/%s/%s_all.mat', ...
        mypath, datasets{d}, mdls{m}));
    
    if (isnan(dic.full) || isempty(dic.full)) && ~all(isnan(dic.chains)),
        dic.full = nanmean(dic.chains);
    end
    mdldic(m) = dic.full;
end

% everything relative to the full model
mdldic = bsxfun(@minus, mdldic, mdldic(1));
mdldic = mdldic(2:end);
[~, bestMdl] = min(mdldic);

for i = 1:length(mdldic),
    b = bar(i, mdldic(i), 'facecolor', colors(i, :), 'barwidth', 0.6, 'BaseValue', 0, ...
        'edgecolor', 'none');
end

%# Add a text string above/below each bin
for i = 1:length(mdldic),
    if mdldic(i) < 0,
        text(i, mdldic(i) + 0.12*range(get(gca, 'ylim')), ...
            num2str(round(mdldic(i))), ...
            'VerticalAlignment', 'top', 'FontSize', 4, 'horizontalalignment', 'center', 'color', 'w');
    elseif mdldic(i) > 0,
        text(i, mdldic(i) + 0.12*range(get(gca, 'ylim')), ...
            num2str(round(mdldic(i))), ...
            'VerticalAlignment', 'top', 'FontSize', 4, 'horizontalalignment', 'center', 'color', 'w');
    end
end
axis square; axis tight;
xlim([0.5 length(mdldic)+0.5]);
offsetAxes; box off;
set(gca, 'color', 'none');
set(gca, 'xcolor', 'k', 'ycolor', 'k');

end