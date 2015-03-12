function assigned_chars = speaking_face2_optimize_quadprog(episode_data, cliq_data, optim_params, debug)
%SPEAKING_FACE2_OPTIMIZE_QUADPROG Quadratic Programming based optimization
% Models the problem as a quadratic optimization
% Creates all the necessary constraint and cost matrices
% Calls quadprog, collects results
%
% TODO: imitate results structure like in speaking_face2_optimize_fmincon.m
%
% Not so good because the convex-ness of the problem is questionable
%
% Author: Makarand Tapaswi
% Created: 08-09-2014

% creates the relevant matrices for quadratic programming and calls quadprog
nc = length(episode_data.characters);
% ground-truth numbered index into characters list
gt_chars = cellfun(@(x) find(strcmp(x, episode_data.characters)), episode_data.gtids);

assigned_chars = nan(1, length(episode_data.gtids));
for k = 1:length(cliq_data)
    cliq_ft_idx = cliq_data(k).cliqs;
    ncft = length(cliq_ft_idx);

    % create the threading energy computation matrix
    if ~isempty(cliq_data(k).thread_pairs)
        tmp_matrix = cell(ncft, ncft);
        [tmp_matrix{:}] = deal(zeros(nc));
        for p = 1:size(cliq_data(k).thread_pairs, 1)
            tmp_matrix{cliq_data(k).thread_pairs(p, 1), cliq_data(k).thread_pairs(p, 2)} = eye(nc);
        end
        thread_matrix = blocky_matrix(tmp_matrix) + blocky_matrix(tmp_matrix)';
    else
        thread_matrix = zeros(ncft*nc);
    end

    % create the uniqueness energy computation matrix
    tmp_matrix = cell(ncft, ncft);
    [tmp_matrix{:}] = deal(zeros(nc));
    for p = 1:size(cliq_data(k).unique_pairs, 1)
        tmp_matrix{cliq_data(k).unique_pairs(p, 1), cliq_data(k).unique_pairs(p, 2)} = eye(nc);
    end
    unique_matrix = blocky_matrix(tmp_matrix) + blocky_matrix(tmp_matrix)';

    % create the sum = 1 multiplier matrix
    tmp_matrix = cell(ncft, ncft);
    [tmp_matrix{:}] = deal(zeros(1, nc));
    for p = 1:ncft
        tmp_matrix{p, p} = ones(1, nc);
    end
    sum1_matrix = blocky_matrix(tmp_matrix);

    % initialize optimization variable
    x0 = optim_params.eps_equal * ones(nc, ncft);
    x0 = x0(:);

    % setup
    H = optim_params.weights.unique * unique_matrix + optim_params.weights.thread * thread_matrix;
    Aeq = sum1_matrix;
    beq = ones(ncft, 1);
    lb = zeros(size(x0)); ub = ones(size(x0));
    f = -cliq_data(k).lip_scores(:);

    % call "quadratic programming"
    out_x = quadprog(H, f, [], [], Aeq, beq, lb, ub, x0, optimset('Display', 'off'));

    % use the output and create character assignments
    [vals, idx] = maxk(reshape(out_x, [nc, ncft]), 2, 1);
    assign_for = abs(diff(vals, 1)) > 0.1;
    assigned_chars(cliq_ft_idx(assign_for)) = idx(1, assign_for);

    if debug % multiplier matrix figures
        figure(101);
        subplot(221); imagesc(thread_matrix); title('Threading multiplier'); axis equal tight;
        subplot(222); imagesc(unique_matrix); title('Uniqueness multiplier'); axis equal tight;
        subplot(223); imagesc(sum1_matrix); title('Sum = 1 multiplier'); axis equal tight;
        drawnow;

        ft_assigned = ~isnan(assigned_chars);
        fprintf('Summary: Cliq. %4d -- Precision: %.4f | Assigned: %.4f\n', k, ...
            100*sum(assigned_chars(ft_assigned) == gt_chars(ft_assigned))/sum(ft_assigned), 100*sum(ft_assigned)/length(episode_data.gtids));
    end
end

if ~debug
    ft_assigned = ~isnan(assigned_chars);
    fprintf('Summary: Cliq. %4d -- Precision: %.4f | Assigned: %.4f\n', k, ...
        100*sum(assigned_chars(ft_assigned) == gt_chars(ft_assigned))/sum(ft_assigned), 100*sum(ft_assigned)/length(episode_data.gtids));
end

warning('Collection and analysis of results is not complete! Please check fmincon');

end
