%% rawim2hist_folder.m
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
% Output: h, histogram vector of size (b, d) where b is number of bins.
%
% Reference:
% "Deep Gaussian Process for Crop Yield Prediction Based on Remote Sensing
% Data" (2017)
% https://cs.stanford.edu/~ermon/papers/cropyield_AAAI17.pdf
%
% Last edit GSL: 8/6/2019
% Dependencies: none

% Paths hard-coded
parent_path = 'C:\Users\CTLab\Documents\George\Python_data\arritissue_data\train_mat'; % .mat files
path_whitepaper = 'C:\Users\CTLab\Documents\George\Python_data\arritissue_data\whitepaper'; % .mat files

% Access folder of ARI raw .mat data
listing = dir(parent_path);
dirFlags = [listing.isdir] & ~strcmp({listing.name},'.') & ~strcmp({listing.name},'..');
% Extract only those that are directories.
subFolders = listing(dirFlags);
% Print folder names to command window.
for k = 1 : length(subFolders)
  fprintf('Sub folder #%d = %s\n', k, subFolders(k).name);
end
num_sessions = length(subFolders);

for k=1:num_sessions
    session = subFolders(k).name;
    
    % Load white paper image
    file_whitepaper = dir(fullfile(path_whitepaper, [session, '*.mat']));
    load(fullfile(path_whitepaper, file_whitepaper.name));
    im_whitepaper = arriRGB_21channels;
    
    % Iterate through tissue .mat data acquired during this session date
    session_listing = dir(fullfile(parent_path, subFolders(k).name, '*.mat'));
end

%TODO: load all .mat data as histograms
DATE = '20190520';
TISSUETYPE = 'muscle'; 

h = rawim2hist(im, mask, im_whitepaper);