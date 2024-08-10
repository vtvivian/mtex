%% MTEX TrueEBSD
% Description
% main script to run trueEBSD workflow
% MATLAB R2023a
% local mtex version - forked from feature/grain3d, approx mtex6.0.beta3
% SO3 folder replaced with mtex6.0.beta3 release because wignerTrafo mex
% files were not working (probably compiled for a different matlab release)
%
% Inputs 
% dataName = @char array, relative path to dataset from
%       fullfile(cd,'\..\Data\') 
% loadDemoData_<dataName1>.m  user-created import script where 
%       dataName1 = dataName with illegal characters removed (non alphabetic, 
%   numeric, or underscore). See dataLoader/loadDemoData.m for more
%   information on how to write the loadDemoData_<dataName1>.m script.
% setSave = do you want to save outputs? 1 (yes) or 0 (no)
% 
% Outputs
% Default save dir savepname = fullfile(cd,'..\Data\mtexOut\', dataName,timestamp);
% Save: plotted images, MAT file, command window outputs, copy of source code for current run
% 

clear; close all; home;

%% Check and add MATLAB paths

[mpath,~,~] = fileparts(matlab.desktop.editor.getActiveFilename);

addpath(genpath(mpath));
warning('off','MATLAB:rmpath:DirNotFound');
rmpath(genpath(fullfile(cd,'\..\Data\mtexOut')));

%navigate to MTEX path in parent folder and load this
addpath(fullfile(mpath,'..\..\..\..'));
cd(fullfile(mpath,'..\..\..\..'));
startup_mtex;

%go back to trueEbsd code folder
[mpath,mname,~] = fileparts(matlab.desktop.editor.getActiveFilename);
cd(mpath);

%% Import data + file saving
tic

dataName = 'copper\ID29';    
imgList = loadDemoData(dataName);

% file saving housekeeping
setSave = 1;
timestamp = char(datetime('now'),'yyMMdd_HHmm');
savepname = fullfile(cd,'..\Data\mtexOut\', dataName,timestamp);

if setSave
    if ~exist (savepname, 'dir')
        mkdir(savepname);
    end
    diary(fullfile(savepname,[removeweirdchars(dataName) '_log.txt']));
    diary on
end

disp(['TrueEBSD output log for date_time ' timestamp '.']);
if setSave
    disp(['Outputs and log files for ' dataName ' will be saved in ' savepname]);
else
    disp(['Output and log files for ' dataName ' will not be saved']);
end

%% set up trueEBSD job
% job = trueEbsd(disImgEBSD, disImgNF, disImgFF, disImgBSE);

job = trueEbsd(imgList{:});

t1  = toc;
disp(['Finished set up trueEBSD job for ' dataName ' in ' num2str(t1,'%.1f') ' seconds']);
%% resize images to match pixel size and FOV
% images in job.resizedList all have pixels in the same positions

pixSzIn = 0; %set to 0 to use default pixel size
% or type in a number in microns e.g. % pixSzIn = 0.2; 

job = pixelSizeMatch(job,pixSzIn);

t1  = toc;
disp(['Finished resize images to match pixel size and FOV for ' dataName ' in ' num2str(t1,'%.1f') ' seconds']);

%% optionally change cross-correlation ROI size and number
% this commented-out section shows syntax for what you can do
%{
customSetXCF1.ROISize=512; % 4x biggest shift
customSetXCF1.NumROI=struct;
customSetXCF1.NumROI.x = 40; %  as many ROI as grains in FOV
customSetXCF1.NumROI.y = round(customSetXCF1.NumROI.x * size(job.resizedList{1}.img,1)/size(job.resizedList{1}.img,2)); % follow image aspect ratio
customSetXCF1.XCFMesh=250; % correlation peak upsampling, default 250
customSetXCF1.xcfImg = 'edge';

customSetXCF2 = customSetXCF1;
customSetXCF2.ROISize=512;
customSetXCF2.xcfImg = 'edge';

% assign customSetXCF
% job.resizedList{1}.setXCF{1} = customSetXCF1;
job.resizedList{3}.setXCF{1} = customSetXCF2;
% or just rewrite individual properties
job.resizedList{3}.setXCF{1}.ROISize = 256;
job.resizedList{4}.setXCF{1}.xcfImg = 'img';
job.resizedList{5}.setXCF{1}.xcfImg = 'img';
%}

%% calculate image distortions --> output job.shifts
% calculate ROI shifts (1 shift per ROI box in image) and 
% fit to a distortion model (1 shift vector per pixel)
% job.shifts contains information about the shift vectors for each image
% pair

job = calcShifts(job,'fitErr');

t1  = toc;
disp(['Finished calculate image shifts and fit distortion models for ' dataName ' in ' num2str(t1,'%.1f') ' seconds']);

%% undistort images
% apply pixel shifts so that images in job.undistortedList 
% can be overlaid and have matching spatial features

job = undistort(job);

t1  = toc;
disp(['Finished remove image distortions for ' dataName ' in ' num2str(t1,'%.1f') ' seconds']);

%% Plotting script
% export images before and after distortion correction

try %in case this fails, still save the data!
    trueEbsdPlots
    t1  = toc;
    disp(['Finished plot figures for ' dataName ' in ' num2str(t1,'%.1f') ' seconds']);

catch ME
    ME1 = ME;
    warning(ME.message);
    t1  = toc;
    disp(['Failed plot figures for ' dataName ' in ' num2str(t1,'%.1f') ' seconds']);

end


%% grain boundary voids calculation
% Postprocessing in MTEX specific to copper example
% TrueEBSD enables us to match grain boundary voids from the BSE image
% with grain boundaries in the EBSD map. 
% We can compare MDFs of boundaries in the whole map with the boundaries
% that the voids nucleated on.
% It turns out that the <111> 60 degree boundaries prefer not to grow
% voids.

try %in case this fails, still save the data!
    gbVoidsTest
    t1  = toc;
    disp(['Finished gb voids calculation for ' dataName ' in ' num2str(t1,'%.1f') ' seconds']);
catch ME 
    ME3 = ME;
    t1  = toc;
    warning(ME.message);
    disp(['Failed gb voids calculation for ' dataName ' in ' num2str(t1,'%.1f') ' seconds']);
end

%% Save stuff

if setSave
    close all
    srcFiles = cellfun(@which, ...
        {mname; 'trueEbsdPlots'; 'gbVoidsTest'; ['loadDemoData_' removeweirdchars(dataName)]}, ...
        'UniformOutput',0);
    srcFiles(cellfun(@numel,srcFiles)==0)=[]; %remove empty files
    saveVarsAndScript(savepname, [removeweirdchars(dataName) '_' timestamp], srcFiles);
end

t1  = toc;
disp(['Finished TrueEBSD workflow for ' dataName ' in ' num2str(t1,'%.1f') ' seconds']);

if setSave
    diary off
end
