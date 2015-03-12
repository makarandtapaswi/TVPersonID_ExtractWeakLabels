function tracks_in_shot = read_tracks_via_shots(VideoStruct, Tracks)
%READ_TRACKS_VIA_SHOTS Returns a list of track indices per shot
% Uses the same index as the "Tracks"
%
% Author: Makarand Tapaswi
% Last modified: 10-05-2013


[ShotStartEnd, ShotType] = videoevents_to_shots(VideoStruct);
num_shots = size(ShotStartEnd, 1);

% Get list of frames in shot
frames_in_shot = cell(num_shots, 1);
for k = 1:num_shots
    frames_in_shot{k} = ShotStartEnd(k, 1):ShotStartEnd(k, 2);
end
    
% Go through each track and put it in proper shot
last_shot = 1;
tracks_in_shot = cell(num_shots, 1);
for k = 1:length(Tracks)
    track_assigned = 0;
    retry = 0;
    for s = max(1, last_shot-5):num_shots
        if ~isempty(intersect(Tracks(k).frames, frames_in_shot{s}))
            tracks_in_shot{s} = [tracks_in_shot{s}, k];
            track_assigned = track_assigned + 1;
            retry = 5;
        elseif track_assigned == 0
            last_shot = s;
        else
            if retry, retry = retry - 1;
            else
                break;
            end
        end
    end
    
    if ~track_assigned, keyboard; end
end

end
