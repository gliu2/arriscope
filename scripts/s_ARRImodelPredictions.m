%% s_ARRImodelPredictions.m
%
% Purpose:  
%   Use the raw ARRI RGB sensor values captured under 6 different
%   lights to estimate surface reflectance.  We illustrate with MCC.
%   (Ultimately, we wish to estimate reflectances for tissue.)
%
%   We will use measured tissue reflectances, although it is also possible
%   to predict tissue reflectances if we know the absorbance and scattering
%   properties
%   
% Method:
%   1. Select a collection of surface reflectances (e.g. reflectances for different tissue types)
%   2. Predict the raw ARRI RGB sensor values for each of the measured tissue reflectances
%   3. Calculate the principal components for a set of measured
%   reflectances such that you can describe reflectances by a weighted
%   combination of the principal components 
%       each surface is then described by weights on the principal
%       components
%       Select N basis functions that account for 99% of the variance in
%       the surface reflectances and where N < number of sensor values
%       Do not remove the mean, since some types of tissue (cancer versus
%       non-cancer) differ by the mean (note that in the future, we need to
%       normalize the sensor values such that they are relatively invariant
%       to non-uniform distribution of illumination
%
% Example:
%   We will use the MCC surfaces to illustrate and validate the method
%   Once we have done that, we can replace the MCC surfaces with a
%   collection of reflectances for different tissue types.
%% 1. Selection of surface reflectances

wave = 400:10:700;

% Load the macbeth reflectances
surfaces = ieReadSpectra('MiniatureMacbethChart.mat',wave);
plotReflectance(wave,surfaces);

%% 2. Predicted Sensor values -
% read in the sensor QE and multiply by the lights to get 18 sensors

% Load sensor
arriSensorFname = fullfile(arriRootPath,'data','sensor','ARRIestimatedSensors.mat');
arriQE = ieReadSpectra(arriSensorFname, wave);
plotRadiance(wave,arriQE,'title','ARRI sensor quantum efficiency');

% Load the lights and multiply with sensor QE 
testLights = {'blueSonyLight.mat','greenSonyLight.mat',...
    'redSonyLight.mat','violetSonyLight.mat',...
    'whiteSonyLight.mat','whiteARRILight.mat'};

sensor = zeros(length(wave),numel(testLights)*3);
kk = 0;
for ii = 1:numel(testLights)
    for jj = 1:3
        kk = kk +1;
        thisLight = ieReadSpectra(testLights{ii},wave);
        thisSensor = arriQE(:,jj) .* thisLight;
        sensor(:,kk)= thisSensor(:);
    end
end
plotRadiance(wave,sensor,'title','ARRI QE * Light Spectral Energy');
% set(gca,'yscale','log');

% Predict sensor values for reflectances
predSensorValues = sensor' * surfaces;

%% 3. Principal components analysis
nDim = 6;
[linModel,S,V] = svd(surfaces);
linModel = linModel(:,1:nDim);
plotReflectance(wave,linModel);
xaxisLine;
S = diag(S);
percentV = cumsum(S.^2)/sum(S.^2);

%% 4. Find a N x B matrix that maps N sensor values into B weights 
% Find the weights that are the LS solution to
%    measured = sensor*linModel*wgts
%    measured = A w (A = sensor*linModel)
%    w = measured \ A
A = sensor'*linModel;
wgts = pinv(A)*predSensorValues;
predLowDim = sensor'*linModel*wgts; 
identityLine; grid on; xlabel('Sensor values predicted by the full linear model');ylabel('Sensor values predicted by reduced dim');

%% Get the real sensor values
% Display the raw camera images captured by the ARRIScope camera with the
% NIR filter on for each of the 6 lights
% Then grab the mean R, G and B values for each of the 24 patches captured
% under each of the 6 lights
% Notice that the raw camera image captured under violet17 has very little
% signal and is, therefore, noisy

chdir(fullfile(arriRootPath,'data','macbethColorChecker','MacbethIRON'));

rgbImages = {'MacbethCc_blue17_fIRon.ari','MacbethCc_green17_fIRon.ari', ...
    'MacbethCc_red17_fIRon.ari', 'MacbethCc_violet17_fIRon.ari', ...
    'MacbethCc_white17_fIRon.ari','MacbethCc_arriwhite20_fIRon.ari'};

ip = ipCreate;
ip = ipSet(ip,'correction method illuminant','none');
ip = ipSet(ip,'conversion method sensor','none');

showSelection = true;   % Do or do not bring up the window
fullData      = false;  % Just returns the mean in each patch
cornerPoints = [
    79   291;
   490   292;
   489    19;
    79    22];

mRGB = [];
for ii=1:numel(rgbImages)
    img = arriRead(rgbImages{ii},'image','left');
    img = imresize(img,1/4);
    ip  = ipSet(ip,'result',img); 
    thisRGB = macbethSelect(ip,showSelection,fullData,cornerPoints);
    mRGB = [mRGB; thisRGB'];
end

scatter(mRGB(:)/max(mRGB(:)),predSensorValues(:)/max(predSensorValues(:)));
identityLine; grid on; xlabel('Real sensor values');ylabel('Sensor values predicted by the full linear model');

scatter(mRGB(:)/max(mRGB(:)),predLowDim(:)/max(predLowDim(:)));
identityLine; grid on; xlabel('Real sensor values');ylabel('Sensor values predicted by lower dim model');

% Note:  we can approximate the MCC reflectances using as few at 3 spectral
% basis functions in order to predict the ARRI sensor values.  This is
% because we are projecting reflectances (represented by 31 numbers) down
% into sensors (represented by 18 numbers - RGB under 6 lights).  


%%  5.  Predicted reflectance comparisons

% If we want to PREDICT 18 sensor values (RGB under 18 lights) for the 24
% color patches, we only need to represent the spectral reflectances of the
% 24 color patches using 3 principal components. (see above at how well we
% can predict the 18 sensor values when DIM = 3)

% However, if we want to PREDICT spectral reflectances of each of the 24
% color patches, given the 18 sensor values, we need to represent the
% spectral reflectances of the 24 color patches using 6 principal
% components.

% Why is that?  Well, each of the 24 color patches is represented by 31
% numbers, and these are projected down into 18 numbers
% But going the other way, we have 18 sensor values attempting to predict
% 31 wavelength samples for each color patch. 

plotReflectance(wave,surfaces);
hold on;
predReflectance = linModel*wgts;
plot(wave,predReflectance,'--');
hold off

ieNewGraphWin;
scatter(surfaces(:),predReflectance(:));
identityLine; grid on; xlabel('reflectance');ylabel('predicted reflectance');

