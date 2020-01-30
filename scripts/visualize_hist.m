%% visualize_hist.m
%
% Visualize multispectral images of tissue using histogram representation 
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
% Dependencies: same_yaxes.m

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

%% Load data
load('alltissue_hist.mat')
[X, y, y_onehot] = hist2ml(alltissue_hist);
d = 21;

% Get mean and std (across specimens) of spectral bands per tissue type
[n, m] = size(X);
nbins = n/d;
num_classes = length(unique(y));

meanX = zeros(n, num_classes);
stdX = zeros(n, num_classes);
for i=1:num_classes
    thisX = X(:, y==i);
    meanX(:, i) = mean(thisX, 2); 
    stdX(:, i) = std(thisX, 0, 2);
end

%% Visualize histograms
figure('DefaultAxesFontSize', 10)
AxesHandles_1 = zeros(num_classes, 1);
% x = 1/nbins:1/nbins:d;
x = 1/nbins:1/nbins:1;
count=0;
for i = 1:num_classes
    y = meanX(:, i);
    err = stdX(:, i);
    
    for j = 1:d
        count = count+1;
        AxesHandles_1(i) = subplot(num_classes,d, count);
        plot(x, y((1:nbins)+(j-1)*nbins))
%         errorbar(x, y, err)
%         title([tissues{i}, ' band ', num2str(j)])
        title(tissues{i})
        xlabel('Bin')
        ylabel('Freq')
    end
end
same_yaxes(AxesHandles_1)

%% Visualize histograms
figure('DefaultAxesFontSize', 10)
AxesHandles_1 = zeros(num_classes, 1);
x = 1/nbins:1/nbins:d;
% x = 1/nbins:1/nbins:1;
count=0;
for i = 1:num_classes
%     y = meanX(:, i);
    y = stdX(:, i);
    err = stdX(:, i);
    
    count = count+1;
    AxesHandles_1(i) = subplot(num_classes,1, count);
    plot(x, y)
%         errorbar(x, y, err)
%         title([tissues{i}, ' band ', num2str(j)])
    hold on
%     plot(x, y+ 
    for j=1:d-1
        xline(x(nbins*j), 'k-');
    end
    hold off
    title(tissues{i})
    xlabel('Bin')
    ylabel('Freq')
    ylim([0, 100000])
end
% same_yaxes(AxesHandles_1)
