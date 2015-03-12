% gather threading info
startup;

VSS = [BBT(1, 1:6), BUFFY(5, 1:6)];
for k = 2:length(VSS)
    ft = get_face_tracks(VSS(k), 'pf8');
    ft = remove_ignore_tracks(ft, params.face.id.ignore_tracks);
    [track_threads, track_in_thread, track_thread_matrix] = shot_and_track_threading(VSS(k), ft, read_tracks_via_shots(VSS(k), ft));
    save(sprintf('%s.track_threads.mat', VSS(k).name), 'track_threads', 'track_in_thread', 'track_thread_matrix');
end

