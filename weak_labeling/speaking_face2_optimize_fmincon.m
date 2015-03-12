function res = speaking_face2_optimize_fmincon(episode_data, cliq_data, optim_params, debug)
%SPEAKING_FACE2_OPTIMIZE_QUADPROG Constrained function minimiation based optimization
%
% Models the problem as a constrained function minimization
% Wraps the fmincon objective function -- speaking_face2_fmincon_objfun.m
% Calls fmincon, collects results
%
% Pretty good! Incorporates uniqueness, threading, regularization and lip-diff
% based scoring in the objective.
%
% Author: Makarand Tapaswi
% Created: 09-09-2014

% prepare some pre-requisite data for analysis
nc = length(episode_data.characters);
nft = length(episode_data.gtids);
gt_chars = cellfun(@(x) find(strcmp(x, episode_data.characters)), episode_data.gtids);
assigned_chars = nan(1, nft);

objparams = optim_params.objparams;
res = struct('assign', repmat({''}, 1, nft), 'gtid', episode_data.gtids, ...
             'conf', repmat({0}, 1, nft), 'conf_diff', repmat({0}, 1, nft), ...
             'valid_thresh', repmat({0}, 1, nft));

%%% go through each cliq and evaluate
if ~debug, fprintf('Optimizing for each clique: %4d/%4d', 0, length(cliq_data)); end
for k = 1:length(cliq_data)
    cliq_ft_idx = cliq_data(k).cliqs;
    if ~debug, fprintf('\b\b\b\b\b\b\b\b\b%4d/%4d', k, length(cliq_data)); end
    ncft = length(cliq_ft_idx);
    %%% create the sum = 1 multiplier matrix for the constraint
    tmp_matrix = cell(ncft, ncft);
    [tmp_matrix{:}] = deal(zeros(1, nc));
    for p = 1:ncft
        tmp_matrix{p, p} = ones(1, nc);
    end
    Aeq = blocky_matrix(tmp_matrix);
    
    %%% initialize parameters for optimization
    x0 = optim_params.eps_equal * ones(size(cliq_data(k).lip_scores));
    lb_x = zeros(size(x0));
    ub_x = ones(size(x0));
    
    %%% call "fmincon"
    ls = cliq_data(k).lip_scores;
    tp = cliq_data(k).thread_pairs;
    up = cliq_data(k).unique_pairs;
    beq = ones(ncft, 1);
    init_obj = speaking_face2_fmincon_objfun(x0, ls, tp, up, optim_params.weights);
    [x_final, final_obj] = fmincon(@(x) speaking_face2_fmincon_objfun(x, ls, tp, up, optim_params.weights), ...
                      x0, [], [], Aeq, beq, lb_x, ub_x, [], objparams);

    %%% process output x after optimization
    [vals, idx] = maxk(x_final, 2, 1);
    vals_diff = abs(diff(vals, 1));
    assign_for_idx = find(vals_diff > optim_params.diff_thresh);
    assigned_chars(cliq_ft_idx(assign_for_idx)) = idx(1, assign_for_idx);
    
    for t = 1:length(cliq_ft_idx)
        res(cliq_ft_idx(t)).assign = episode_data.characters{idx(1, t)};
        res(cliq_ft_idx(t)).conf_diff = vals_diff(1, t);
        res(cliq_ft_idx(t)).conf = vals(1, t);
        if vals_diff(1, t) > optim_params.diff_thresh
            res(cliq_ft_idx(t)).valid_thresh = 1;
        end
    end

    % results printing
    if debug
        % display a lot of stuff to analyze what happened
        fprintf('optimized from %.3f --> %.3f\n', init_obj, final_obj);
        assigned_names = cell(size(idx, 2), 1);
        for t = 1:size(idx, 2)
            if ~isnan(assigned_chars(cliq_ft_idx(t)))
                assigned_names{t} = episode_data.characters{assigned_chars(cliq_ft_idx(t))};
            end
        end
        fprintf('tracks: idx -- trackerId -- gt -- assigned\n');
        disp([mat2cellsingle(cliq_ft_idx'), mat2cellsingle(cliq_data(k).cliq_tids'), episode_data.gtids(cliq_ft_idx)', assigned_names]);
        fprintf('tracks: characters -- lip_scores\n');
        disp([episode_data.characters', mat2cellsingle(cliq_data(k).lip_scores)]);
        fprintf('tracks: characters -- optim_scores\n');
        disp([episode_data.characters', mat2cellsingle(x_final)]);        
        fprintf('unique pairs (column):\n');
        disp(cliq_data(k).unique_pairs');
        fprintf('thread pairs (column):\n');
        disp(cliq_data(k).thread_pairs');
        
        ft_assigned = ~isnan(assigned_chars);
        num_correct = sum(assigned_chars(ft_assigned) == gt_chars(ft_assigned));
        assigned = 100*sum(ft_assigned)/length(episode_data.gtids);
        
        % check for error in this cliq, easier to debug
        ignoreidx = cellfun(@isempty, assigned_names);
        if all(ignoreidx), fprintf(2, 'MEH! SKIP  ');
        else
            cliq_no_error = all(strcmp(episode_data.gtids(cliq_ft_idx(~ignoreidx)), assigned_names(~ignoreidx)'));
            if cliq_no_error, fprintf(2, 'WOOHOO! :D ');
            else              fprintf(2, 'OH! NO! :( ');
            end
        end
        fprintf('--- Summary: Cliq. %4d -- Precision: (%d) %.4f | Assigned: (%d) %.4f\n', ...
            k, num_correct, 100*num_correct/sum(ft_assigned), sum(ft_assigned), assigned);
    end
end
if ~debug, fprintf('\n'); end

if debug
    %% VL-PR curve on all scores
    vlpr_labels = double(arrayfun(@(x) strcmp(x.gtid, x.assign), res));
    vlpr_labels(vlpr_labels == 0) = -1;

    figure;
    subplot(121);
    rec_at_chosen_point = sum([res.conf] > (0.1 + 1/nc))/nft;
    vl_pr(vlpr_labels, [res.conf]);
    line([rec_at_chosen_point, rec_at_chosen_point], [0, 1], 'Color', 'g', 'LineWidth', 2);
    legend off; title('Assigned Confidences');
    subplot(122);
    rec_at_chosen_point = sum([res.conf_diff] > 0.1)/nft;
    vl_pr(vlpr_labels, [res.conf_diff]);
    line([rec_at_chosen_point, rec_at_chosen_point], [0, 1], 'Color', 'g', 'LineWidth', 2);
    legend off; title('Assigned Conf diff');
end

end
