function VideoStruct = initVIDEO(video_name, varargin)
%INITVIDEO - Returns VideoStructure array for list of input video names
% Usually called by other stuff, although it can also be called directly.
% Examples:
%   video_name = 'bbt_s01e01', 'buffy_s05e01', 'got_s01e01'
%
% length(varargin) == 2, {season, episode}
%
% This code adds or calls the adders of stuff to the video structure
% ADD: video_info, labels, cache

%% Process arguments
default_args.series = '';
default_args.season = [];
default_args.episode = [];
default_args.movie = [];
VideoStruct = cvhci_process_options(varargin, default_args);

%% Add all the information
VideoStruct.name = video_name;

%%% data file name templates
VideoStruct.data.castlist =    ['data/castlist/', video_name, '.cast'];
VideoStruct.data.videvents =   ['data/video/', video_name, '.videvents'];
VideoStruct.data.facetracks =  ['data/tracks/', video_name, '.facetracks.mat'];
VideoStruct.data.subtt_trans = ['data/text/', video_name, '.subtt_trans_align.mat'];
VideoStruct.data.ft_thread =   ['data/tracks/', video_name, '.track_threads.mat'];

%%% cache file name templates
cachedirs.sf2 = 'cache/sf2/';
VideoStruct.cache.sf2_prepare_data =    [cachedirs.sf2, video_name, '.nft-%d.opts-%s.mat'];
VideoStruct.cache.sf2_optim_result =    [cachedirs.sf2, video_name, '.sf2data-%s.optimopts-%s.mat'];

% create cache directories if they do not exist
dirf = fieldnames(cachedirs);
for f = 1:length(dirf)
    if ~exist(cachedirs.(dirf{f}), 'dir'), mkdir(cachedirs.(dirf{f})); end
end



%% Add list of characters
try
    [VideoStruct.characters, VideoStruct.CharacterStruct] = get_character_names(VideoStruct);
catch
    VideoStruct.characters = {''};
    VideoStruct.CharacterStruct = empty_struct();
    warning('Failed to load list of characters for %s. Setting to empty.', VideoStruct.name);
end

end
