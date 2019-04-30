%% extract_ROImask.m
% 
% Extract data from Ariscope RGB images of tissue, PNG or TIF.
% Input: im - RGB image matrix of shape (h,w,3)
%        mask - mask matrix of same shape as im
% Output: ari_ROI - XW (space-wavelength) matrix of size (m, 3) with 3 columns for r, g, and b values for m pixels in ROI 
%
% Dependencies: iset
% Last edit: 4/29/2019
%
% Author: George Liu

function roi_rgb = extract_ROImask(im, mask)

    % Extract ROIs for original tissue using mask
    mask_bw = imbinarize(mask); % convert double logical to binarized logical mask

    im_r = im(:,:,1);
    im_g = im(:,:,2);
    im_b = im(:,:,3);

    roi_r = im_r(mask_bw(:,:,1));
    roi_g = im_g(mask_bw(:,:,2));
    roi_b = im_b(mask_bw(:,:,3));
    
    roi_rgb = [roi_r, roi_g, roi_b]; 

end