function out_mat = blocky_matrix(blocks)
%BLOCK_MATRIX Creates a block matrix
%
% Example usage:
%       blocky_matrix({zeros(2), zeros(2); eye(2), zeros(2)})
%
% Author: Makarand Tapaswi
% Created: 04-09-2014

% concatenate all the "column" cells
for k = 1:size(blocks, 1)
    tmp_mat{k, 1} = cat(2, blocks{k, :});
end

% concatenate all the "row" cells
for k = 1:size(tmp_mat, 1)
    out_mat = cat(1, tmp_mat{:});
end


end