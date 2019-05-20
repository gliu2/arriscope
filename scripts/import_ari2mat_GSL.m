%% import_ari2mat_GSL.m
%
% Purpose: Import ari files from Flywheel for given session and acquisition, and
% convert ari raw files to .mat files. One MAT file per tissue type. 
% MAT files should contain one array each, with 21-channel image of 7
% illumination types combined:
%
%       white (Specimen_white20_fIRon.ari) 
%       blue (Specimen_blue17_fIRon.ari)
%       green (Specimen_green17_fIRon.ari)
%       IR (Specimen_ir7_fIRoff.ari) 
%           note that this has NIR blocking filter off (i.e. fiRoff)
%       red (Specimen_red17_fIRon.ari)
%       violet (Specimen_violet17_fIRon.ari)
%       white (Specimen_white17_fIRon.ari)
%  
% Modified from: s_arriGetMeanRGBvalues.m
% Background:
%
% IN THIS SCRIPT we
%   1. Download the data for one specimen type under N lights from the Flywheel database
%   2. unzip the data into a local directory
%   3. concatenate 21 channels (3 RGB * 7 illumination stimuli)
%   4. Save 21-channel image as MAT file (can import into Python scripts)
%
% See also s_arriROISelect.m
%
% Last edit GSL: 5/20/2019
% Dependencies: correct_ari.m, extract_ROImask.m


%% initialize ISET
ieInit;
%% Open up to the data on Flywheel
% the first time you connect to Flywheel 
%       see https://github.com/vistalab/scitran/wiki/Connecting-and-Authentication 
%           if you have done this and cannot run the section below
%               try getting out of Matlab and opening again
st = scitran('stanfordlabs');
st.verify;

% Work in this project
project      = st.lookup('arriscope/ARRIScope Tissue'); 


%% Choose a session and acquisition 
DATE = '"20190515"';

TISSUE_CLASSES = ["Artery", ...
    "Bone", ...
    "Cartilage", ...
    "Dura", ...
    "Fascia", ...
    "Fat", ....
    "Muscle", ...
    "Nerve", ...
    "Skin", ...
    "Parotid", ...
    "PerichondriumWCartilage", ...
    "Vein"];

num_tissues = length(TISSUE_CLASSES);
tissues = cell(num_tissues, 1);
for i=1:num_tissues
    tissues{i} = char(TISSUE_CLASSES(i));
end

for i = 1:num_tissues
    TISSUE = tissues{i};
    disp([' Analyzing tissue ', num2str(i), ' out of ', num2str(num_tissues), ' - ', TISSUE])

    % Keep the double quotes or else Flywheel will read the string as a number.
    thisSession  = project.sessions.findOne(['label=', DATE]);
    thisAcq      = thisSession.acquisitions.findOne(['label=', TISSUE]);
    disp(thisAcq.label); 

    % Choose the ari zip file with the images
    files    = thisAcq.files;
    zipFile = stSelect(files,'name', [TISSUE, '_CameraImage_ari.zip']);
    zipArchive = [TISSUE, '_CameraImage_ari.zip'];

    % Find out the filenames in the zip archive
    zipInfo = thisAcq.getFileZipInfo(zipFile{1}.name);
    stPrint(zipInfo.members,'path')

    %% Unzip all the files
    % make 'local' folder if doesn't exist
    local_foldername = fullfile(arriRootPath,'local');
    if ~exist(local_foldername, 'dir')
       mkdir(local_foldername)
    end
    chdir(local_foldername);
    arriZipFile = thisAcq.getFile(zipArchive);
    arriZipFile.download(zipArchive);
    unzip(zipArchive,thisAcq.label);
    disp('Downloaded and unzipped spd data');




    %% GSL added 4-29-2019: Read the arri image and extract the ROI 
    %   List of 7 (previously 8) light stimuli in order:
    % Bone_arriwhite20_fIRon.ari
    % Bone_blue17_fIRon.ari
    % Bone_green17_fIRon.ari
    % Bone_ir7_fIRoff.ari
    % Bone_red17_fIRon.ari
    % Bone_violet17_fIRon.ari
    % Bone_white17_fIRon.ari
    % (Bone_whitemix17_fIRon.ari) <-- Not using anymore

    % Use created unzipped folder of .ari files to get filenames, instead
    % of zip folder
    % Get a list of all files and folders in local unzipped folder.
    filesUnzippedAll = dir(fullfile(local_foldername, thisAcq.label));
    % Get a logical vector that tells which is a directory.
    dirFlags = [filesUnzippedAll.isdir];
    % Extract only those that are NOT directories.
    filesUnzipped = filesUnzippedAll(~dirFlags);
    
%     nFiles  = length(zipInfo.members);
    nFiles = length(filesUnzipped);
    ip = ipCreate;
    % Histogram window

    % There should be 8 files in zip, one per light stimulus
    NUM_LIGHTS = 8;
    if nFiles ~= NUM_LIGHTS
        disp(['Warning: there are ', num2str(nFiles), ' light stimuli instead of ', num2str(NUM_LIGHTS), ...
            ' based on number of files found in ZIP folder.'])
    end
    % Store RGB values for each light stimulus, then concatenate to form
    % feature matrix for image pixels
    arriRGB_21channels = []; % Combined image matrix of size (h, w, 21) from 7 RGB light stimuli images

    % For each light stimulus
    for ii = 1:nFiles
%         entryName = zipInfo.members{ii}.path;
        entryName = filesUnzipped(ii).name;
        disp(['Working on light stimulus ', num2str(ii), ' out of ', num2str(nFiles), ': ', entryName, ' ...'])
        outName = fullfile(arriRootPath,'local',thisAcq.label,entryName);
        thisAcq.downloadFileZipMember(zipArchive,entryName,outName);
        arriRGB = arriRead(outName);

        % Extract ROI from corrected L eye image
        [arriRGB_leftCorrected, ~] = correct_ari(arriRGB);
        arriRGB_21channels = cat(3,arriRGB_21channels, arriRGB_leftCorrected);
    end

    %% Save out the data from all the measurements from a given specimen
    %
    % To save:
    %  RGBdata_allStimuli, RGB histograms for all light conditions
    %  feature_vectors, (num pixels) x 21 matrix of intensity values, per row:
    %            [arriwhite (3 - RGB), blue (3), green (3), IR (3), red (3),
    %            violet (3), white(3), whitemix(3)]
    %  zipInfo, which contains the file names
    %  class_label, the tissue type
    %  mask

    % Save feature vector and label per image pixels
    class_label = TISSUE;

    % To find the acquisition you can use
    %{
      tst = st.lookup(sprintf('arriscope/ARRIScope Tissue/%s/%s/%s',...
        thisSession.subject.label,thisSession.label,thisAcq.label));
    %}
    sessionLabel = thisSession.label;
    acquisitionLabel  = thisAcq.label;
    fileOrder = stPrint(zipInfo.members,'path');
    outFile = fullfile(arriRootPath,'local',sprintf('%s-%s_GSL',sessionLabel,acquisitionLabel));
    % save(outFile, 'meanRGB','stdRGB','acquisitionLabel','sessionLabel','fileOrder','rect');
    save(outFile, 'arriRGB_21channels','acquisitionLabel','sessionLabel','fileOrder','class_label', '-v7.3');

end

disp('Done!')
