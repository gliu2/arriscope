% describe_hist_ariraw.m
% Analyze histograms of raw ari images (.mat file)
% Save per-band image (fig and png) and histograms (fig and png).
%
% To use: change DATE and TISSUETYPE for correct figure name saving
%
% Last edit: 8/5/2019
% Dependencies: none

DATE = '20190520';
TISSUETYPE = 'muscle'; 

% Load white paper image
path_whitepaper = 'C:\Users\CTLab\Documents\George\Python_data\arritissue_data\whitepaper';
file_whitepaper = dir(fullfile(path_whitepaper, [DATE, '*.mat']));
load(fullfile(path_whitepaper, file_whitepaper.name));
im_whitepaper = arriRGB_21channels;

%% Median filter to remove salt-pepper noise in white paper image
for j=1:21
    im_whitepaper_band = im_whitepaper(:,:,j);
    im_whitepaper(:,:,j) = medfilt2(im_whitepaper_band, [3,3]);
end

%% Select mat raw image
disp('Select raw mat image:')
[file,path] = uigetfile('C:\Users\CTLab\Documents\George\Python_data\arritissue_data\*');
load(fullfile(path, file)); % arriRGB_21channels variable is loaded into workspace here
% arriRGB_21channels = imread(fullfile(path, file));

% % Normalize image by its white paper 
arriRGB_21channels = arriRGB_21channels./im_whitepaper;

%% Select mask
disp('Select mask:')
[file,path] = uigetfile('C:\Users\CTLab\Documents\George\Python_data\arritissue_data\masks\*.png');
mask1 = imread(fullfile(path, file));

%% Open spectral band images and histograms, output stats
disp('Opening band images...')
for k=1:21
    h=figure(k); image(arriRGB_21channels(:,:,k)); colorbar, figname=[DATE, '_', TISSUETYPE, '_image_band', num2str(k)]; title(['Band ', num2str(k), ' out of 21']), saveas(h, figname, 'fig'), saveas(h, figname, 'png')
end

disp('Histograms...')
for k=1:21
%     h=figure(k); thisim=arriRGB_21channels(:,:,k); thisim=thisim(logical(mask1(:,:,1))); histogram(thisim); figname=[DATE, '_', TISSUETYPE, '_hist_band', num2str(k)]; title(['Histogram of band ', num2str(k), ' out of 21']), xlabel('Bin'), ylabel('Count'), saveas(h, figname, 'fig'), saveas(h, figname, 'png')
    % Cutoff histogram at 1 for normalized images by white paper 
    h=figure(k); thisim=arriRGB_21channels(:,:,k); thisim=thisim(logical(mask1(:,:,1))); histogram(min(thisim, 1)); xlim([0, 1]), figname=[DATE, '_', TISSUETYPE, '_hist_band', num2str(k)]; title(['Histogram of band ', num2str(k), ' out of 21']), xlabel('Bin'), ylabel('Count'), saveas(h, figname, 'fig'), saveas(h, figname, 'png')
end

disp('Max vals')
for k=1:21
    thisim=arriRGB_21channels(:,:,k); thisim=thisim(logical(mask1(:,:,1))); disp(nanmax(thisim(~isinf(thisim))))
end

disp('99th percentile')
for k=1:21
    thisim=arriRGB_21channels(:,:,k); thisim=thisim(logical(mask1(:,:,1))); disp(prctile(thisim(~isinf(thisim)), 99))
end

disp('Mean')
for k=1:21
    thisim=arriRGB_21channels(:,:,k); thisim=thisim(logical(mask1(:,:,1))); disp(nanmean(thisim(~isinf(thisim))))
end

disp('Std')
for k=1:21
    thisim=arriRGB_21channels(:,:,k); thisim=thisim(logical(mask1(:,:,1))); disp(nanstd(thisim(~isinf(thisim))))
end

disp('Done')