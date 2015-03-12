function obj = speaking_face2_fmincon_objfun(x, lip_scores, pos_pairs, neg_pairs, weights)
%SPEAKING_FACE2_OBJFUN Objective function to use with fmincon
%
% See also: speaking_face2, speaking_face2_optimize_fmincon
%
% Inputs
%       variable to optimize: x -- nc x ncft
%       lip scores (ls):      lip_scores -- nc x ncft
%       pos pairs (thread):   pos_pairs -- npairs x 2
%       neg pairs (unique):   neg_pairs -- npairs x 2
%
% Outputs
%       objective function value: obj
%       gradient? (TODO? probably not required because problem is too simple)
%
% Author: Makarand Tapaswi
% Created: 09-09-2014

%%% lip-match score
lip = 0;
for k = 1:size(x, 2)
    lip = lip + x(:, k)'*lip_scores(:, k);
end

%%% pos-score
pos = 0;
for k = 1:size(pos_pairs, 1)
    pos = pos + x(:, pos_pairs(k, 1))' * x(:, pos_pairs(k, 2));
end

%%% neg-score
neg = 0;
for k = 1:size(neg_pairs, 1)
    neg = neg + x(:, neg_pairs(k, 1))' * x(:, neg_pairs(k, 2));
end

%%% quadratic regularization
%       prevents setting the slightest shifts in lip-diff to 1
quad_reg = sum(sum(x.^2));

% minimize this!
obj = weights.lip * lip ...             % negative
      + weights.unique * neg ...        % positive
      + weights.thread * pos ...        % negative
      + weights.regular * quad_reg;     % positive

end
