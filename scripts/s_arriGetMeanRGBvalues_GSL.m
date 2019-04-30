%% s_arriGetMeanRGBvalues.m
%
% Purpose: Jared made measurements stored in Arriscope Tissue from
% cadaver data.  This routine 
%
%   Specifies a Session and Acquisition
%   Specifies a rect (see s_arriROISelect)
%   Reads the relevant Arri camera files
%   Returns the ARRI RGB raw camera values for the specimen illuminated under the different lights 
%       white (Specimen_white20_fIRon.ari) 
%       blue (Specimen_blue17_fIRon.ari)
%       green (Specimen_green17_fIRon.ari)
%       IR (Specimen_ir7_fIRoff.ari) 
%           note that this has NIR blocking filter off (i.e. fiRoff)
%       red (Specimen_red17_fIRon.ari)
%       violet (Specimen_violet17_fIRon.ari)
%       white (Specimen_white17_fIRon.ari)
%       whitemix (Specimen_whitemix17_fIRon.ari) 
%  
%
% Background:
%
% IN THIS SCRIPT we
%   1. Download the data for one specimen type under N lights from the Flywheel database
%   2. unzip the data into a local directory
%   3. Select a rectangular region of pixels from one camera image (rect)
%   4. Use that rect to select and calculate the mean R, G and B raw camera
%   pixel values for all camera images (i.e. corresponding pixels for
%   specimen under all N lights)
%
% JEF  SCIENSTANFORD, 2019
%
% See also s_arriROISelect.m
%
% TODO:
%   create a warning for saturated pixel values
%
% Last edit GSL: 4/29/2019
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


%% GSL 4-29-2019: Select folder containing masks of tissue images
disp('Select folder containing masks of tissue images:')
selpath2 = uigetdir();
dir_csv2 = dir(fullfile(selpath2, '*.png'));
numfiles2 = length(dir_csv2);

%% Choose a session and acquisition 
DATE = '"20190424"';

% tissues = cell(1,1);
% tissues{1} = 'Skin';
% % TISSUE = 'Cartilage';

tissues = cell(8,1);
tissues{1} = 'Bone';
tissues{2} = 'Dura';
tissues{3} = 'Fascia';
tissues{4} = 'Fat';
tissues{5} = 'Muscle';
tissues{6} = 'Nerve';
tissues{7} = 'Parotid';
tissues{8} = 'Vein';

num_tissues = length(tissues);
for i = 1:num_tissues
    TISSUE = tissues{i};
    disp([' Analyzing tissue ', num2str(i), ' out of ', num2str(num_tissues), ' - ', TISSUE])

    % Keep the double quotes or else Flywheel will read the string as a number.
    thisSession  = project.sessions.findOne(['label=', DATE]);
    thisAcq      = thisSession.acquisitions.findOne(['label=', TISSUE]);
    % thisSession  = project.sessions.findOne('label="20190412"');
    % thisAcq      = thisSession.acquisitions.findOne('label=Bone');
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


    %% GSL added 4-29-2019: Load mask for tissue type

    % Find tissue mask in selected folder, if exists
    for nn = 1:numfiles2
        filename = dir_csv2(nn).name;
        if startsWith(filename, TISSUE)
            mask_path = fullfile(selpath2, filename);
            disp(['Found mask path: ', mask_path])
            break
        elseif nn == numfiles2
            disp(['Warning: mask does not exist for tissue type ', TISSUE])
        end
    end

    % Read mask
    mask = imread(mask_path);


    %% GSL added 4-29-2019: Read the arri image and extract the ROI 
    %   List of 8 light stimuli in order:
    % Bone_arriwhite20_fIRon.ari
    % Bone_blue17_fIRon.ari
    % Bone_green17_fIRon.ari
    % Bone_ir7_fIRoff.ari
    % Bone_red17_fIRon.ari
    % Bone_violet17_fIRon.ari
    % Bone_white17_fIRon.ari
    % Bone_whitemix17_fIRon.ari

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
    RGBdata_allStimuli = cell(nFiles, 1);
    feature_vectors = []; % feature vectors combined all stimuli

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
        rgbData = extract_ROImask(arriRGB, mask); 

        % dipslay correct L eye image
        ip = ipSet(ip,'display output',arriRGB_leftCorrected);
        ip = ipSet(ip,'name',entryName);
        ipWindow(ip);

        c = {'r','g','b'};
        ieNewGraphWin;
        for jj=1:3
            histogram(RGB2XWFormat(rgbData(:,jj)),500,'FaceColor',c{jj},'EdgeColor',c{jj});
            hold on
        end
        xlabel('Value'); ylabel('Count'); title(strrep(entryName,'_',' '))

        % Store feature vector of RGB values for all pixels per light stimulus 
        RGBdata_allStimuli{ii} = rgbData;
        % concatenate feature vectors horizontally to get feature vector in each
        % row per pixel
        feature_vectors = [feature_vectors, RGBdata_allStimuli{ii}];

    end

    %% Save out the data from all the measurements from a given specimen
    %
    % To save:
    %  RGBdata_allStimuli, RGB histograms for all light conditions
    %  feature_vectors, (num pixels) x 24 matrix of intensity values, per row:
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
    save(outFile, 'RGBdata_allStimuli','feature_vectors','acquisitionLabel','sessionLabel','fileOrder','class_label', 'mask');

end

disp('Done!')

% %% Read the arri image and select the rect 
% 
% % Select the file that will be used to determine rect (image captured with ARRI white
% entryName = zipInfo.members{1}.path;
% outName = fullfile(arriRootPath,'local',thisAcq.label,entryName);
% % thisAcq.downloadFileZipMember(zipArchive,entryName,outName);
% 
% % This rect should have pixels that are not saturated 
% % The rect will be used to grab pixels in all other images of the same
% % specimen under different lighting conditions
% 
% arriRGB = arriRead(outName);
% ip = ipCreate;
% ip = ipSet(ip,'display output',arriRGB);
% ipWindow(ip);
% 
% % Pick a region to use to get the other values - 
% % select a region that has no saturated pixel values
% [~,rect] = ieROISelect(ip);
% 
% disp(rect)
% % thisRect = ieROIDraw(rect);
% 
% %% Use rect for selecting the mean RGB values 
% % We selected a region (rect) that does not have saturated pixel values
% % We assume that this area will not be saturated for the same specimen under different lights
% 
% nFiles  = length(zipInfo.members);
% meanRGB = zeros(nFiles,3);
% stdRGB  = zeros(nFiles,3);
% ip = ipCreate;
% 
% % Histogram window
% 
% for ii = 1:nFiles
%     entryName = zipInfo.members{ii}.path;
%     outName = fullfile(arriRootPath,'local',thisAcq.label,entryName);
%     thisAcq.downloadFileZipMember(zipArchive,entryName,outName);
%     arriRGB = arriRead(outName);
%     ip = ipSet(ip,'display output',arriRGB);
%     ip = ipSet(ip,'name',entryName);
%     ipWindow(ip);
%     roiData = imcrop(arriRGB,rect);
%     rgbData = RGB2XWFormat(roiData);
%     
%     c = {'r','g','b'};
%     ieNewGraphWin;
%     for jj=1:3
%         histogram(RGB2XWFormat(rgbData(:,jj)),500,'FaceColor',c{jj},'EdgeColor',c{jj});
%         hold on
%     end
%     xlabel('Value'); ylabel('Count'); title(strrep(entryName,'_',' '))
%     
%     % display the rectangular region
%     [shapeHandle,ax] = ieROIDraw('ip','shape','rect','shape data',rect);
%     % delete(shapeHandle);
%     xwData = RGB2XWFormat(roiData);
%     meanRGB(ii,:) = mean(xwData)';
%     stdRGB(ii,:)  = std(xwData)';
% end
% 
% %% Save out the data from all the measurements from a given speciment
% %
% % To save:
% %  meanRGB, stdev of pixel values
% %  thisAcq
% %  zipInfo, which contains the file names
% %  rect
% 
% % To find the acquisition you can use
% %{
%   tst = st.lookup(sprintf('arriscope/ARRIScope Tissue/%s/%s/%s',...
%     thisSession.subject.label,thisSession.label,thisAcq.label));
% %}
% sessionLabel = thisSession.label;
% acquisitionLabel  = thisAcq.label;
% fileOrder = stPrint(zipInfo.members,'path');
% outFile = fullfile(arriRootPath,'local',sprintf('%s-%s',sessionLabel,acquisitionLabel));
% save(outFile, 'meanRGB','stdRGB','acquisitionLabel','sessionLabel','fileOrder','rect');
% 
% %%