function VideoStruct = BUFFY(season, episode)
% Initialize FG2015 project for Buffy the Vampire Slayer
% Given season and episode
%


num_frames = {[], [], [], [], [62619 62156 64099 63699 64082 64106]};

k = 1;
for ep = episode
    video_name = sprintf('buffy_s%02de%02d', season, ep);
    VideoStruct(k) = initVIDEO(video_name, 'series', 'buffy', 'season', season, 'episode', ep);
    % Hack some info about the video here to substitute for the actual full video
    VideoStruct(k).data.numframe = num_frames{season}(ep);
    k = k + 1;
end

end
