%% Cu grain boundary voids phase reassignment

%% load EBSD data from trueEBSD job
ebsdOld = job.undistortedList{1}.ebsd;
ebsdOld.pos = job.undistortedList{1}.pos; % assign new grid with likely a different step size
ebsdOld.plottingConvention = job.undistortedList{1}.mapPlottingConvention;
bse = job.undistortedList{end}.img; 

ext = ebsdOld.extent;
gridExt = [ext(1), ext(1) + (job.undistortedList{1}.dx *(size(bse,2)-1)),...
           ext(3), ext(3) + (job.undistortedList{1}.dx *(size(bse,1)-1)),...
           ext(5),ext(5)];

%% rotate everything into axis ij 
% because that makes life easier for plotting
% and we don't care about absolute orientations, just where the voids are
rot2ij = rotation.map(vector3d.X,ebsdOld.plottingConvention.east,...
    -vector3d.Z, ebsdOld.plottingConvention.outOfScreen);
plottingConventionIj = plottingConvention(-vector3d.Z,vector3d.X);

ebsdOld = rotate(ebsdOld,rot2ij);
ebsdOld = gridify(ebsdOld,'extent',gridExt);
% update EBSD plotting convention
ebsdOld.plottingConvention = plottingConventionIj;
%% Verify that EBSD coordinates are in 'ij' convention
% only need to run this if debugging
%{
% Image
figure; 
imagesc([1 size(bse,2)]*job.undistortedList{2}.dx,...
    [1 size(bse,1)]*job.undistortedList{2}.dy, ...
    job.undistortedList{2}.img(:,:,1:3)); axis ij image; colormap gray;
xlabel('x'); ylabel('y');

% EBSD map
setMTEXpref('showCoordinates','on');
setMTEXpref('figSize','normal'); 
figure; 
plot(ebsdOld,ebsdOld.bc,ebsdOld.plottingConvention); 
mtexColorMap gray;

%}
%% Reassign phases according to BSE image

phasesBse= bse==0; %voids = 1, copper = 0. don't just do ~bse because there may be nans

ebsdNew = gridify(ebsdOld);


voidPhase = crystalSymmetry('1','mineral','voids','color',str2rgb('DarkBlue'));

ebsdNew(phasesBse).rotations = rotation('euler',0,0,0);
ebsdNew(phasesBse).CS = voidPhase;

ebsdNew = gridify(ebsdNew);

% crop to largest rectangle
[~,~,~,keepGrid] = FindLargestRectangles(imfill(ebsdOld.isIndexed,'holes'));
ebsdNew = gridify(ebsdNew(keepGrid)); ebsdNew.plottingConvention = plottingConventionIj;
ebsdOld = gridify(ebsdOld(keepGrid)); ebsdOld.plottingConvention = plottingConventionIj;

ebsdNew
ebsdOld

figure;
plot(ebsdNew,ebsdNew.bc,ebsdOld.plottingConvention); mtexColorMap gray;
hold on; 
plot(ebsdNew('voids'),repmat(1.5*max(ebsdNew.bc(:)),size(ebsdNew('voids'))),ebsdNew.plottingConvention); %force white
if setSave
      saveFigs(gcf,['ebsdNew_bc'],savepname);
end

figure;
plot(ebsdNew,ebsdNew.plottingConvention)
if setSave 
      saveFigs(gcf,['ebsdNew_phases'],savepname);
end

%% Calculate grains and boundaries

% ignore voids in grain reconstruction - only copper phase
[grains,ebsdNew('Copper').grainId] = calcGrains(ebsdNew('Copper'),'angle',10*degree);
%redraw boundaries because we can, and we might want the g.b. trace angle
%later to find the coherent sigma3 boundaries
grains = boundaryContours(grains);
gBs = grains.boundary('Copper','Copper');

newMtexFigure('figSize','large');
plot(ebsdNew('Copper'),ebsdNew('Copper').orientations,'FaceAlpha',0.5,ebsdNew.plottingConvention); hold on;
plot(gBs,ebsdNew.plottingConvention,'linecolor',str2rgb('gray'));
plot(ebsdNew('voids'),zeros(size(ebsdNew('voids'))),ebsdNew.plottingConvention); colormap gray;
if setSave 
      saveFigs(gcf,['ebsdNew_ipfOut'],savepname);
end

%% Find nearest g.b. per copper void

% gbPosMap is an ebsd map, 
% nonzero pixels are ebsd map positions next to a grain boundary
% nonzero values are indices to gBs
gbPosMap = zeros(size(ebsdNew));
[ebsdIdList,ia,ic]=unique(gBs.ebsdId,'stable');
%ia are linear indices to unique values of gBs.ebsdId
%gBIdList are row indices to gBs
gBIdList = repmat([1:length(gBs)]',[1,2]);

gbPosMap(id2ind(ebsdNew,ebsdIdList))=gBIdList(ia);


%% find the grain boundary nearest to each void pixel
% 1. distance from grain boundary
[gbDist, gbNearest]=bwdist(gbPosMap); % gbNearest are linear indices to gbPosMap
% 2. locations of voids
voidsMap = zeros(size(ebsdNew));
voidsMap(ebsdNew.phase==ebsdNew('voids').phase(1))=1;
% 3. find closest g.b. to this void
% we only find intersections between voids and gbs, because the voids
% cover up the copper-copper boundaries
voidsList=gbPosMap(gbNearest(logical(voidsMap))); %indices to gBs
voidsDist=gbDist(logical(voidsMap)); %distance from void to nearest gB in pixels

%% separate out voids on the boundary vs close to the boundary (could be
% not on the boundary, could be a image matching error)

% guess a good threshold based on the TrueEBSD tilt fit residuals (95th
% percentile - arbitrary sensible guess?)
voidsList_threshPix = prctile(sqrt(job.shifts{2}{1}.fitError.ROI.Shift_X_1.^2 + job.shifts{2}{1}.fitError.ROI.Shift_Y_1.^2),95); 
%split voidsList into _on and _near its closest gB
voidsList_on = voidsList(voidsDist<=sqrt(2)); %pixel next to copper void
voidsList_near = voidsList(voidsDist>sqrt(2) & voidsDist<=voidsList_threshPix);
voidsList_notNear = voidsList(voidsDist>voidsList_threshPix); 
% because the voids are blobs, 'notnear' can include pixels further from
% the boundary in a void that actually crosses the g.b.

%sort voidsList to prefer gb points on a void
voidsList= [voidsList_on;voidsList_near;voidsList_notNear];

% find nearest gB misorientation
[voidLocs_gIdPairs,ia2,ic2] = unique(gBs(voidsList).grainId,'rows','stable');

% find g.b. misorientation
mdf_voids = calcDensity(gBs(voidsList).misorientation);
mdf_all = calcDensity(gBs.misorientation);


%% plot EBSD map with g.b. annotations
figure; newMtexFigure('figSize','large');
plot(ebsdNew('Copper'),ebsdNew('Copper').orientations,'FaceAlpha',0.3,ebsdNew.plottingConvention); hold on;
plot(gBs,ebsdNew.plottingConvention,'linecolor',str2rgb('gray'));
plot(ebsdNew('voids'),zeros(size(ebsdNew('voids'))),ebsdNew.plottingConvention); colormap gray; clim([0 1]);
plot(gBs(voidsList_on),ebsdNew.plottingConvention,'linecolor',str2rgb('DarkRed'),'linewidth',3);
plot(gBs(voidsList_near),ebsdNew.plottingConvention,'linecolor',str2rgb('Red'),'linewidth',3);
plot(gBs(voidsList_notNear),ebsdNew.plottingConvention,'linecolor',str2rgb('magenta'),'linewidth',2);
if setSave 
      saveFigs(gcf,['gBVoidLocs_map'],savepname);
end


% plot misorientation distributions 
% compare all map boundaries, boundary segments near a void, random distribution for copper crystal

% angle distributions 
figure; 
newMtexFigure('figSize','tiny','outerplotspacing',30);
plotAngleDistribution(mdf_all,'DisplayName','All GBs');hold on
plotAngleDistribution(mdf_voids,'DisplayName','Void GBs');
plotAngleDistribution(ebsdNew('Copper').CS,ebsdNew('Copper').CS,'antipodal','DisplayName','Uniform MDF');
legend('show','Location','northwest'); 
xlabel('Misorientation angle / degrees');
ylabel('Frequency / mrd');
if setSave 
      saveFigs(gcf,['gBVoidLocs_mdfAx'],savepname);
end

% axis distribution
figure; newMtexFigure('layout',[2,2],'figSize','large','outerplotspacing',30,'innerplotspacing',50);
nextAxis(1,2); plotAxisDistribution(mdf_all,'colorRange','equal'); mtexTitle('All GBs');
nextAxis(2,2); plotAxisDistribution(mdf_voids,'colorRange','equal'); mtexTitle('Void GBs');
nextAxis(2,1); plotAxisDistribution(ebsdNew('Copper').CS,ebsdNew('Copper').CS,'antipodal','colorRange','equal'); mtexTitle('Uniform MDF');
mtexColorbar;
if setSave 
      saveFigs(gcf,['gBVoidLocs_mdfAng'],savepname);
end


