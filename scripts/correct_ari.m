%% correct_ari.m
% 
% Correct rotation of Ariscope RGB images (.ari) of tissue. Return L and R
% eye image separately.
%
% Input: arriRGB - RGB image matrix of shape (h,w,3)
%
% Output: arriRGB_leftCorrected - left eye RGB image of same rotation as TIF, shape (w/2, h, 3)
%         arriRGB_rightCorrected - right eye RGB image of same rotation as TIF, shape (w/2, h, 3)
%
% Dependencies: none
% Last edit: 4/29/2019
%
% Author: George Liu

function [arriRGB_leftCorrected, arriRGB_rightCorrected] = correct_ari(arriRGB)

% Isolate L and R eye images
arriRGB_left = arriRGB(:,1:size(arriRGB, 2)/2, :); % L eye, rotated 90 degreees clockwise
arriRGB_right = arriRGB(:,size(arriRGB, 2)/2+1:end, :); % R eye, rotated 90 degrees counter-clockwise

% Correct rotations of left and right images
arriRGB_leftCorrected = rot90(arriRGB_left, 1);
arriRGB_rightCorrected = rot90(arriRGB_right, 3);

end