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


%% 5-6-19: Convert class labels (y) to numerical class labels via categorical array, in order:
classes = ["Artery", "Bone", "Cartilage", "Dura", "Fascia", "Fat", "Muscle", "Nerve", "Skin", "Parotid", "PerichondriumWCartilage", "Vein"];
y_label = single(categorical(y, classes));
save('FreshCadaver004_20190429_data_5-6-19_pyfriendly.mat', 'X', 'y_label', '-v7.3')

%% Perform k-means clustering on X
% Cut off whitemix RGB features
X2 = single(X(:, 1:end-3));

stream = RandStream('mlfg6331_64');  % Random number stream
options = statset('UseParallel',1,'UseSubstreams',1,...
    'Streams',stream);

tic; % Start stopwatch timer
% [idx,C,sumd,D] = kmeans(X, 12);
[idx,C,sumd,D] = kmeans(X2,12,'Options',options,'MaxIter',10000,...
    'Display','final','Replicates',10);
toc % Terminate stopwatch timer

%% 5-6-19: Calculate mean and standard deviation of each tissue type
B = categorical(y);
classes = unique(B, 'stable');
% A = double(B);
% y_one_hot = ind2vec(A')';
num_classes = size(classes, 1);

%%
num_features = size(X, 2);
class_mean = zeros(num_classes, num_features);
class_std = zeros(num_classes, num_features);
B_expanded = repmat(B, 1, num_features);
for nn = 1:num_classes
    this_class = classes(nn);
    disp(['Working on ', num2str(nn), ' out of ', num2str(num_classes), ': ', this_class])
    X_thisclass = reshape(X(B_expanded==this_class), [], 24);
    
    % Calculate metrics
    class_mean(nn, :) = mean(X_thisclass);
    class_std(nn, :) = std(X_thisclass);
end

% Disp results
disp([ 'Tissue type' , ' ', 'Mean', ' ', 'Std'])
for nn = 1:num_classes
    disp([ classes(nn) , ' ', num2str(class_mean(nn)), ' ', num2str(class_std(nn))])
end

%% Calculate training error with PDF score
class_std_inv = class_std .^ -1;
W = class_std_inv;
B = -diag(class_std_inv*class_mean');
y_scores = W*X' + B; % lower score is more likely that class
y_pred_not = softmax(y_scores);
y_pred = 1 - y_pred_not;
% y2 = pdf('Normal',x,mu,sigma)
