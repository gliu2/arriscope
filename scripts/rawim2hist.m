%% rawim2hist.m
%
% Convert raw image to histogram of pixel counts (after masking in tissue). 
% Raw image is matrix (from RGB .mat file imported from .ari file via
% 'import_ari2mat_GSL.m').
% Reduces dimensionality of image data. Assumes permutation invariance.
%
% Preprocesses raw image by dividing element-wise by white paper image of
% corresponding illumination (spectral band). White paper image is
% processed by median 3x3 filter to remove speckle.
%
% Input: im, image matrix of size (height, width, d) where d is number of spectral
%           bands (i.e. channels).
%        mask, mask matrix of size (height, width) indicating pixels
%           corresponding to tissue.
%        im_whitepaper, image matrix of size (height, width, d) of white
%           paper 
%        n_bins, number of bins (int) [optional]
% 
% Output: h, histogram vector of size (b, d) where b is number of bins.
%
% Reference:
% "Deep Gaussian Process for Crop Yield Prediction Based on Remote Sensing
% Data" (2017)
% https://cs.stanford.edu/~ermon/papers/cropyield_AAAI17.pdf
%
% Last edit GSL: 8/13/2019
% Dependencies: none

function h = rawim2hist(im, mask, im_whitepaper, varargin)
if nargin==3
    N_BINS = 100; % number of bins for histogram; fine-tune this hyperparameter
else
    N_BINS = varargin{1};
end

d = size(im, 3); % # spectral bands i.e. channels

% Median filter to remove salt-pepper noise in white paper image
for j=1:d
    im_whitepaper_band = im_whitepaper(:,:,j);
    im_whitepaper(:,:,j) = medfilt2(im_whitepaper_band, [3,3]);
end

% Normalize image by its white paper 
im = im./im_whitepaper;

% Histogram for normalized values [0, 1], set values above 1 to 1.
h = zeros(N_BINS, d);
for k=1:d
    im_band = im(:,:,k); 
    im_band = im_band(logical(mask(:,:,1))); % obtain pixel values within mask of tissue
    im_band = min(im_band, 1); % Set values above 1 to 1 b/c normalized images by white paper
    [counts, ~] = imhist(im_band, N_BINS); 
    h(:, k) = counts;
end

end

% d = size(x, 3); % # spectral bands i.e. channels
% im = x;
% % im = gpuArray(x); % use GPU
% for i = 1:d
%     im_band = im(:, :, i);
%     [counts, binLocations] = imhist(im_band); 
%     hist_band = counts
% end