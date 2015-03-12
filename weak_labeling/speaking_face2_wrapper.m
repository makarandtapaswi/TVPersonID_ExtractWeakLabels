function [ft, result, error_counts] = speaking_face2_wrapper(VSS, varargin)
%SPEAKING_FACE2_WRAPPER Main wrapper to call the optimization based speaking-face assignment
%
% See the dopts
%
% Author: Makarand Tapaswi
% Created: 11-09-2014

% general
dopts.debug = false;
dopts.re_optimize = false;
dopts.ft_type = 'pf8';

% lipdiff method, tiny tweaks to make it "better"
dopts.lipdiff.opening_bpf = false;
dopts.time_offset_frst = 0.1;
dopts.time_offset_last = 0.2;

% data preparation
dopts.cleanup.pan = []; % if not empty, removes tracks *greater* than this pan angle
dopts.cleanup.size = []; % if not empty, removes tracks *smaller* than this resolution
dopts.use_unique = true;
dopts.use_threads = true;
dopts.operating_point = 0.05; % IMPORTANT THRESHOLD AT WHICH ID IS PERFORMED! LOWER WILL ASSIGN MORE TRACKS BUT LOSE PRECISION.
dopts.eps_small = 1e-6;

% optimization model hyperparameters
dopts.optim_diff_thresh = 0.1;
dopts.quadprog_weights = struct('unique', 1, 'thread', -1);
dopts.fmincon_weights = struct('lip', -1, 'unique', 1, 'thread', -1, 'regular', 3);

% optimset -- actual optimization parameters
dopts.objparams = struct('Display', 'off');

% ready-up
opts = cvhci_process_options(varargin, dopts);
optim_params = struct('eps_small', opts.eps_small, 'eps_equal', 1, 'diff_thresh', opts.optim_diff_thresh, ...
                      'quadprog_weights', opts.quadprog_weights, 'fmincon_weights', opts.fmincon_weights, ...
                      'objparams', opts.objparams);

%% Run for all episodes
[ft, epi_data, cliq_data, result, error_counts] = deal(cell(1, length(VSS)));

for k = 1:length(VSS)
    fprintf('-----------------Episode %d--------------------\n', VSS(k).episode);
    % get characters list, make sure unknown is always last :)
    characters = [setdiff(VSS(k).characters, 'unknown'), 'unknown'];

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% MODEL-BASED %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%% gather face tracks - use the relevant fields for caching
    % face tracks were saved such that they already contain the lip_opening with BPF feature
    load(VSS(k).data.facetracks);
    ft{k} = FaceTracks;
    
    %%% remove tracks before passing to data prep and optimization models
    sf2_ft = ft{k};
    % face resolution (size) cleanup
    if ~isempty(opts.cleanup.size)
        sf2_ft(arrayfun(@(x) mean(x.w) < opts.cleanup.size, sf2_ft)) = [];
    end
    if ~isempty(opts.cleanup.pan)
        sf2_ft(arrayfun(@(x) mean(abs(x.pan)) > opts.cleanup.pan, sf2_ft)) = [];
    end
    nft = length(sf2_ft);

    %%% Collect data necessary for optimization
    [epi_data{k}, cliq_data{k}, sf2_hash] = ...
        speaking_face2_prepare_data(VSS(k), sf2_ft, characters, ...
                                    'ft_type', opts.ft_type, 'use_unique', opts.use_unique, 'use_threads', opts.use_threads, ...
                                    'time_offset_frst', opts.time_offset_frst, 'time_offset_last', opts.time_offset_last);
    optim_params.eps_equal = 1./length(epi_data{k}.characters);

    %%%%%%%%%%%%%%%%%%%% OPTIMIZATION with CACHING-SUPPORT %%%%%%%%%%%%%%%%%%%%%
    optim_hash = DataHash(optim_params);
    opt_results_cache_fname = sprintf(VSS(k).cache.sf2_optim_result, sf2_hash(1:8), optim_hash(1:8));
    try
        fprintf('Loading results from cache:\n%s\n', opt_results_cache_fname);
        if opts.re_optimize, assert(false); end
        load(opt_results_cache_fname);
    catch
        %%% fmincon -- Constrained function minimization
        optim_params.weights = optim_params.fmincon_weights;
        assignment_results = speaking_face2_optimize_fmincon(epi_data{k}, cliq_data{k}, optim_params, opts.debug);
        % save and collect
        save(opt_results_cache_fname, 'assignment_results', 'optim_params');
    end

    %%% print this episode result as summary
    valid = [assignment_results.conf_diff] > opts.operating_point;
    correct = strcmp({assignment_results(valid).gtid}, {assignment_results(valid).assign});
    fprintf(2, 'Summary: %s -- #FT: (%d) %d | Precision: (%d) %.2f | Assigned: (%d) %.2f\n', ...
            VSS(k).name, length(ft{k}), nft, sum(correct), 100*sum(correct)/sum(valid), sum(valid), 100*sum(valid)/nft);

    %%% collect episode results in a cell & *make sure number of tracks matches*
    for t = 1:length(ft{k})
        idx = find(ft{k}(t).trackerId == [sf2_ft.trackerId]);
        if isempty(idx)
            result{k}(t) = struct('assign', '', 'gtid', ft{k}(t).groundTruthIdentity, ...
                                  'conf', NaN, 'conf_diff', NaN, 'valid_thresh', NaN);
        else
            result{k}(t) = assignment_results(idx);
        end
    end
    assert(length(result{k}) == length(ft{k}));
        
    %%% add "assigned_speaker" & "assigned_scores" field to the facetracks
    % structure, helps easily switch the legacy face id codes
    for t = 1:length(ft{k})
        if result{k}(t).conf_diff > opts.operating_point
            ft{k}(t).assigned_speaker = result{k}(t).assign;
            ft{k}(t).assigned_scores = result{k}(t).conf_diff;
        else
            ft{k}(t).assigned_speaker = '';
        end
    end

    % release...
end

% if single video, return struct instead of a cell
if length(VSS) == 1
    ft = ft{1};
    result = result{1};
    error_counts = error_counts{1};
end

end
