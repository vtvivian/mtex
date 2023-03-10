function [ebsdOut,keepGrid2] = trueEbsd2Mtex(ebsd,trueEbsdFile,phasesBsd,imgBsd)
% function to take TrueEBSD output and use it to undistort the EBSD XY grid
% Vivian Tong NPL, for MTEX 2023 Workshop
% supplied for information only, no guarantee that any of this is correct
% or can be transferred to a different system.


load(trueEbsdFile,'gridshift_x','gridshift_y','setExp','Images');

NumCols=Images.NumCols;
NumRows=Images.NumRows;

%% crop and resize EBSD data
% find out which dimension to resize (which dimension is not cropped)
% use gridify2 function modified for square grids from djm87 (Daniel
% Savage) https://github.com/mtex-toolbox/mtex/issues/471
% BUT gridify2 is much more expensive than gridify - use only when actually
% needed
ebsd1=gridify(ebsd); %preallocate before resizing
%%%%%%


% find out what size to crop to
[xmin, xmax, ymin, ymax] = ebsd.extend;
xVec = [(xmin-(ebsd1.dx-setExp.PixSizeImg)/2):...
    setExp.PixSizeImg:...
    (xmin-(ebsd1.dx-setExp.PixSizeImg)/2) + (setExp.PixSizeImg*NumCols)];
yVec = [(ymin-(ebsd1.dy-setExp.PixSizeImg)/2):...
    setExp.PixSizeImg:...
    (ymin-(ebsd1.dy-setExp.PixSizeImg)/2) + (setExp.PixSizeImg*NumRows)];
%handle potential +-1 pixel errors
if numel(yVec)~= NumRows
    if numel(yVec)- NumRows == 1
        yVec(end)=[]; 
    elseif numel(yVec)- NumRows == -1
        yVec(end+1)=yVec(end)+setExp.PixSizeImg; 
    else
        error('big difference between expected and calculated resized EBSD map ygrid');
    end
end
if numel(xVec)~= NumCols
    if numel(xVec)- NumCols == 1
        xVec(end)=[]; 
    elseif numel(xVec)- NumCols == -1
        xVec(end+1)=xVec(end)+setExp.PixSizeImg; 
    else
        error('big difference between expected and calculated resized EBSD map xgrid');
    end
end
[xGrid, yGrid] = meshgrid(xVec,yVec);

%resize EBSD map
ebsd2 = gridify(interp(ebsd1, xGrid(:), yGrid(:))); 


% crop EBSD map to size
%end-NumCols+1:end is to account for the fliplr
ebsd2 = ebsd2(1:NumRows,end-NumCols+1:end);
phasesBsd = phasesBsd(1:NumRows,end-NumCols+1:end);
imgBsd = imgBsd(1:NumRows,end-NumCols+1:end);

%% undistort EBSD data
% only works for  setSemName = 'Auriga'!
%grids and shifts in pixel units

%we need to map TEST to REF therefore shift directions go backwards
%also need to sort out
[xGridPix, yGridPix] = meshgrid(1:NumCols,1:NumRows);
shiftXY = fliplr(cat(3,-(xGridPix-gridshift_x),(yGridPix-gridshift_y)));

%create undistorted xy positions and set all pixels outside the frame to
xGridWarp = imwarp(xGridPix, shiftXY); xGridWarp(~xGridWarp)=nan; 
yGridWarp = imwarp(yGridPix, shiftXY); yGridWarp(~yGridWarp)=nan; 

ebsd3 = EBSD(ebsd2); %un-gridify
ebsd3.x = (xGridWarp(:)*ebsd2.dx) + ebsd2.x(1,1); ebsd3.y = (yGridWarp(:)*ebsd2.dy) + ebsd2.y(1,1);
updateUnitCell(ebsd3);

ebsd3(isnan(ebsd3.x))=[]; %remove EBSD points outside the undistorted frame
[xmin2, xmax2, ymin2, ymax2] = ebsd2.extend;
ebsd3(ebsd3.x>xmax2)=[]; 
ebsd3(ebsd3.y>ymax2)=[]; 
ebsd3(ebsd3.x<xmin2)=[]; 
ebsd3(ebsd3.y<ymin2)=[]; 

%% regrid undistorted data
%need gridify2 - interp doesn't work here 
ebsd4 =gridify2(ebsd3,'unitCell',ebsd2.unitCell,'extend',ebsd2.extend);

[xmin4, xmax4, ymin4, ymax4] = ebsd4.extend;
%figure out crop dimensions
crop2 = inpolygon(ebsd2,[xmin4-ebsd4.dx/2 ymin4-ebsd4.dy/2 ...
    (xmax4-xmin4)+(ebsd4.dx) (ymax4-ymin4)+(ebsd4.dy)]);

ebsd4.prop.bsdPhase=reshape(phasesBsd(crop2),size(ebsd4));
ebsd4.prop.bsdImg=reshape(imgBsd(crop2),size(ebsd4));

%% crop EBSD map edges where they don't overlap
%crop to largest rectangle inside map - now all notIndexed points belong to
%the crack
%use bwconvhull to exclude crack points in FindLargestRectangles
% FindLargestRectangles is in the matlab file exchange
[~,~,~,keepGrid] = FindLargestRectangles(bwconvhull(ebsd4.isIndexed,'union'));
ebsdOut = gridify(ebsd4(keepGrid)); 
keepGrid2 = crop2; keepGrid2(crop2)=keepGrid;


