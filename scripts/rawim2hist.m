%% rawim2hist.m
%
% Convert raw image to histogram of pixel counts (after masking in tissue). 
% Raw image is matrix (from RGB .mat file imported from .ari file via
% 'import_ari2mat_GSL.m').
% Reduces dimensionality of image data. Assumes permutation invariance.
%
% Input: x, image matrix of size (height, width, d) where d is number of spectral
%           bands (i.e. channels).
%        m, mask matrix of size (height, width) indicating pixels
%           corresponding to tissue.
% Output: h, histogram vector of size (bxd, 1) where b is number of
%            unique discrete pixel values.
%
% Reference:
% "Deep Gaussian Process for Crop Yield Prediction Based on Remote Sensing
% Data" (2017)
% https://cs.stanford.edu/~ermon/papers/cropyield_AAAI17.pdf
%
% Last edit GSL: 8/5/2019
% Dependencies: extract_ROImask.m

function h = rawim2hist(x, m)

d = size(x, 3); % # spectral bands i.e. channels
im = x;
% im = gpuArray(x); % use GPU
for i = 1:d
    im_band = im(:, :, i);
    [counts, binLocations] = imhist(im_band); 
    hist_band = counts
end