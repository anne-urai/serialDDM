function e1_serialBias_SfN_DIC()

  addpath(genpath('~/code/Tools'));
  warning off; close all;
  global datasets datasetnames


  set(groot, 'defaultaxesfontsize', 6, 'defaultaxestitlefontsizemultiplier', 1, ...
  'defaultaxestitlefontweight', 'bold', ...
  'defaultfigurerenderermode', 'manual', 'defaultfigurerenderer', 'painters', ...
  'DefaultAxesBox', 'off', ...
  'DefaultAxesTickLength', [0.02 0.05], 'defaultaxestickdir', 'out', 'DefaultAxesTickDirMode', 'manual', ...
  'defaultfigurecolormap', [1 1 1], 'defaultTextInterpreter','tex');
  usr = getenv('USER');

types = {'regress', 'stimcoding'};
for s = 1:2,
  plots = {'neutral', 'biased'};

  for p = 1:length(plots),

    switch p
      case 1

      switch usr
        case 'anne' % local
        datasets = {'RT_RDK', 'projects/0/neurodec/Data/MEG-PL', 'NatComm', 'Anke_2afc_neutral'};
        case 'aeurai' % lisa/cartesius
        datasets = {'NatComm', 'MEG', 'Anke_neutral', 'RT_RDK'};
      end
      datasetnames = {'2IFC (Urai et al. 2016)', '2IFC (MEG)', '2AFC (Braun et al.)', '2AFC (RT)'};

      case 2
      switch usr
        case 'aeurai' % lisa/cartesius
        datasets = {'Anke_alternating', 'Anke_neutral', 'Anke_repetitive', 'Anke_serial'};
      end
      datasetnames = {'2AFC alternating', '2AFC neutral', '2AFC repetitive', '2AFC all'};
    end

    % ============================================ %
    % DIC COMPARISON BETWEEN DC, Z AND BOTH
    % ============================================ %

    % 1. STIMCODING, only prevresp
    clf;
    mdls = {'dc_prevresp_prevstim', 'z_prevresp_prevstim', ...
    'dc_z_prevresp_prevstim', 'nohist'};
    for d = 1:length(datasets),
      subplot(4, 4, d);
      getPlotDIC(mdls, types{s}, d, 1);
      title(datasetnames{d});
      set(gca, 'xtick', 1:3, 'xticklabel', {'dc', 'z', 'both'});
    end

    % can you please add the full diffusion equation on top of the regression models? So akin to the eq we put into JW’s figure,
    % only here we would also have to add z. For specifics, take a look at the first few equations in Bogasz’ paper...

    % subplot(4,4,6);
    % switch types{s}
    % case 'regress'
    %   text(-0.2, 0.6, {'Regression models', ...
    %   'dc: dy = s*v*dt + dc \cdot dt + cdW, x', ...
    %   'z ~ 1 + prevresp + prevstim'}, 'fontsize', 8);
    % case 'stimcoding'
    % end
    % axis off;

    drawnow;
    print(gcf, '-depsc', sprintf('~/Data/serialHDDM/figure1b_HDDM_DIC_%s_%s.eps', plots{p}, types{s}));
    print(gcf, '-dpdf', sprintf('~/Data/serialHDDM/figure1b_HDDM_DIC_%s_%s.pdf', plots{p}, types{s}));

  % % ============================================ %
  % DIC COMPARISON BETWEEN DC, Z AND BOTH
  % ============================================ %

  clf; nrsubpl = 5;
  mdls = {'dc_prevresp', 'dc_prevresp_prevstim',  ...
  'dc_prevresp_prevstim_sessions', 'dc_prevresp_prevstim_prevrt', ...
  'dc_prevresp_prevstim_prevrt_prevpupil', ...
  'dc_prevresp_prevstim_prevrt_prevpupil_sessions', 'nohist'};

  for d = 1:length(datasets),
    subplot(nrsubpl, nrsubpl, d);
    getPlotDIC(mdls, types{s}, d, 1);
    set(gca, 'xtick', 1:6, 'xticklabel',...
    {'[1]', '[2]', '[3]', '[4]', '[5]', '[6]'});
    title(datasetnames{d});
  end

  switch types{s}
  case 'regress'

  subplot(nrsubpl, nrsubpl, d+1);
  text(0, -0.2, {'Regression models', ...
  '[1] v ~ 1 + stimulus + prevresp', ...
  '[2] v ~ 1 + stimulus + prevresp + prevstim', ...
  '[3] v ~ 1 + stimulus*session + prevresp + prevstim', ...
  '     a ~ 1 + session', ...
  '[4] v ~ 1 + stimulus*session + prevresp*prevrt + prevstim*prevrt', ...
  '     a ~ 1 + session', ...
  '[5] v ~ 1 + stimulus*session + prevresp*prevrt + prevstim*prevrt + prevresp*prevpupil + prevstim*prevpupil', ...
  '     a ~ 1 + session', ...
  '[6] v ~ 1 + session*(stimulus + prevresp*prevrt + prevstim*prevrt + prevresp*prevpupil + prevstim*prevpupil)', ...
  '     a ~ 1 + session', ...
  }, 'fontsize', 6); axis off;
  end

  print(gcf, '-depsc', sprintf('~/Data/serialHDDM/suppfigure1b_HDDM_DIC_allmodels_%s_%s.eps', plots{p}, types{s}));
  print(gcf, '-dpdf', sprintf('~/Data/serialHDDM/suppfigure1b_HDDM_DIC_allmodels_%s_%s.pdf', plots{p}, types{s}));
end
end
end

% ============================================ %
% DIC COMPARISON BETWEEN DC, Z AND BOTH
% ============================================ %

function getPlotDIC(mdls, s, d, plotBest)
  global datasets
  axis square;

  mdldic = nan(1, length(mdls));
  for m = 1:length(mdls),
    if ~exist(sprintf('~/Data/%s/HDDM/summary/%s_%s_all.mat', ...
      datasets{d}, s, mdls{m}), 'file'),
      continue;
    end

    load(sprintf('~/Data/%s/HDDM/summary/%s_%s_all.mat', ...
    datasets{d}, s, mdls{m}));

    if (isnan(dic.full) || isempty(dic.full)) && ~all(isnan(dic.chains)),
      dic.full = nanmean(dic.chains);
    end
    mdldic(m) = dic.full;
  end

  if isnan(mdldic(end)), assert(1==0); end

    % everything relative to the full mdoel
    mdldic = bsxfun(@minus, mdldic, mdldic(end));
    mdldic = mdldic(1:end-1);

    b = bar(1:length(mdldic), mdldic, 'facecolor', [0.7 0.7 0.7], 'barwidth', 0.5, 'BaseValue', 100);
    b.BaseValue = 0; drawnow;

    %# Add a text string above/below each bin
    for i = 1:length(mdldic),
      if mdldic(i) < 0,
        text(i, mdldic(i) - 0.07*range(get(gca, 'ylim')), ...
        num2str(round(mdldic(i))), ...
        'VerticalAlignment', 'top', 'FontSize', 4, 'horizontalalignment', 'center');
      elseif mdldic(i) > 0,
        text(i, mdldic(i) + 0.14*range(get(gca, 'ylim')), ...
        num2str(round(mdldic(i))), ...
        'VerticalAlignment', 'top', 'FontSize', 4, 'horizontalalignment', 'center');
      end
    end

    % indicate which one is best
    bestcolor = linspecer(3);
    if plotBest,
      [~, idx] = min(mdldic);
      hold on;
      %  disp(idx);
      bar(idx, mdldic(idx), 'basevalue', 0, 'facecolor', bestcolor(1, :), 'barwidth', 0.5, 'BaseValue', 0);
    end

    box off;
    ylabel({'\Delta DIC (from nohist)'});
    set(gca, 'xticklabel', {'dc', 'z'}, 'tickdir', 'out');
    % set(gca, 'YTickLabel', num2str(get(gca, 'YTick')'));
    axis square; axis tight;
    ylim(1.8*get(gca, 'ylim'));
    xlim([0.7 length(mdls)-1+0.5]);
    offsetAxes;
    set(gca, 'xcolor', 'k', 'ycolor', 'k');
  end
