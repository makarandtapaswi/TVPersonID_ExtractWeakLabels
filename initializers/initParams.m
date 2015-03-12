%INITPARAMS - Get all default parameters

clear params;

%% Text Parameters

params.text.subtt_trans_method = 'words'; % alternatives are 'chars' or 'words'
params.text.allowable_error = 0.75; % error rate for the number of matching idxs
params.text.min_line_length = 2; % ignore all assignments for lines short than this due to missing reliability in matching, e.g. (Hi! - Hi! - Hi! - Hi!...)
params.text.words_window = 100;
params.text.chars_window = 100;

%% Book Parameters

params.book.chapters_alignment.m1 = 5;      % #matching words in the 2 dialogs
params.book.chapters_alignment.r1 = 0.6;    % min words-ratio between matched words and num-words
params.book.chapters_alignment.m2 = 3;      % #matching words in the 2 dialogs for small dialogs
params.book.chapters_alignment.r2 = 0.75;   % min words-ratio between matched words and num-words for both video and book for small dialogs
params.book.chapters_alignment.m3 = 2;      % very short dialogs, should match exactly. Use only after knowing which chapter goes where
params.book.chapters_alignment.r3 = 1;      % words-ratio is 1. Both dialogs should match perfectly.
params.book.chapters_alignment.neg_weight = 0.02; % -X is the weight to go down / right in the dtw_blocky
params.book.chapters_alignment.use_prior = true; % whether to use a prior in the search

params.book.esper_post_proc.multi_dlg_in_para = true;       % assign multiple dialogs in same para to same person
params.book.esper_post_proc.only_name_in_para = true;       % assign a single name appearing in para to dialog
params.book.esper_post_proc.alternation = true;             % setup alternating dialogs and assign names

%% Video Analysis Parameters

params.video_analysis.shotdetect.use_trackinglib_binary = true; % use the output from this (a column of scores)
if params.video_analysis.shotdetect.use_trackinglib_binary   
    params.video_analysis.shotdetect.diffthresh = 15; % threshold difference
else
    params.video_analysis.shotdetect.diffthresh = 2e8; % the original DFD struct difference threshold
end
params.video_analysis.shotdetect.filter_lengths = 11; % morphological filtering lengths
params.video_analysis.shotdetect.proximity = 8; % two shots cannot occur within 8 frames of each other! (@ 25fps)

%% Face Parameters
params.face.facetracks_type = 'pf8'; % facetrack tracking methods [pf|gt|abt]

% Comparing two tracks on the same video
params.face.trackdiff.area_match_tolerance = 50; % percentage required overlap to say that the tracks are same

% What can be called a good track
params.face.good_track.max_pan = 15; % mean pan angle should be smaller
params.face.good_track.size = 50; % mean track size should be bigger
params.face.good_track.track_length = 25; % number of frames in track should be more
params.face.good_track.need_eyes = 0.5; % 50% of the track should contain eye detections

% Face is false positive when
params.face.false_positive.skin_thresh = 10; % when skin confidence < X
params.face.false_positive.ffp_thresh = -45; % when facial feature point detector confidence < X
params.face.false_positive.trackchange_thresh = 1.5; % when same position score < X
params.face.false_positive.relsize_small_thresh = 0.4; % when track1 < 0.4 * track2, call it a false positive
params.face.false_positive.relsize_equal_thresh = 0.8; % when track1 > 0.8 * track2, consider them to be close enough
params.face.false_positive.faceposition_thresh = 5.5; % when face position score < X
params.face.false_positive.mmtracker_thresh = 0.2; % when tracker confidence < X
params.face.false_positive.svmclassifier_thresh = 0.8; % when classification score > X

% Facial feature extraction
params.face.facial_features.type = 'intraface'; % 'ninepoint': Sivic/Everingham 2009, 'esrfrontal'/'esrleft'/'esrright': AFLW ESR, 'intraface': SDM
params.face.facial_features.magnify_face_det = 0.2; % expand face bounding box for facial feature localization
params.face.facial_features.facepipe_debug = false; % debug output from the face-pipeline

% Lip region extraction parameters
params.face.lip_region.filt_length = 5;
params.face.lip_region.mouth_mid_to_nose_tip = 2/3;
params.face.lip_region.mouth_side_extra_factor = 1/4;
params.face.lip_region.bottom_lip_extra = 1.5;

% Speakign face association
params.face.speaking.thresh_upper = 0.015; % if lip diff > this, ==> speaking
params.face.speaking.thresh_lower = 0.0075; % if lip diff < this, ==> not speaking
params.face.speaking.thresh_conf = 0.5; % if confidence is too low, ignore (-25 for ninepoint, 0.5 for SDM)
params.face.speaking.use_book = false; % if true, get subtitle naming from the book, not a transcript

% Exemplar SVM classification parameters
params.face.exemplar.liblinS = 1; % liblinear method: 0-LR, 1-SVM
params.face.exemplar.slackC = 1; % SVM slack C
params.face.exemplar.singlefeat = 0; % whether to use a single feature per track
params.face.exemplar.fsel = 1; % remove features based on ffpconf
params.face.exemplar.min_ffpconf = -15; % remove features whose facial-feature-point confidence is lower than this

% Graph-based face clustering
params.face.graph_cluster.min_frames_overlap = 5; % minimum number of overlapping frames required
params.face.graph_cluster.w_uniq = -10; % negatively weight similarity when forcing uniqueness
params.face.graph_cluster.alt_shot_ou = 0.4; % required overlap / union of facetracks
params.face.graph_cluster.w_alt = 10; % alternate shot based FT similarity
params.face.graph_cluster.temporal_spread = 10; % sigma in an exponential function
params.face.graph_cluster.w_time = 1; % temporal proximity based FT similarity
params.face.graph_cluster.w_feature = 5; % weight for feature similarity
params.face.graph_cluster.exemplar_merge_track_thresh = -0.5; % all tracks with scores > 0 can be merged

% Face ID
params.face.id.feature_type = 'dct.f-bp.m-1.np-0.slf-5'; % parameters for dct: f: facial feature type (bp/esr), m: mirror features, np: normalize pan, slf: skip last frames (#frames skipped)
params.face.id.method = 'fmlr'; % one of 'nn', 'lr', 'fmlr', 'svm', 'ssvm'
params.face.id.labeling.method = 'speaking'; % one of 'speaking', 'speaking-gt', 'supervised-abs', 'supervised-frac', 'supervised-frac-min-abs'
params.face.id.labeling.num_abs = 20; % number of tracks to label
params.face.id.labeling.num_frac = 0.1; % fraction of tracks to label (character-wise)
params.face.id.ignore_tracks = {'false_positive', 'trackswitch'};
params.face.id.test_speaker_assigned_tracks = true;  % compare tracks with assigned speaker to model (excluding the features from the same track)
params.face.id.no_features_strategy = {'speaker', 'unknown'}; % what to do if we couldn't find any features for this tracks: 'speaker': assign speaker if any, 'prior': assign most likely person, 'unknown': assign unknown
params.face.id.num_subsample = 2000; % subsample at most that many features for each face model
params.face.id.num_subsample_u = 10000; % subsample at most that many unlabeled features
params.face.id.num_subsample_c = 10000; % subsample at most that many constraints
params.face.id.num_subsample_negatives = params.face.id.num_subsample; % subsample negatives during binary classifier training
params.face.id.num_kernel_prototypes = 10000; % subsample at most that many kernel prototypes
params.face.id.kernel = 'polynomial'; % kernel type
params.face.id.kernelparams.polynomial.order = 2; % polynomial degree (if kernel type == 'polynomial')
params.face.id.kernelparams.rbf.scale = 7.5; %rbf kernel scale (if kernel type == 'rbf')
params.face.id.loss = 'l2'; % 'l2+entropy+constraints'; % loss
params.face.id.add_bias = false;
params.face.id.lambda = 1; % regularization parameter
params.face.id.mu = 1; % weight for entropy loss
params.face.id.gamma = 1; % weight for (neg) constraint loss
params.face.id.slack_C = 1e-4; % slack parameter for SVM training
params.face.id.seed = 0;
params.face.id.leaveout.seed = 0; % seed for random number generator before shuffling tracks
params.face.id.leaveout.leaveout_fold = 0; % which fold to leave out (if 0: disable leaveout)
params.face.id.leaveout.num_folds = 10; % ... of how many folds in total


%% Speaker Parameters

% Basic feature extraction parameters
params.speaker.fs = 16e3; % sampling frequency
params.speaker.analysis_win = 20e-3; % analysis window size for feat-extraction

% GMM model parameters
params.speaker.num_gaussians = 8; % number of gaussians for speaker models
params.speaker.max_train_time = 120; % maximum training time for speaker models
params.speaker.num_coeff = 39; % number of MFCC coefficients

% Params while testing 
params.speaker.test.hopbunch = 1; % how many frames to slide at once
params.speaker.test.winbunch = 1; % how many frames to consider at once

%% Clothing Parameters
% Person tracks type!
params.clothing.persontracks_type = 'ab';

% 3D histogram feature parameters
params.clothing.rgbhist3d.num_bins = 4;
params.clothing.rgbhist3d.truncate_hist = 0.1;

% Colour Structure Descriptor feature parameters
params.clothing.csd_mpeg7.hop = 4; % noverlap = winsize - hop
params.clothing.csd_mpeg7.hue_bins = 8;
params.clothing.csd_mpeg7.sum_bins = 32;

% Clothing location (estimated)
params.clothing.clothingrect.lcut = 0.1; % cut the left 10% of image (bg)
params.clothing.clothingrect.rcut = 0.9; % cut the right 10% of image (bg)
params.clothing.clothingrect.tcut = 0.2; % cut the top 20% of image (face)
params.clothing.clothingrect.bcut = 0.5; % cut the bottom 50% of image (legs/bg)
params.clothing.clothingrect.minArea = 0.25; % atleast 25% of area should be made up of useful image pixels

% Params for checking whether face detection is in person box
params.clothing.faceInPersonBox.lcut = 0.1; % face should exist from left to right end of the bbox
params.clothing.faceInPersonBox.rcut = 0.9;
params.clothing.faceInPersonBox.tcut = 0.0; % face should exist within top to bottom end of the bbox
params.clothing.faceInPersonBox.bcut = 0.25;

% Params for clothing clustering
params.clothing.cluster.linkCut = 0.06; % percentage of max distance at which to cut off the clustering process
params.clothing.cluster.feature_method = 'rgbhist3d';
params.clothing.cluster.featdistance_method = 'euclidean';
params.clothing.cluster.agg_method = 'ward';

% Params for assigning clusters with identities
params.clothing.clusterAssign.face_result_type = 'ALL';
params.clothing.clusterAssign.idThresh = 0.6; % this ratio of cluster faces (1:6) should belong to chosen ID
params.clothing.clusterAssign.totalThresh = 0.10; % this ratio of all possible IDs (including blank) should belong to chosen ID
params.clothing.clusterAssign.stddevThresh = 0.6; % the histogram of chosen cluster's images should not exceed this
params.clothing.clusterAssign.faceperson_association_method = 'tracks'; % alternative being 'tracks'. Selects whether person frames or tracks should be associated with face tracks
params.clothing.clusterAssign.include_scenes_for_unassigned_labeling = 'me'; % 'me' for current scene, 'neighbour' for current and +/- 1 scenes, 'all' for all scenes
params.clothing.clusterAssign.combine_results_frame_to_track = 'mean'; % 'max', 'mean', 'norm1' are the options for combining frame results into track result
params.clothing.clusterAssign.min_scenes_to_label_unassigned = 3; % should find atleast "X" number of assigned clusters within scenes

%% Model Parameters

% Which modalities and options to use
params.model.use_Face = true; % use face energy
params.model.use_Clothing = true; % use person energy
params.model.use_Self = true; % use self energy
params.model.use_Speaker = false; % use speaker penalty
params.model.use_Uniqueness = true; % use uniqueness penalty

% Other parameters
params.model.assoc_type = 'frame';
params.model.initial_tiny_value = 0.05;
params.model.false_positive = 0;
params.model.verbose = false;
params.model.speaker_sigmoid_mididx = 0;
params.model.numchars = -Inf;

% Modality weights
params.model.weights.face = 1;
params.model.weights.clothing = 1;
params.model.weights.self = 1;
params.model.weights.speaker = 2;
params.model.weights.unique = 2;
