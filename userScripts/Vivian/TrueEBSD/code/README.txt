This folder TrueEBSD contains MATLAB code related to the TrueEBSD MTEX program.

Files
 - main.m
	run TrueEBSD workflow
 - trueEbsdPlots.m
	example script to plot trueEBSD outputs - this is an example only, what you want to plot will change for each workflow / dataset
 - gbVoidsTest.m
	not part of TrueEBSD code - analysis script for TrueEBSD-corrected EBSD map - copper example
 - README.txt
	this file


Folders:
 - @distortedImg
	distortedImg.m - classdef 
 - @trueEbsd
	trueEbsd.m - classdef 
	undistort.m; pixelSizeMatch.m; calcShifts.m - class functions	
 - dataLoader
	Import function (wrapper function to run import script for the dataset)
		loadDemoData.m
	Import scripts for demo datasets
		loadDemoData_copperID29.m -- this example
		loadDemoData_Ti64.m
 - funcsV0
	MATLAB functions inherited from original TrueEBSD code (https://zenodo.org/records/4282885)	
 - tools
	Helper functions (MTEX and generic MATLAB) used in TrueEBSD code 
	MTEX-specific: 
		ebsdMapOffset.m; 
		ebsdSquare2ij.m; 
		ij2EbsdSquare.m; 
		ebsdMapOffset.m; 
		nwse2EbsdPos.m;
		
	MATLAB: 
		FindLargestRectangles.m (from MATLAB central), license.txt (license file for FindLargestRectangles.m);
		removeweirdchars.m;
		saveFigs.m;
		saveVarsAndScript.m;		
 