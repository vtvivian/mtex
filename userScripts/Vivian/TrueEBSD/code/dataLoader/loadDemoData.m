function [disImgs] = loadDemoData(nameIn,varargin)
% load TrueEBSD datasets 
% This function runs the script loadDemoData_<dataName>.m, which is a
% script the operator needs to write themselves to set up the input data.
% This can include importing images and EBSD maps using MATLAB and MTEX
% functions. 
% loadDemoData_<dataName>.m is a script created by the user and saved in
% the current folder.
% Create one script for each dataset and make sure the file name matches
% the variable dataName in main.m.
%
% loadDemoData_<dataName>.m should import image data + metadata (can be from text, 
% HDF5 or image files) and construct a disImgs{n} = @distortedImg object from each one. 
% The images need to contain the same physical features but may have different contrast modes.
%
% Inputs
% nameIn – input dataset name as @char array 
%
% Outputs
% disImgs – @distortedImg cell array of imported image data 



if numel(varargin)>0 && strcmpi(varargin{1},'wizard')
    % run import wizard instead of loading existing data
    [~,disImgs] = dataLoaderWizard_contiguity;
else

    nameIn = argin_check(nameIn,{'char'});
    name1 = removeweirdchars(nameIn);
    ld = str2func(['loadDemoData_' name1]);
    ld()
end
