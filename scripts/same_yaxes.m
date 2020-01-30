%% same_yaxes.m
% 
% Set subplot y-axis scales the same
%
% Input: AxesHandles - vector of axes handles, one for each subplot
%
% Code from: https://www.mathworks.com/matlabcentral/answers/32153-subplots-with-equal-nice-y-axes-is-there-a-function
%
% Dependencies: none
% Last edit: 4/22/2019
%
% Author: George Liu

function same_yaxes(AxesHandles)

allYLim = get(AxesHandles, {'YLim'});
allYLim = cat(2, allYLim{:});
set(AxesHandles, 'YLim', [min(allYLim), max(allYLim)]);

end