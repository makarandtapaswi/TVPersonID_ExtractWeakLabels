function [episode_data, cliq_data, opts_hash] = speaking_face2_prepare_data(VS, ft, characters, varargin)
%SPEAKING_FACE2_PREPARE_DATA -- Since speaking_face.m was so adhoc! :)
% Now uses an energy-based minimization scheme to do the best possible job of
% identity assignment.
%
% Author: Makarand Tapaswi & Martin Baeuml
% Created: 04-09-2014

dopts.ft_type = 'pf8';
dopts.use_unique = true;
dopts.use_threads = true;
dopts.eps_small = 1e-6;

% the "feature_offset" in speaking_face.m; reduces the duration of
% facetrack-subtitle overlap by X (e.g., 0.5) seconds from both sides
dopts.time_offset_frst = 0.05;
dopts.time_offset_last = 0.2;

opts = cvhci_process_options(varargin, dopts);

nc = length(characters);

fthash = filter_struct(ft, 'x', 'y', 'w', 'h', 'frames', 'timestamps', 'trackerId', 'lip_diff');
opts_hash = DataHash({opts, fthash});
cache_fname = sprintf(VS.cache.sf2_prepare_data, length(ft), opts_hash(1:8));
try
    fprintf('Loading all relevant data from cache:\n%s\n', cache_fname);
    load(cache_fname);
catch
    %% Gather all the data
    % gather subtitle/transcript annotations
    load(VS.data.subtt_trans);
%     AllTextStruct = subtitle_transcript_matcher(VS, params);
    ST = split_subtitle_lines(AllTextStruct);

    %% Required analysis for energy potentials
    % remove subtitles which don't have a "Speaker" field as one of the characters
    ST(~cellfun(@(x) any(strcmpi(x, characters)), {ST.Speaker})) = [];
    % make a numerical list of speakers (easier to use later)
    subtt_ids = cellfun(@(x) find(strcmpi(x, characters)), {ST.Speaker});

    % tracks overlap with which subtitles?
    face_segments = [arrayfun(@(x) x.timestamps(1), ft)', arrayfun(@(x) x.timestamps(end), ft)'];
    text_segments = [[ST.starttime]', [ST.endtime]'];
    [face_text.overlaps, face_text.durations] = overlapping_segments(face_segments, text_segments);

    % pair-wise uniqueness
    if opts.use_unique
        unique_ft_pairs = overlapping_segments(face_segments, face_segments, true);
    end

    % shot and track threading
    if opts.use_threads
        load(VS.data.ft_thread);
%         [track_threads, track_in_thread, track_thread_matrix] = shot_and_track_threading(VS, ft, read_tracks_via_shots(VS, ft));
    end

    %% Create cliques for optimization
    ft_links = zeros(length(ft));
    if opts.use_unique
        % add uniqueness pairs
        ft_links(sub2ind(size(ft_links), unique_ft_pairs(:, 1), unique_ft_pairs(:, 2))) = 1;
    end
    if opts.use_threads
        % add threading pairs
        ft_links = ft_links + track_thread_matrix;
    end
    % get cliqs
    [cliqs, ft_in_cliq] = transitivity_cliques(ft_links);
    % to tracks which are not part of any cliq, add them as singletons
    singleton_tracks = find(ft_in_cliq == 0);
    for k = 1:length(singleton_tracks)
        cliqs{end+1} = singleton_tracks(k);
        ft_in_cliq(singleton_tracks(k)) = length(cliqs);
    end
    % make sure all tracks are part of some cliq (single or more)
    assert(length(unique([cliqs{:}])) == length(ft));

    %% For each cliq localize indexing
    thread_pairs = cell(1, length(cliqs));
    unique_pairs = cell(1, length(cliqs));
    lip_scores = cell(1, length(cliqs));
    cliq_tids = cell(size(cliqs));

    for k = 1:length(cliqs)
        cliq_ft_idx = cliqs{k};
        ncft = length(cliq_ft_idx);
        % create checklists
        checked_thread = nan(1, ncft);
        checked_uniq = nan(1, ncft);

        %%% create local threading pairs
        thread_pairs{k} = [];
        if opts.use_threads
            for t = 1:ncft
                if ~isnan(checked_thread(t)), continue; end
                % track not in thread, continue
                if track_in_thread(cliq_ft_idx(t)) == 0, checked_thread(t) = 0; continue; end
                % list of tracks in this thread
                in_thread = track_threads{track_in_thread(cliq_ft_idx(t))};
                % mark tracks as added
                for ii = in_thread, checked_thread(ii == cliq_ft_idx) = 1; end
                % get threaded pairs
                thread_pairs{k} = [thread_pairs{k}; nchoosek(in_thread, 2)];
            end
            % localize indexing
            for i = 1:numel(thread_pairs{k})
                thread_pairs{k}(i) = find(thread_pairs{k}(i) == cliq_ft_idx);
            end
        end

        %%% create uniqueness pairs and energy matrix
        unique_pairs{k} = [];
        if opts.use_unique
            for t = 1:ncft
                if ~isnan(checked_uniq(t)), continue; end
                negpair_at = find(any(unique_ft_pairs == cliq_ft_idx(t), 2));
                % no neg pairs, ok continue
                if isempty(negpair_at), checked_uniq(t) = 0; continue; end
                % found negpairs, mark as used and add
                for ii = 1:length(negpair_at)
                    checked_uniq(cliq_ft_idx == unique_ft_pairs(negpair_at(ii), 1)) = 1;
                    checked_uniq(cliq_ft_idx == unique_ft_pairs(negpair_at(ii), 2)) = 1;
                    unique_pairs{k} = [unique_pairs{k}; unique_ft_pairs(negpair_at(ii), :)];
                end
            end
            % localize indexing
            for i = 1:numel(unique_pairs{k})
                unique_pairs{k}(i) = find(unique_pairs{k}(i) == cliq_ft_idx);
            end
        end
        
        %%% lip difference scores to influence decisions
        lip_scores{k} = opts.eps_small * ones(nc, ncft);
        % for each track, get speaker id of which subtitles overlap and add corresponding lipdiff score
        for t = 1:ncft
            pick_subtt = cliq_ft_idx(t) == face_text.overlaps(:, 1);
            % skip the track if it doesn't overlap with any subtt
            if ~any(pick_subtt), continue; end
            ftone = ft(cliq_ft_idx(t));
            this_subtts = face_text.overlaps(pick_subtt, 2);
            this_overlaps = face_text.durations(pick_subtt, :);
            % get the subtt overlap durations and sum up lipdiff of that region
            for s = 1:length(this_subtts)
                % get the duration of lip-diff scores contained within subtitle
                lipdiff1 = ftone.timestamps > (this_overlaps(s, 1) + opts.time_offset_frst);
                lipdiffn = ftone.timestamps < (this_overlaps(s, 2) - opts.time_offset_last);
                if ~any(lipdiff1) || ~any(lipdiffn), continue; end
                lipdiff1 = find(lipdiff1, 1, 'first');
                lipdiffn = find(lipdiffn, 1, 'last');

                % accumulate lipdiff score within that region and use it as a score
                lipdiff_score = nansum(abs(ftone.lip_diff(lipdiff1:lipdiffn)));
                f_idx = subtt_ids(this_subtts(s));
                lip_scores{k}(f_idx, t) = lip_scores{k}(f_idx, t) + lipdiff_score;
            end
        end
        
        %%% save cliq trackerId for posterity
        cliq_tids{k} = [ft(cliq_ft_idx).trackerId];
    end

    % Save everything relevant to further optimization processing
    episode_data = struct('gtids', {{ft.groundTruthIdentity}}, 'characters', {characters});
    cliq_data = struct('cliqs', cliqs, 'cliq_tids', cliq_tids, 'lip_scores', lip_scores, ...
                       'thread_pairs', thread_pairs, 'unique_pairs', unique_pairs);
    save(cache_fname, 'episode_data', 'cliq_data');
end

end

