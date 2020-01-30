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
% Last edit GSL: 8/13/2019
% Dependencies: rawim2hist.m

% Hyper-parameters to fine tune
N_BINS = 100;

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

% Paths hard-coded
parent_path = 'C:\Users\CTLab\Documents\George\Python_data\arritissue_data\train_mat'; % .mat files
path_whitepaper = 'C:\Users\CTLab\Documents\George\Python_data\arritissue_data\whitepaper'; % .mat files
mask_path = 'C:\Users\CTLab\Documents\George\Python_data\arritissue_data\masks\';

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

% Load histograms of images per tissue-type per session
alltissue_hist = cell(num_tissues, num_sessions);
for k=1:num_sessions
    session = subFolders(k).name;
    disp(['Working on session: ', session, ' (', num2str(k), ' out of ', num2str(num_sessions), ') ...'])
    
    % Load white paper image
    file_whitepaper = dir(fullfile(path_whitepaper, [session, '*.mat']));
    load(fullfile(path_whitepaper, file_whitepaper.name));
    im_whitepaper = arriRGB_21channels;
    
    % Iterate through tissue .mat data acquired during this session date
    session_listing = dir(fullfile(parent_path, subFolders(k).name, '*.mat'));
    for j=1:num_tissues
        tissuetype = tissues{j};
        tissue_filename = [session, '-', tissuetype, '_GSL.mat'];
        tissue_fullpath = fullfile(parent_path, subFolders(k).name, tissue_filename);
        if ~isfile(tissue_fullpath)
            disp(['  Skip ', tissuetype])
            continue
        end
        
        % Load raw image data from .mat file
        disp(['  ', tissuetype, ' ...'])
        load(tissue_fullpath); % load arriRGB_21channels variable into workspace
        im = arriRGB_21channels; % 
        
        % Load mask for tissue type and session
        mask_name = ['*_', tissuetype, 'Mask.png'];
        mask_listing = dir(fullfile(mask_path, session, mask_name));
        mask = imread(fullfile(mask_path, session, mask_listing.name));
        
        % Get histogram from raw image
        alltissue_hist{j, k} = rawim2hist(im, mask, im_whitepaper, N_BINS);
    end
end

disp('Save histograms to alltissue_hist.mat ...')
save('alltissue_hist_bins200.mat', 'alltissue_hist')

disp('Done.')