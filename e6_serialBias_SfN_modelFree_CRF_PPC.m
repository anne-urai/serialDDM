function e6_serialBias_SfN_modelFree_CRF_PPC

% Code to fit the history-dependent drift diffusion models described in
% Urai AE, Gee JW de, Donner TH (2018) Choice history biases subsequent evidence accumulation. bioRxiv:251595
%
% MIT License
% Copyright (c) Anne Urai, 2018
% anne.urai@gmail.com

% ========================================== %
% conditional response functions from White & Poldrack
% run on simulated rather than real data
% ========================================== %

addpath(genpath('~/code/Tools'));
warning off; close all; clear;
global datasets datasetnames mypath colors
useBiasedSj = 1; % select only the most biased subjects
cutoff_quantile = 3;
whichModels = 1;

for qidx = 1,
    
    switch qidx
        case 1
            qntls = [0.1, 0.3, 0.5, 0.7, 0.9]; % Leite & Ratcliff
        case 2
            qntls = [0.5 1];
    end
    
    switch whichModels
        case 1
            models = {'data', 'stimcoding_nohist', 'stimcoding_dc_z_prevresp'};
            thesecolors = {[0 0 0], [0.5 0.5 0.5], mean(colors([1 2], :))};
        case 2
            models = {'data', 'stimcoding_z_prevresp', 'stimcoding_dc_z_prevresp'};
            thesecolors = {[0 0 0],  colors(1, :), mean(colors([1 2], :))};
    end
    
    allds.fast  = nan(length(datasets), length(models));
    allds.slow = nan(length(datasets), length(models));
    
    for d = 1:length(datasets);
        
        % plot
        close all;
        subplot(441); hold on;
        
        for m = 1:length(models),
            
            switch models{m}
                case 'data'
                    filename = dir(sprintf('%s/%s/*.csv', mypath, datasets{d}));
                    alldata  = readtable(sprintf('%s/%s/%s', mypath, datasets{d}, filename.name));

                otherwise
                    if ~exist(sprintf('%s/summary/%s/%s_ppc_data.csv', mypath, datasets{d}, models{m}), 'file'),
                        continue;
                    else
                        fprintf('%s/summary/%s/%s_ppc_data.csv \n', mypath, datasets{d}, models{m});
                    end
                    % load simulated data - make sure this has all the info we need
                    alldata    = readtable(sprintf('%s/summary/%s/%s_ppc_data.csv', mypath, datasets{d}, models{m}));
                    alldata    = sortrows(alldata, {'subj_idx'});
                    
                    alldata.rt          = abs(alldata.rt_sampled);
                    alldata.response    = alldata.response_sampled;
            end
            
            if ~any(ismember(alldata.Properties.VariableNames, 'transitionprob'))
                alldata.transitionprob = zeros(size(alldata.subj_idx));
            else
                assert(nanmean(unique(alldata.transitionprob)) == 50, 'rescale units');
                alldata = alldata(alldata.transitionprob == tps(tp), :);
            end
            
            % make sure to use absolute RTs!
            alldata.rt = abs(alldata.rt);
            
            % recode into repeat and alternate for the model
            alldata.repeat = zeros(size(alldata.response));
            alldata.repeat(alldata.response == (alldata.prevresp > 0)) = 1;
            
            % for each observers, compute their bias
            [gr, sjs] = findgroups(alldata.subj_idx);
            sjrep = splitapply(@nanmean, alldata.repeat, gr);

            % who are the repeating observers?
            sjrep = sjs(sjrep < 0.5);
            
            % recode into biased and unbiased choices
            alldata.biased = alldata.repeat;
            altIdx = ismember(alldata.subj_idx, sjrep);
            alldata.biased(altIdx) = double(~(alldata.biased(altIdx))); % flip

            if useBiasedSj,

                 switch models{m}
                 case 'data'
                % for this plot, use only the most extremely biased observers (see email Tobi 23 August)
                    sjbias = splitapply(@nanmean, alldata.biased, gr);

                    if cutoff_quantile == 2,
                        cutoff = median(sjbias);
                    elseif cutoff_quantile == 0,
                        cutoff = 0; % keep everyone!
                    else
                       cutoff = quantile(sjbias, cutoff_quantile);
                    end
                    cutoff = quantile(sjbias, cutoff_quantile);
                    usesj = sjs(sjbias > cutoff(end)); % only take the subjects who are in the highest quantile
                end
                
                alldata = alldata(ismember(alldata.subj_idx, usesj), :);
            end
            
            % ignore if coherence is present but doesn't contain unique values
            if ismember('coherence', alldata.Properties.VariableNames),
                if length(unique(alldata.coherence(~isnan(alldata.coherence)))) == 1,
                    alldata.coherence = [];
                end
            end
            
            % divide RT into quantiles for each subject
            discretizeRTs = @(x) {discretize(x, quantile(x, [0, qntls]))};
            alldata(isnan(alldata.rt), :) = [];
            
            % when there were multiple levels of evidence, do these plots
            % separately for each level
            if ~any(ismember('coherence', alldata.Properties.VariableNames))
                
                rtbins = splitapply(discretizeRTs, alldata.rt, findgroups(alldata.subj_idx));
                alldata.rtbins = cat(1, rtbins{:});
                
                % get RT quantiles for choices that are in line with or against the bias
                [gr, sjidx, rtbins] = findgroups(alldata.subj_idx, alldata.rtbins);
                cpres               = array2table([sjidx, rtbins], 'variablenames', {'subj_idx', 'rtbin'});
                cpres.choice        = splitapply(@nanmean, alldata.biased, gr); % choice proportion
                
                % make into a subjects by rtbin matrix
                mat = unstack(cpres, 'choice', 'rtbin');
                mat = mat{:, 2:end}; % remove the last one, only has some weird tail
                
            else
                disp('splitting by coherence first');
                
                [gr, sj, coh] = findgroups(alldata.subj_idx, alldata.coherence);
                rtbins = splitapply(discretizeRTs, alldata.rt, gr);
                alldata.rtbins = cat(1, rtbins{:});
                
                % get RT quantiles for choices that are in line with or against the bias
                [gr, sjidx, rtbins, coh] = findgroups(alldata.subj_idx, alldata.rtbins, alldata.coherence);
                cpres               = array2table([sjidx, rtbins, coh], 'variablenames', {'subj_idx', 'rtbin', 'coh'});
                cpres.choice        = splitapply(@nanmean, alldata.biased, gr); % choice proportion
                
                sjs = unique(cpres.subj_idx);
                mat = nan(length(sjs), max(cpres.rtbin));
                for sj = 1:length(sjs),
                    for r = 1:max(cpres.rtbin);
                        mat(sj, r) = nanmean(cpres.choice(cpres.subj_idx == sjs(sj) & cpres.rtbin == r));
                    end
                end
            end
            
            % biased choice proportion
            switch models{m}
                case 'data'
                    disp(size(mat))
                    % ALSO ADD THE REAL DATA WITH SEM
                    h = ploterr(qntls, nanmean(mat, 1), [], ...
                       1.96* nanstd(mat, [], 1) ./ sqrt(size(mat, 1)), 'k', 'abshhxy', 0);
                    set(h(1), 'color', 'k', 'marker', 'o', ...
                        'markerfacecolor', 'w', 'markeredgecolor', 'k', 'linewidth', 0.5, 'markersize', 3, ...
                        'linestyle', '-');
                    set(h(2), 'linewidth', 0.5);
                otherwise
                    plot(qntls, nanmean(mat, 1), 'color', thesecolors{m}, 'linewidth', 1);
            end
            
            % SAVE
            avg = nanmean(mat, 1);
            
            try
                allds.fast(d, m) = nanmean(avg(1:2));
                allds.slow(d, m) = nanmean(avg(end-3:end));
            catch % median split, only 2 bins
                % this is what we'll use for the summary figure 3c
                allds.fast(d, m) = nanmean(avg(1));
                allds.slow(d, m) = nanmean(avg(2));
            end
           % allds.all(d, m, :) = avg;
        end
        %  end
        
        axis tight; box off;
        set(gca, 'xtick', qntls);
        set(gca,  'ylim', [0.5 max(get(gca, 'ylim'))]);

        axis square;  offsetAxes;
        xlabel('RT (quantiles)');
        set(gca, 'xcolor', 'k', 'ycolor', 'k');
        ylabel('P(bias)');
        title(datasetnames{d});
        tightfig;
        set(gca, 'xcolor', 'k', 'ycolor', 'k');
        
        switch qidx
            case 1
                print(gcf, '-dpdf', sprintf('~/Data/serialHDDM/CRF_PPC_d%d_quantiles_sjCutoff%d_whichModels%d.pdf', d, cutoff_quantile, whichModels));
            case 2
                print(gcf, '-dpdf', sprintf('~/Data/serialHDDM/CRF_PPC_d%d_median.pdf', d));
        end
    end
end
savefast(sprintf('~/Data/serialHDDM/allds_cbfs.mat'), 'allds');

%% ========================================== %
% PLOT ACROSS DATASETS
% ========================================== %

load(sprintf('~/Data/serialHDDM/allds_cbfs.mat'));
periods = {'fast', 'slow'};

for p  = 1:2,
    close all;
    subplot(3,3,1); hold on;
    
    plot([1 5], [nanmean(allds.(periods{p})(:, 5)) nanmean(allds.(periods{p})(:, 5))], '--k');
    lower =  nanmean(allds.(periods{p})(:, 5)) -  nanstd(allds.(periods{p})(:, 5)) ./ sqrt(length(datasets));
    plot([1 5], [lower lower], ':k');
    upper =  nanmean(allds.(periods{p})(:, 5)) +  nanstd(allds.(periods{p})(:, 5)) ./ sqrt(length(datasets));
    plot([1 5], [upper upper], ':k');
    
    
    for b = 1:4,
        bar(b, nanmean(allds.(periods{p})(:, b+1)), 'edgecolor', 'none', ...
            'facecolor', thesecolors{b+1}, 'basevalue', 0.5, 'barwidth', 0.6);
    end
    
    % now the data
    b = ploterr(5, nanmean(allds.(periods{p})(:, 5)), [], ...
        nanstd(allds.(periods{p})(:, 5)) ./ sqrt(length(datasets)), ...
        'ko', 'abshhxy', 0);
    set(b(1), 'markerfacecolor', 'k', 'markeredgecolor', 'w', 'markersize', 6);
    
    ylabel(sprintf('P(bias) on %s trials', periods{p}));
    set(gca, 'xtick', 1:5, 'xticklabel', {'No history', 'z', 'v_{bias}', 'Both', 'Data'}, ...
        'xticklabelrotation', -30);
    axis square; axis tight;
    % set(gca, 'ytick', [0.5:0.01:0.54], 'ylim', [0.5 0.545]);
    offsetAxes;
    title('All datasets');
    
    tightfig;
    set(gca, 'ycolor', 'k', 'xcolor', 'k');
    print(gcf, '-dpdf', sprintf('~/Data/serialHDDM/CRF_qual_%s.pdf', periods{p}));
end
end
