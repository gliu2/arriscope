%% GSL 4-29-2019: Select folder containing .mat files of tissue
disp('Select folder containing .mat files of tissue extracted feature vectors:')
selpath3 = uigetdir();
dir_mat = dir(fullfile(selpath3, '*.mat'));
numfiles3 = length(dir_mat);

% For each .mat file, import feature vectors as m x 21 matrix X,
% where rows of X correspond to points and columns correspond to variables
X = [];
y = [];
for mm = 1:numfiles3
    disp(['Working on MAT file ', num2str(mm), ' out of ', num2str(numfiles3), ': ', dir_mat(mm).name, ' ...'])
    mat_filename = dir_mat(mm).name;
    load(fullfile(selpath3, mat_filename))
    
    % Save all feature vectors into big matrix X
    X = [X; feature_vectors];
    
    % Save class labels
    class_label = convertCharsToStrings(class_label); % Ensure class label is string, not char
    num_ROIpixels = size(feature_vectors, 1);
    y = [y; repmat(class_label, num_ROIpixels, 1)];
end
disp('Done importing MAT data.')


%% Perform k-means clustering on X
% Cut off whitemix RGB features
X2 = X(:, 1:end-3);

stream = RandStream('mlfg6331_64');  % Random number stream
options = statset('UseParallel',1,'UseSubstreams',1,...
    'Streams',stream);

tic; % Start stopwatch timer
% [idx,C,sumd,D] = kmeans(X, 12);
[idx,C,sumd,D] = kmeans(X2,12,'Options',options,'MaxIter',10000,...
    'Display','final','Replicates',10);
toc % Terminate stopwatch timer