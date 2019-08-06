%% classify_hist.m
%
% Classify multispectral images of tissue using histogram representation 
% of ARI raw data. 
%
% Beforehand run:
%   (1) rawim2hist_folder.m  
%   (2) hist2ml.m
% 
% Input: h - histogram cell array of size (num_tissues, num_sessions), where 
%            entry h{i, j} is histogram for i-th tissue on the j-th date. 
%            Histogram vectors are of size (b, d) where b is number of 
%            bins and d is number of spectral bands/channels.
%
% Output: X - training data matrix of size (n, m), where n is number of
%             features (b*d, flattened and concatenated individual
%             histograms) and m is number of training examples, i.e. unique
%             tissue specimens.
%         y - one-hot class label matrix of size (12, m). 
%             Row corresponds to tissue index in TISSUE_CLASSES:
%
% Last edit GSL: 8/6/2019
% Dependencies: none

% Tissue types hard-coded
TISSUE_CLASSES = [
    "Artery"
    "Bone"
    "Cartilage"
    "Dura"
    "Fascia"
    "Fat"
    "Muscle"
    "Nerve"
    "Parotid"
    "PerichondriumWCartilage"
    "Skin"
    "Vein"
    ];
num_tissues = length(TISSUE_CLASSES);
tissues = cell(num_tissues, 1);
for i=1:num_tissues
    tissues{i} = char(TISSUE_CLASSES(i));
end

% add empty entry to end for confusion matrix plot
tissues_pad = tissues;
tissues_pad{end+1} = [];

%% Train softmax regression
net = trainSoftmaxLayer(X, y_onehot);
y_hat = net(X);
p = plotconfusion(y_onehot, y_hat, 'Softmax (No-Holdout)');
p.CurrentAxes.YTickLabel = tissues_pad;
p.CurrentAxes.XTickLabel = tissues_pad;

% Cross-validate
K_FOLDS = 10;

m = size(X,2);
partitions = 1:floor(m/K_FOLDS):m;
partitions(end) = m+1;

X_shuffled = X(:, randperm(m)); % permute columns
for i=1:K_FOLDS
    if i==1
        Xtrain = X_shuffled(:, partitions(i):partitions(i+1)-1);
    elseif i==K_FOLDS
%         Xtrain = X_shuffled(:, partitions(i):partitions(i+1)-1);
    else
    
    end
    
    Xval
end