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
% Dependencies: none (MATLAB Bioinformatics Toolbox for crossvalind)

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
tissues_cat = categorical(TISSUE_CLASSES);

% add empty entry to end for confusion matrix plot
tissues_pad = tissues;
tissues_pad{end+1} = [];

%% Load data
% obtain "alltissue_hist" variable from output of rawim2hist_folder.m
[X, y, y_onehot] = hist2ml(alltissue_hist);

%% Train softmax regression
net = trainSoftmaxLayer(X, y_onehot);
y_hat = net(X);
p = plotconfusion(y_onehot, y_hat, 'Softmax (No-Holdout)');
p.CurrentAxes.YTickLabel = tissues_pad;
p.CurrentAxes.XTickLabel = tissues_pad;

%% Cross-validate
K_FOLDS = 10;
m = size(X,2);

indices = crossvalind('Kfold', m, K_FOLDS);
y_hat_i = cell(K_FOLDS, 1);
C_i = cell(K_FOLDS, 1);
y_pred_all = zeros(1, m);
for i=1:K_FOLDS
    disp(['Working on fold ', num2str(i), ' out of ', num2str(K_FOLDS)]);
    test = (indices == i); 
    train = ~test;
    
%     %Multispectral classification
%     imtype = 'Multispectral';
%     net = trainSoftmaxLayer(X(:,train), y_onehot(:,train));
%     y_hat_i{i} = net(X(:,test));
    
    %RGB Classification
    imtype = 'RGB';
    net = trainSoftmaxLayer(X(1:300,train), y_onehot(:,train));
    y_hat_i{i} = net(X(1:300,test));
    
    % Compile confusion matrices
    [~, y_pred_i] = max(y_hat_i{i}, [], 1);
    y_pred_all(test) = y_pred_i;
    C_i{i} = confusionmat(y(test), y_pred_i);
end

% Display confusion matrix
C_all = confusionmat(y, y_pred_all);
figure
cc = confusionchart(C_all, tissues_cat, 'RowSummary','row-normalized','ColumnSummary','column-normalized');
acc = sum(diag(C_all))/sum(C_all, 'all');
title([imtype, ' Acc ', num2str(acc)])