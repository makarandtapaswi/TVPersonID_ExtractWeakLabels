% Performs some data download, compilation, and messaging operations on first initialization of the repository
global PID

% Create a file in PROJECTROOT/tmp/ to know whether it has been accessed before
tmp_fname = 'tmp/first_init';
if exist(tmp_fname, 'file')
    clear tmp_fname
    return;
end

if ~isdir('tmp'), mkdir('tmp'); end

%% jsonlab
fprintf(2, 'Matlab - JSON interface.\n');
fprintf('http://mathworks.com/matlabcentral/fileexchange/33381-jsonlab--a-toolbox-to-encode-decode-json-files-in-matlab-octave\n');
fprintf('Please download and unpack the folder to "%s/ext/jsonlab" and make sure the file loadjson.m exists in the folder.\n', PID.base_dir);
json_fname = 'ext/jsonlab/loadjson.m';
while ~exist(json_fname, 'file')
    fprintf('Press any key to continue...\n');
    pause;
end
% Check that the loading works
addpath(genpath('ext/jsonlab/'));
try
    loadjson('data/castlist/bbt_s01e01.cast');
    fprintf('Success!\n\n');
catch
    fprintf('Error in reading JSON file. The jsonlab toolbox is not correctly installed.\n');
    delete(tmp_fname);
end


%% DataHash
fprintf(2, 'DataHash for caching intermediate data.\n');
fprintf('http://mathworks.com/matlabcentral/fileexchange/31272-datahash\n');
fprintf('Please download and unpack the folder to "%s/ext/DataHash" and make sure the file DataHash.m exists in the folder.\n', PID.base_dir);
dhash_fname = 'ext/DataHash/DataHash.m';
while ~exist(dhash_fname, 'file')
    fprintf('Press any key to continue...\n');
    pause;
end
% Check that the loading works
addpath(genpath('ext/DataHash/'));
if strcmp(DataHash(5), '2b825db8181456131b9fcc10d5590815');
    fprintf('Success!\n\n');
else
    warning('DataHash is different from what I have. This should be fine in principle.\n');
end


%% Maximal cliques
fprintf(2, 'Compute Maximal Cliques in a graph\n');
fprintf('http://mathworks.com/matlabcentral/fileexchange/30413-bron-kerbosch-maximal-clique-finding-algorithm\n');
fprintf('Using an older version for maintaing compatibility.\n')
fprintf('By continuing you accept the license -- ext/maximalCliques/license.txt\n');
pause;
fprintf('Success!\n\n');


%% Mink - Maxk
fprintf(2, 'Multiple min/max of a vector/matrix\n');
fprintf('http://mathworks.com/matlabcentral/fileexchange/23576-min-max-selection\n');
fprintf('Please download and unpack the folder to "%s/ext/minmaxk" and make sure the file maxk.m exists in the folder.\n', PID.base_dir);
maxk_fname = 'ext/minmaxk/maxk.m';
while ~exist(maxk_fname, 'file')
    fprintf('Press any key to continue...\n');
    pause;
end
% Compile the mex files
try
    cd ext/minmaxk
    minmax_install;
    cd ../../
    fprintf('Success!\n\n');
catch
    error('Error compiling MEX file for minmaxk toolbox');
end


%% Create file
fid = fopen(tmp_fname, 'w');
fprintf(fid, 'Created temporary file on %s\n', date);
fclose(fid);

clear tmp_fname json_fname ans dhash_fname maxk_fname

