%% Example MTEX plotting script
% Vivian Tong NPL, for MTEX 2023 Workshop
% Example general MTEX script, adapted for WC-Co fatigue crack analysis
% supplied for information only, no guarantee that any of this is correct
% or can be transferred to a different system.

clear; close all; home;

addpath(genpath(cd));
addpath(genpath('D:\Vivian Tong\MATLAB_general\mtexToolsNpl'));

%% Check these variables every time!!!

roiNum=1;
    
    % if you want to save outputs, set setSave = 1;, otherwise setSave = 0;
    % turning this on also pulls the latest git projects before running
    % develop mode tries to commit and push any changes to git. Switch
    % setGit = 1 if you have set up git, set to 0 if you have not set up git
    % (e.g. you downloaded the source code from the gitlab page) or when
    % debugging
    setSave = 1;
    setGit = 0;
    
    setSemName = 'Auriga'; %'Supra' (EDAX Hikari) or 'Auriga' (OI Sym2)
    
    % % switch plotting functions on and off
    % 1 to turn on, 0 to skip
    setPlot.mapPatternQuality=1; % plotebsdmapscalar()
    setPlot.mapPhase=1; % plotebsdmapscalar()
    setPlot.mapOrientationIpf=1; % plotebsdmapipf
    setPlot.spherePoleFigs=0; % plotebsdpolefigs
    setPlot.grainsCalc=1; % prepebsdcleangrains()
    setPlot.grainsPlot=0; % plotgrains()
    setPlot.autocorr=0; % plotAutocorr()
    setPlot.gbShape = 0;
    %%%%%%%%%%%%
    % Run Import wizard
    % run the line below (highlight + F9, or highlight + right click > Evaluate Selection)
    % to create a import script.
    % you need the CS (crystal symmetry) and maybe the pname & fname variables.
    %{
import_wizard('EBSD');
    %}
    
    % the XYZ --> abc,a*b*c* alignments will be updated later in loadebsdnpl
    % according to the NPL EBSD system conventions,so it's ok if it is wrong here.
    CS = {...
        'notIndexed',...
        crystalSymmetry('6/mmm', [2.9 2.9 2.8], 'X||a*', 'Y||b', 'Z||c*', 'mineral', 'W C', 'color', [0.53 0.81 0.98]),...
        crystalSymmetry('m-3m', [3.6 3.6 3.6], 'mineral', 'Co (fcc)', 'color', [0.74 0.56 0.56]),...
        crystalSymmetry('6/mmm', [2.5 2.5 4.1], 'X||a*', 'Y||b', 'Z||c*', 'mineral', 'Co (hcp)', 'color', [0.85 0.65 0.13])};
    
    
    
    %%%%%%%%%%%%
    % Data files and folders
    %you can paste this from import_wizard generated script if you like
    % you can also define a relative file path using 'cd' (current directory)
    
    % path to files
    % roiNum=2;
    roiNumStr=num2str(roiNum);
    pname = ['D:\Vivian Tong\some file path\20230128\EBSD\' ];
    % which files to be imported
    fname = fullfile(pname, ['Map Data - EBSD Data.ctf']);
    
    %%%%%%%% Ok you can stop checking here %%%%%%%%
    
    %% Outputs and version control
    %replace pname with first parent folder
    [pname,~,~]=fileparts(fname);
    
    %time now
    timestamp = char(datestr(now,'yymmdd_HHMM'));
    scriptName = mfilename;
    
    if setSave
        %output folder
        saveFolder = fullfile(pname, ['\mtexOut' timestamp]); %make
    else
        saveFolder = '';
    end
    
    if setGit
        gitProjectName = 'vivian.tong/mtexToolsNpl';
        gitCommitMsg = input('Type a git commit message: ','s'); %prompt for a git commit message, e.g. 'my dataset'
    else
        gitProjectName='';
        gitCommitMsg='';
    end
    
    % set up standard EBSD map plot settings
    settingsplotebsdmap(setSave);
    
    %% Read EBSD data
    [ebsdRaw,CS] = loadebsdnpl(setSemName, fname, CS); %overwrite CS to follow
    % crystal/cartesian alignment conventions for NPL EBSD systems
    
    %% TrueEBSD spatial distortion correction
    trueEbsdFile=fullfile(pname,'TrueEBSD Outputs\TrueEBSD_Data.mat');
    % phase map from BSD image
    switch setSemName
        case 'Auriga'
            phasesBsd = imread(fullfile(pname,['BSDPhases_' roiNumStr '.tif']));
            imgBsd = imread(fullfile(pname,'BSE.tif'));
            switch getMTEXpref('xAxisDirection')
                case 'west'
                    phasesBsd = fliplr(phasesBsd);
                    imgBsd = fliplr(imgBsd);
                otherwise
                    error('which way does the BSD image point?');
            end
            switch getMTEXpref('zAxisDirection')
                case 'outofPlane'
                    % do nothing
                otherwise
                    error('which way does the BSD image point?');
            end
            
            tic; disp(char(datetime(now,'ConvertFrom','datenum')));
            [ebsd,rectKeepGrid] = trueEbsd2Mtex(ebsdRaw,trueEbsdFile,phasesBsd,imgBsd);
            disp([char(datetime(now,'ConvertFrom','datenum')) ': function trueEbsd2Mtex() run time:']);
            toc; %run time 240 seconds
            
            % make ebsd map coordinates match imageJ ROI
            %  translate ebsd.x, ebsd.y to match global crack coordinates (using
            %imageJ ROI positions --> match top left corners.
            roiFName = dir(fullfile(pname,'*.roi'));
            if numel(roiFName)==1
                sROI = ReadImageJROI(fullfile(roiFName.folder,roiFName.name));
                % sROI.vnRectBounds(1) = top row
                % sROI.vnRectBounds(2)= left column
                % sROI.vnRectBounds(3) = bottom row
                % sROI.vnRectBounds(4) = right column
                
                %this is correct only if X points West, Y points South, Z points out of
                %plane
                %TODO - take into account shift in top left corner position
                %which corresponds to top right in these EBSD map coordinates
                %after cropping EBSD map in trueEbsd2Mtex!
                [row(1),col(1)] = find(any(rectKeepGrid,2),1,'first'); %first row = top
                [row(2),col(2)] = find(any(rectKeepGrid,1),1,'first'); %first column = left
                [row(3),col(3)] = find(any(rectKeepGrid,2),1,'last'); %last row = bottom
                [row(4),col(4)] = find(any(rectKeepGrid,1),1,'last'); %last column = right
                
             
                 ebsd=ebsd +...
                    (round([-(sROI.vnRectBounds(4) - (size(rectKeepGrid,2)-col(4))) ...
                    (sROI.vnRectBounds(1) - (row(1)-1))])...
                    .*[ebsd.dx, ebsd.dy]);
            else
                warning('could not load imagej ROI file, ebsd map xy in local coordinates')
            end
            
        otherwise
            error('cannot do spatial distortion correction for EBSD map! Check coordinates');
    end
    
    %% (5) Grains
    setDebug=0;
    if setDebug
        warning('grainsBsdReconstruction() running in debug mode');
        ebsd=reduce(ebsd,5);
    end
    % setGrainOption options are:
    % 1 - dilate indexed points / erode notIndexed point by 1 pixel at boundary
    % 2 - calculate grains from entire map - treat unindexed points as separate phase
    % 3 - calculate grains from indexed points only - interpolate unindexed points to calculate grains
    % wild spike removal is computationally expensive, esp when used with
    % setGrainOption 1 - only turn on if you really need it)
    setGrainOption.calcMethod = 3; % can be 1 2 or 3 (2 is most computationally expensive)
    setGrainOption.wildSpikeRemoval=0; %1 to turn on, 0 to turn off
    setGrainOption.threshAng=10*degree;
    setGrainOption.qhull='';% use mtex default for voronoi decomposition
    
    % do special reconstruction per phase using BSD phase map
    %try for WC
    if setPlot.grainsCalc || setPlot.grainsPlot
        tic;disp(char(datetime(now,'ConvertFrom','datenum')));
        [~,grains_WC] = prepebsdcleangrains(ebsd('W C'),setGrainOption);
        figure; plot(grains_WC);
        disp([char(datetime(now,'ConvertFrom','datenum')) ': function prepebsdcleangrains() run time:']); toc;   %run time 2933 seconds

             
        % Merge inclusion grains
        [grains_WC,~] = merge(grains_WC,'inclusions');
        
        tic; disp(char(datetime(now,'ConvertFrom','datenum')));
        [ebsdCMean,ebsdC,grainsC] = grainsBsdReconstruction(ebsd,grains_WC,ebsd('W C').phaseId(1),setGrainOption);
        disp([char(datetime(now,'ConvertFrom','datenum')) ': function grainsBsdReconstruction() run time:']);
        toc;       % run time 13058 seconds
        ebsdCMean=gridify(ebsdCMean);
        ebsdC=gridify(ebsdC);
        
        [ebsdCMean,grainsC] = removeTinyCrackGrains(ebsdCMean,grainsC);
    end
    %now repeat for Co-fcc and Co-hcp phases (TODO)
    
    %total run time approx 4 hours to this point
    
    %% save output data
    if setSave
        savedatamatlab(saveFolder, 'mtexOut');
        saveversionstamp([], [], [], timestamp, fname, saveFolder,setPlot, setGrainOption);
    end
    
    %% (1) Pattern quality map
    % this is called image quality ('iq') in Edax but band contrast ('bc')in OxInst
    
    switch setSemName
        case 'Supra'
            pqName = 'iq';
        case 'Auriga'
            pqName = 'bc';
    end
    
    if setPlot.mapPatternQuality % plotebsdmapscalar()
        plotebsdmapscalar(ebsd,pqName,'Pattern Quality','gray',saveFolder,setSave);
    end
    
    %% (2) Phase map
    % mtex colours are defined already in CS, leave setColorMap empty ([])
    if setPlot.mapPhase
        plotebsdmapscalar(ebsd,'phase','Phase',[],saveFolder,setSave);
        plotebsdmapscalar(ebsd,'bsdPhase','BSD Phase',[],saveFolder,setSave);
        plotebsdmapscalar(ebsd,'bsdImg','BSD Image','gray',saveFolder,setSave);
        
        %replot after processing
        plotebsdmapscalar(ebsdCMean,'phase','Phase TrueEBSD',[],saveFolder,setSave);
        plotebsdmapscalar(ebsdCMean,'bsdPhase','BSD Phase TrueEBSD',[],saveFolder,setSave);
        plotebsdmapscalar(ebsdCMean,'bsdImg','BSD Image TrueEBSD','gray',saveFolder,setSave);
    end
    %% (3) IPF maps
    % use 'ipfTSLKey' colorkey for plotting to (approximately) match OIM and
    % Aztec outputs
    % use 'ipfColorKey' colorkey to use MTEX default colour mapping
    if setPlot.mapOrientationIpf
        plotebsdmapipf(ebsd,'ipfTSLKey',setSemName,fullfile(saveFolder,'ebsd'),setSave);
        %     replot after processing
        plotebsdmapipf(ebsdCMean,'ipfTSLKey',setSemName,fullfile(saveFolder,'ebsdCMean'),setSave);
        plotebsdmapipf(ebsdC,'ipfTSLKey',setSemName,fullfile(saveFolder,'ebsdC'),setSave);
    end
    
    %% plot grain maps and statistics
    % 1 to turn on, 0 to turn off
    setGrainPlotOption=struct;
    setGrainPlotOption.removeEdge=0; %remove map edge grains
    setGrainPlotOption.removeIslands=0; %remove grains inside other grains
    setGrainPlotOption.fitEllipse=1;
    setGrainPlotOption.feretDiams=1;
    setGrainPlotOption.minGrainSize=0; % min grain size in pixel units. 0 to turn off. If you turn this off feretDiams might error.
    
    if setPlot.grainsPlot
        [~,~,grains2Table] = plotgrains(ebsdCMean('Crack'),grainsC,setGrainPlotOption,saveFolder,setSave);
    end
    

    %% Crack boundary angles
    % smoothing iterations test
    gbSmoothIter=[0 10 30 60 100 150];%number of iterations to perform smoothing
    iter_select = 5;
    grains_Crack=cell(numel(gbSmoothIter),1);
    for i=1:numel(gbSmoothIter)
        grains_Crack{i}= smooth(grainsC('Crack'),gbSmoothIter(i));
    end
    
    
    % plots
    lineCols=colormap(lines(numel(gbSmoothIter)));
    figure; set(gcf,'Position',[1 41 1920 963]);
    for i=1:numel(gbSmoothIter)
        ax=subplot(2,3,i);
        gbSegLen = grains_Crack{i}.boundary.segLength;
        histogram(grains_Crack{i}.boundary.direction(logical(gbSegLen)),'antipodal', 'weights',gbSegLen(logical(gbSegLen)),180,'DisplayStyle','stairs');
        rlim([0 0.02]);
        title([num2str(gbSmoothIter(i)) ' iters']);
    end
    savefigmtex('crackSmoothItersHist',saveFolder,setSave);
    
    figure;
    plot(ebsdCMean,ebsdCMean.prop.bsdImg); hold on; colormap gray;
    for i=1:numel(gbSmoothIter)
        plot(grains_Crack{i}.boundary,'linecolor',lineCols(i,:),'DisplayName',[num2str(gbSmoothIter(i)) ' iters']);
    end
    legend;
    title('Smoothed crack shapes');
    savefigmtex('crackSmoothItersMap',saveFolder,setSave);
    % savefigmtex('crackSmoothItersMap_zoom',saveFolder,setSave);
    
    
    figure;
    plot(ebsdCMean,ind2rgb(ebsdCMean.prop.bsdImg,colormap(gray(256)))); hold on;
    plot(grains_Crack{iter_select}.boundary,angle(grains_Crack{iter_select}.boundary.direction,xvector)/degree); colormap(pmkmp(180,'IsoL'));
    caxis([0 90]); mtexColorbar;
    title('Local Crack Angle');
    savefigmtex('crackAngMap_100',saveFolder,setSave);
    
    figure; set(gcf,'Position',[650 685 201 151]);
    polarscatter((1:180)*pi/180,ones(1,180),10,colormap(pmkmp(180,'IsoL')),'filled');
    axis on; 
    set(gca,'RTick',[],'RGrid','off','ThetaGrid','on','ThetaLim',[0 180],'RLim',[0 1]); 
    savefigmtex('crackAngPolarColourScale',saveFolder,setSave);

    %% WC grains closest to crack boundary
    % input: list of crack boundary segments
    % output: per gb segment - grainId of nearest WC grain, distance to nearest WC grain
    
    settings.GbStep=1;
    settings.MaxIters=500;
    tic; disp(char(datetime(now,'ConvertFrom','datenum'))); %25 seconds, 150 iterations to find everyone. very similar computation time for 100 / 200 / 400 /2000 gb segments
    [crackNeighbours,~] = findWCGrainsNearCrack(ebsdCMean,grains_Crack{iter_select}.boundary,settings);
    toc;
    
    % figure;
    % plot(ebsdCMean); hold on;
    % quiver(gbCrackReduced,gbCrackReduced.direction,'color','r');
    
    % calculate misorientation between WC grains either side of the crack
    crackNeighboursBothSidesOk = ispos(crackNeighbours.WCGrainId(:,:,1)) & ispos(crackNeighbours.WCGrainId(:,:,2));
    %deal with the case where the WC grains match up differently on the two sides
    [~,locB1]= ismember(crackNeighbours.WCGrainId(crackNeighboursBothSidesOk,1,1),grainsC.id);
    [~,locB2]= ismember(crackNeighbours.WCGrainId(crackNeighboursBothSidesOk,1,2),grainsC.id);
    
    grains_WCneighbours2sides{1} = grainsC(locB1).meanOrientation;
    grains_WCneighbours2sides{2} = grainsC(locB2).meanOrientation;
    
    moriAng_2sides = angle(grains_WCneighbours2sides{1},grains_WCneighbours2sides{2});
    
    maxPixError=5;
    % classify crack edges into different types
    % let's define:
    % transgranular WC-WC interface = 2
    % WC-Co OR Co-WC interface = -1
    % Co-Co interface = 0
    % intergranular WC-WC interface = -2
    % negative = intergranular, positive = transgranular
    % 1 means something went wrong somewhere
    
    crackNeighboursClassify=crackNeighbours.WCDist;
    crackNeighboursClassify(crackNeighbours.WCDist<=ebsd.dx*maxPixError)=1; %WC edges
    crackNeighboursClassify(crackNeighbours.WCDist>ebsd.dx*maxPixError)=0; %Co edges
    crackNeighboursClassify=crackNeighboursClassify(:,1,1)+crackNeighboursClassify(:,1,2);
    % for the points where not both sides were ok - assume
    %intergranular because no WC was found on one side!
    intergranularPoints = zeros(size(crackNeighboursClassify)); %everything is zero (seed intergranular)
    intergranularPoints(crackNeighboursBothSidesOk)= (moriAng_2sides/degree<setGrainOption.threshAng); %transgranular = 1, intergranular =0
    intergranularPoints=sign(intergranularPoints-0.5); % transgranular = 1; intergranular = -1;
    crackNeighboursClassify = intergranularPoints .*crackNeighboursClassify;
    
    
    
    % % plots
    [~,edges,binId] = histcounts(moriAng_2sides/degree,[0:4:100]);
    dataWeights = grains_Crack{iter_select}.boundary.segLength;
    dataWeights=dataWeights(crackNeighboursBothSidesOk);
    [binCounts]= accumarray(binId(binId>0),...
        dataWeights(binId>0),[length(edges)-1 1],@nansum);
    figure;
    histogram('BinEdges',edges,'BinCounts',binCounts,'Normalization','count',...
        'DisplayStyle','stairs');
    xlabel('Misorientation btwn WC either side of the crack / {\circ}');
    ylabel('Crack length {\mu}m');
    title('Which phase does the crack pass through?');
    savefigmtex('crackNeighbourWC_MoriAngHist',saveFolder,setSave);
    
    %EBSD map
    grains_WCneighbours = grainsC(ismember(grainsC.id,crackNeighbours.WCGrainId(ispos(crackNeighbours.WCGrainId))));
    figure;
    plot(ebsdCMean); hold on;
    plot(grains_WCneighbours,grains_WCneighbours.meanOrientation);
    title('WC Grain Orientations near Crack (IPF-out)');
    savefigmtex('crackNeighbourWC_Ori',saveFolder,setSave);
    
    
    % crack distance
    %line profile
    figure; set(gcf,'Position',[493 552 924 321])
    plot(crackNeighbours.crackXY(:,1,1),crackNeighbours.WCDist(:,1,1),'.','MarkerSize',2); hold on;
    plot(crackNeighbours.crackXY(:,1,2),-crackNeighbours.WCDist(:,1,2),'.','MarkerSize',2);
    ylim([-3 3]);xlim([ebsdCMean.xmin ebsdCMean.xmax]);
    ylabel('Distance to WC boundary / {\mu}m'); xlabel('Crack X-position / {\mu}m');
    title('Distance between crack boundary and closest WC grain boundary');
    savefigmtex('crackNeighbourWC_Dist',saveFolder,setSave);
    
    %histogram
    %TODO - tidy this up into a weighted-histogram function
    [~,edges,binId] = histcounts(crackNeighbours.WCDist(:),[0:ebsd.dx:3]);
    dataWeights = repmat(grains_Crack{iter_select}.boundary.segLength,[size(crackNeighbours.WCDist,3) 1]);
    [binCounts]= accumarray(binId(binId>0),...
        dataWeights(binId>0),[length(edges)-1 1],@nansum);
    figure;
    histogram('BinEdges',edges,'BinCounts',binCounts,'Normalization','cumcount',...
        'DisplayStyle','stairs');
    xlabel({'Distance to WC boundary / {\mu}m'; '(bin width = 1 map pixel)'});
    ylabel('Cumulative crack length {\mu}m');
    title('Which phase does the crack pass through?');
    savefigmtex('crackNeighbourWC_DistHist',saveFolder,setSave);
    
    % classify crack path type
    % line profile
    figure; set(gcf,'Position',[493 552 924 321]);
    plot(crackNeighbours.crackXY(:,1,1),crackNeighboursClassify,'.','MarkerSize',4);
    ylim([-3 3]);xlim([ebsdCMean.xmin ebsdCMean.xmax]);
    ylabel('Crack interface type'); xlabel('Crack X-position / {\mu}m');
    title('Classify crack path interfaces');
    savefigmtex('crackNeighbourWC_Type',saveFolder,setSave);
    
    
    
    
    %weighted histogram classify
    [binProb,edges,binId] = histcounts(crackNeighboursClassify,-2.5:1:2.5,'Normalization','probability');
    dataWeights = repmat(grains_Crack{iter_select}.boundary.segLength,[size(crackNeighboursClassify,3) 1]);
    [binCounts]= accumarray(binId(binId>0),...
        dataWeights(binId>0),[length(edges)-1 1],@nansum);
    figure;
    h=histogram('BinEdges',edges,'BinCounts',binCounts,'Normalization','count',...
        'EdgeColor',[1 1 1],'LineWidth',3); %set bars to appear to not touch because this is really categoraical data
    xlabel('Crack interface type');
    ylabel('Crack length {\mu}m');
    title('Classify crack path interfaces');
    text(h.BinEdges(1:end-1)+0.5,h.Values,arrayfun(@num2str,round(binProb,2),'UniformOutput',false),...
        'HorizontalAlignment','center','VerticalAlignment','bottom','FontSize',14);
    savefigmtex('crackNeighbourWC_TypeHist',saveFolder,setSave);
    

%% (6) grain boundary curvature
% Don't use this function plotgrainsboundary() yet - work ongoing
if setPlot.gbShape
    setGbPlotOptions=struct;
    setGbPlotOptions.minGrainSize=0; %pixel units - not ideal, fix later
    setGbPlotOptions.gbSmooth=gbSmoothIter(iter_select);
    plotgrainsboundary(ebsdCMean(ismember(ebsdCMean.grainId,crackNeighbours.WCGrainId)),...
        grainsC(ismember(grainsC.id,nonzeros(crackNeighbours.WCGrainId))),...
        grains_Crack{iter_select},setGbPlotOptions,saveFolder,setSave);
end
%todo - remove internal grain boundaries


%% (7) Co binder mean free path, WC grain size metrics

% for roiNum = 2:16
% tic
% %load stuff
% roiNumStr=num2str(roiNum);
% % tic
% % %load stuff
% % roiNumStr=num2str(roiNum,'%02u');
% % pname = ['D:\Vivian Tong\\ROI_' roiNumStr ];
% 
% 
% path1=dir(fullfile(pname,'mtexOut*'));
% load(fullfile(pname,path1(end).name,'mtexOut.mat'),'gsmap_stack');
%     
% disp(['Current dataset: ' pname]);

[gsmap_stack] = intercept_length_v3a_MTEX(ebsdCMean('Co (fcc)'),grainsC('Co (fcc)'),saveFolder,setSave);
save(fullfile(saveFolder,'mtexOut'),'gsmap_stack','-append');

figure; histogram(grainsC('W C'),grainsC('W C').diameter,'outerPlotSpacing',30)
xlabel('Grain diameter / {\mu}m');
title('Caliper Diameter - WC grains');
savefigmtex('grainDiam_WC_hist',saveFolder,setSave);


binderPath_horz=mean(gsmap_stack(:,:,1),'all','omitnan');
binderPath_vert=mean(gsmap_stack(:,:,2),'all','omitnan');
binderPath_dia1=mean(gsmap_stack(:,:,3),'all','omitnan');
binderPath_dia2=mean(gsmap_stack(:,:,4),'all','omitnan');
binderPath_horzGeomean=geomean(gsmap_stack(:,:,1),'all','omitnan');
binderPath_vertGeomean=geomean(gsmap_stack(:,:,2),'all','omitnan');
binderPath_dia1Geomean=geomean(gsmap_stack(:,:,3),'all','omitnan');
binderPath_dia2Geomean=geomean(gsmap_stack(:,:,4),'all','omitnan');

weightFacs= (grainsC('W C').area./sum(grainsC('W C').area));
wcDiam_weightArea = sum(grainsC('W C').diameter.*weightFacs);
wcDiam_weightAreaGeomean = exp(sum(log(grainsC('W C').diameter).*weightFacs));
wcDiam_weightNum = mean(grainsC('W C').diameter);
wcDiam_weightNumGeomean = geomean(grainsC('W C').diameter);
wcCeqDiam_weightArea = sum(grainsC('W C').equivalentRadius*2.*weightFacs);
wcCeqDiam_weightAreaGeomean = exp(sum(log(grainsC('W C').equivalentRadius*2).*weightFacs));
wcCeqDiam_weightNum = mean(grainsC('W C').equivalentRadius*2);
wcCeqDiam_weightNumGeomean = geomean(grainsC('W C').equivalentRadius*2);


% (8) WC phase contiguity
% use proxy metric - ratio of WC-WC to WC-Co interfaces
boundaryLenWCWC = sum(grainsC.boundary('W C','WC').segLength);
boundaryLenWCCo = sum(grainsC.boundary('W C','Co').segLength);
boundaryLenWCFraction = boundaryLenWCWC/(boundaryLenWCCo+boundaryLenWCWC);
boundaryLenWCContiguity = (2*boundaryLenWCWC)/(boundaryLenWCCo+2*boundaryLenWCWC);

disp(['WC caliper diameter (area weight): '   num2str(wcDiam_weightArea)]);
disp(['WC caliper diameter (area weight, geomean): ' num2str(wcDiam_weightAreaGeomean)]);
disp(['WC caliper diameter (number weight): ' num2str(wcDiam_weightNum)]);
disp(['WC caliper diameter (number weight, geomean): ' num2str(wcDiam_weightNumGeomean)]);

disp(['WC circ eq diameter (area weight): '   num2str(wcCeqDiam_weightArea)]);
disp(['WC circ eq diameter (area weight, geomean): ' num2str(wcCeqDiam_weightAreaGeomean)]);
disp(['WC circ eq diameter (number weight): ' num2str(wcCeqDiam_weightNum)]);
disp(['WC circ eq diameter (number weight, geomean): ' num2str(wcCeqDiam_weightNumGeomean)]);

disp(['WC-WC interface fraction: ' num2str(boundaryLenWCFraction)]);
disp(['WC phase contiguity: ' num2str(boundaryLenWCContiguity)]);

disp(['Binder mean free path (horz): '   num2str(binderPath_horz)]);
disp(['Binder mean free path (horz, geomean): ' num2str(binderPath_horzGeomean)]);
disp(['Binder mean free path (vert): '   num2str(binderPath_vert)]);
disp(['Binder mean free path (vert, geomean): ' num2str(binderPath_vertGeomean)]);
disp(['Binder mean free path (dia1): '   num2str(binderPath_dia1)]);
disp(['Binder mean free path (dia1, geomean): ' num2str(binderPath_dia1Geomean)]);
disp(['Binder mean free path (dia2): '   num2str(binderPath_dia2)]);
disp(['Binder mean free path (dia2, geomean): ' num2str(binderPath_dia2Geomean)]);

toc
% end

%% Save matlab outputs and version stamp
%if the code ran ok then push the current commit to remote
if setGit
    %handle git version control - either update from the remote, or commit current
    % changes ready to push to the remote
    %tag this dataset with EBSD file name, but first remove illegal characters
    [~,gitNameTag,~] = fileparts(fname); gitNameTag(regexp(gitNameTag,'\W?','start')) = ''; gitNameTag = [gitNameTag '_' timestamp];
    [gitCommitStatus, gitCommitOut, gitCurrentHash] = datagitcommit(gitCommitMsg, gitNameTag);
    
    if gitCommitStatus==0
        [gitPushStatus,gitPushOut] = system('git push --tags');
        if gitPushStatus~=0
            warning('Git push failed! If you are getting an SSL certificate error, check if your SSH authentication is set up correctly. NPL intranet and MathWorks pages have relevant resources.');
            disp(gitPushOut);
        end
    else
        warning('Git commit failed, cannot push to remote!');
    end
else
    % git pull is not used at the moment
    %     [gitPullStatus, gitPullOut, gitCurrentHash] = datagitpull(gitProjectName);
    gitCommitOut = '';
    gitCurrentHash = '';
    gitCommitStatus = '';
    gitNameTag = '';
end

if setSave
    savedatamatlab(saveFolder, 'mtexOut');
    saveversionstamp([], [], [], timestamp, fname, saveFolder,setPlot, setGrainOption);
    
    %     saveversionstamp(gitProjectName, gitCurrentHash, gitNameTag, timestamp, fname, saveFolder,setPlot,setPoleFigOption, setGrainOption,setGrainPlotOption,setAutocorrOption);
end



disp('Run successful! Script ends here.');
