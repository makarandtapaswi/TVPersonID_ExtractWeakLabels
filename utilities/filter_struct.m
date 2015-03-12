function [ s ] = filter_struct( s, varargin )
%FILTER_STRUCT Only keep specified fields of a structure
%   S = FILTER_STRUCT(S, field1, ...) returns a new structure, which only keeps
%   the fields specified as parameters.  Nested fields can be specified 
%   via dots, i.e 'a.b.c', which will then only keep a.b.c and remove all other
%   neighbours of a, a.b and a.b.c.
%
%   Example:
%   >> s = struct('a', 1, 'b', 2, 'c', struct('k', 1, 'j', 3));
%   >> s = filter_struct(s, 'a', 'c.j')
%   s = 
%       a: 1
%       c.j: 3

% Author: Martin Bäuml

if isempty(varargin) 
    error('expected at least one field');
end

% collect which fields to keep, and split nested field specifiers
keep = cell(0, 2);
for k = 1:length(varargin)
    % split at the first do if there is one
    m = strfind(varargin{k}, '.');
    if ~isempty(m)
       first = varargin{k}(1:m-1);
       rem = varargin{k}(m+1:end);
    else
        first = varargin{k};
        rem = '';
    end
    
    % check whether the (root) fieldname was specified before
    m2 = [0];
    if ~isempty(keep)
        m2 = strcmp(first, keep(:,1));
    end
    
    if any(m2)
        % if seen before, add remainder to list for nested call
        % if there is no remainder, keep an empty struct as indicator to keep
        % the full field
        if ~isempty(keep{m2, 2})
            if strcmp(rem, '')
                keep{m2, 2} = {};
            else
                keep{m2, 2} = [keep{m2, 2}, rem];
            end
        end
    else
        % field has not been seen before, add new entry to keep
        if strcmp(rem, '')
            [keep{end+1, :}] = deal(first, {});
        else
            [keep{end+1, :}] = deal(first, {rem});
        end
    end
end

% go through each field and see whether we keep it
fn = fieldnames(s);
for k = 1:length(fn)
    % check whether fieldname is in keep
    m = strcmp(fn{k}, keep(:, 1));
    if any(m)
        % if these were nested fieldnames, call filter_struct recursively
        if ~isempty(keep{m, 2})
            for i = 1:length(s)
                assert(isstruct(s(i).(fn{k})));
                s(i).(fn{k}) = filter_struct(s(i).(fn{k}), keep{m, 2}{:});
            end
        end
    else
        % otherwise just remove the field
        s = rmfield(s, fn{k});
    end
end

end

