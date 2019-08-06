%% hist2ml.m
%
% Convert output of rawim2hist_folder.m to machine learning style variables
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
%         y - class label matrix of size (1, m). Roww corresponds to tissue class.
%         y_onehot - one-hot class label matrix of size (12, m). 
%
% Last edit GSL: 8/6/2019
% Dependencies: none

function [X, y, y_onehot] = hist2ml(h)

% Assess number of training examples (i.e. tissue samples)
[row, col] = find(~cellfun('isempty', h)); % indices of non-empty cell entries

% Initialize ML-style variables: training data X, labels y
[n_bins, n_bands] = size(h{1,1});
n = n_bins*n_bands; % number of features
m = length(row); % number of training examples
X = zeros(n, m); 
y = zeros(1, m);

% Compute average histogram for each tissue type, across sessions
for i=1:m
    X(:, i) = h{row(i), col(i)}(:); % flatten by concatenating histograms of all spectral bands
    y(i) = row(i); % index of tissue class
end

% One-hot class labels
y_onehot = full(ind2vec(y));

end